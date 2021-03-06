#!/usr/bin/perl -w
package reinsert_greedy;
run() unless caller();

#
# Reinsertion of markup from source InlineText into plain text translated
# with Moses, output and input are expected to be UTF-8 encoded
# (without leading byte-order mark)
#
# Copyright 2011-2012 Digital Silk Road and Moravia (www.moravia.com)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

use strict;
use Getopt::Std;

sub run {
    binmode( STDIN,  ":utf8" );
    binmode( STDOUT, ":utf8" );

    if ( @ARGV != 1 ) {
        die "Usage: perl $0 source_tokenized_InlineText_file < traced_target > target_InlineText_file\n";
    }

    open( my $ifh, "<:utf8", $ARGV[0] );

    # Read line from InlineText file
    while (<$ifh>) {
		#acquire elements(tags)
        my @elements = extract_inline($_);

        if ( my $traced_target = <STDIN> ) {
			#reinsert elements into translated text
            print reinsert_elements( $traced_target, @elements );
            print "\n";
        }
        else {
            die "Target file has fewer lines than source file";
        }
    }

    close($ifh);
}

sub extract_inline {
    my $inline = shift;
    my @elements;
    my $i = 0;

	#work with the following tags only
    my $inline_tags = "(m|g|x|bx|ex|lb|mrk)";

    while ( $inline =~ /\G(.*?)<(\/?)$inline_tags(\s|\/?.*?)?>/g ) {
        my @tokens_before = split ' ', $1;
        my $num_tokens = scalar(@tokens_before);
        $i += $num_tokens;
        my $tag_text = defined $4 ? $3 . $4 : $3;

        # opening or isolated tags
        if ( $2 ne '/' ) {

            #if it is isolated tag
            if ( (substr( $tag_text, length($tag_text) - 1 ) eq "/")&&($i>0)) {
                push @elements, { 'el' => $3, 's' => $i - 1, 'txt' => "<$tag_text>" };
            }

            #if it is pair tag
            else {
                push @elements, { 'el' => $3, 's' => $i, 'txt' => "<$tag_text>" };
            }
        }

        # closing tags
        else {

            # find the last corresponding opening tag in the list
            for ( my $j = $#elements ; $j >= 0 ; $j-- ) {
                if ( $elements[$j]->{'el'} eq $3 && exists( $elements[$j]->{'s'} ) && !exists( $elements[$j]->{'ct'} ) ) {

                    #closing element is not allowed to have lower ID than its opening pair
                    if ( $elements[$j]->{s} > $i - 1 ) {
                        push @elements, { 'el' => $3, 'e' => $elements[$j]->{s}, 'txt' => "</$tag_text>", 'ot' => $j, 'gap' => $i - $elements[$j]->{'s'} };
                    }
                    else {
                        push @elements, { 'el' => $3, 'e' => $i - 1, 'txt' => "</$tag_text>", 'ot' => $j, 'gap' => $i - $elements[$j]->{'s'} };
                    }
                    $elements[$j]->{'ct'} = $#elements;
                    last;
                }
            }
        }
    }
    return @elements;
}

sub reinsert_elements {
    my $traced_target = shift;
    my @elements      = @_;
    my @phrase        = ();
    my $i;


    #create array of phrases with start and en info (taken from moses -v)
    while ( $traced_target =~ /\G(.*?)\s*\|(\d+)-(\d+)\|\s*/g ) {
        my $content = $1;
        push( @phrase, [ $content, $2, $3 ] );
    }    #while

    #re-insert starting tag
    for my $u ( 0 .. $#phrase ) {
        for ( $i = $#elements ; $i >= 0 ; $i-- ) {

            #if it is a staring element of a paired tag and was not assign yet
            if ( ( exists $elements[$i]->{ct} ) && ( !exists $elements[$i]->{used} ) ) {

                #if element is in range, put the element BEFORE phrase
                if ( in_range( $phrase[$u][1], $phrase[$u][2], $elements[$i]->{s}, $elements[ $elements[$i]->{ct} ]->{e} ) ) {
                    $phrase[$u][0] = $elements[$i]->{txt} . " $phrase[$u][0]";

                    #mark tag as used
                    $elements[$i]->{used} = 1;
                }

            }
        }
    }

    #re-insert ending tag or standalone (isolated) tag
    for ( my $u = $#phrase ; $u >= 0 ; $u-- ) {
        foreach $i ( 0 .. $#elements ) {

            #if it is a end element of a paired tag and was not assign yet
            if ( ( exists $elements[$i]->{e} ) && ( !exists $elements[$i]->{used} ) ) {

                #if element is in range, put the element AFTER phrase
                if ( in_range( $phrase[$u][1], $phrase[$u][2], $elements[$i]->{e}, $elements[ $elements[$i]->{ot} ]->{s} ) ) {
                    $phrase[$u][0] .= " $elements[$i]->{txt}";

                    #mark tag as used
                    $elements[$i]->{used} = 1;
                }

            }

            #if it is standalone tag
            if ( ( !exists $elements[$i]->{ct} ) && ( !exists $elements[$i]->{ot} ) && ( !exists $elements[$i]->{used} ) ) {

                #if element is in range, put the element AFTER phrase
                if ( in_range( $phrase[$u][1], $phrase[$u][2], $elements[$i]->{s}, $elements[$i]->{s} ) ) {

                    $phrase[$u][0] .= " $elements[$i]->{txt}";

                    #mark tag as used
                    $elements[$i]->{used} = 1;
                }
            }

        }
    }

    #take all not used elements and put them at the end
    foreach $i ( 0 .. $#elements ) {
        if ( !$elements[$i]->{used} ) {
			#initialize phrase[0] if it is not (no moses output(translatio), only a tag)
			push(@phrase,["",0,0]) if($#phrase==-1);
            $phrase[$#phrase][0] .= $elements[$i]->{txt};

            #mark tag as used
            $elements[$i]->{used} = 1;
        }
    }

    my $res = "";
    for my $u ( 0 .. $#phrase ) {
        $res .= $phrase[$u][0] . " ";
    }

	#debugging
#    print "\n$res\n\nelements:\n";
#    foreach $i ( 0 .. $#elements ) {
#        print "elem[$i]=[";
#        while ( my ( $key, $value ) = each $elements[$i] ) {
#            print "$key=$value, ";
#        }
#        print "]\n";
#    }
#

	#remove strating and trailing char if empty
	$res =~ s/\s+/ /g;
	$res =~ s/^\s+//g;
	$res =~ s/s+$//g;

    return $res;
}

sub in_range {
    my $ph_begin = shift;
    my $ph_end   = shift;
    my $el_begin = shift;
    my $el_end   = shift;
    my ( $ph_start, $ph_stop, $el_start, $el_stop );

    #ph_start and el_start have to have higher value than ph_stop, el-stop respectively
    if ( $ph_begin <= $ph_end ) {
        $ph_start = $ph_begin;
        $ph_stop  = $ph_end;
    }
    else {
        $ph_start = $ph_end;
        $ph_stop  = $ph_begin;
    }
    if ( $el_begin <= $el_end ) {
        $el_start = $el_begin;
        $el_stop  = $el_end;
    }
    else {
        $el_start = $el_end;
        $el_stop  = $el_begin;
    }

    my @elem_range = ();
    for ( my $i = $el_start ; $i <= $el_stop ; $i++ ) {
        push( @elem_range, $i );
    }

    #if some range has the element and the phrase same, return 1; otherwise 0
    for ( my $i = $ph_start ; $i <= $ph_stop ; $i++ ) {
        return 1 if ( $i ~~ @elem_range );
    }

    return 0;
}

1;

