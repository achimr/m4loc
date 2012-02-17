#!/usr/bin/perl -w
package reinsert;
run() unless caller();

#
# Reinsertion of markup from source InlineText into plain text translated
# with Moses, output and input are expected to be UTF-8 encoded 
# (without leading byte-order mark)
#
# Copyright 2011-2012 Digital Silk Road
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
    binmode(STDIN,":utf8");
    binmode(STDOUT,":utf8");

    if(@ARGV != 1) {
	die "Usage: perl $0 source_tokenized_InlineText_file < traced_target > target_InlineText_file\n";
    }

    open(my $ifh,"<:utf8",$ARGV[0]);

    # Read line from InlineText file
    while(<$ifh>) {
	my @elements = extract_inline($_);
	if(my $traced_target = <STDIN>) {
	    print reinsert_elements($traced_target,@elements);
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

    my $inline_tags = "(g|x|bx|ex|lb|mrk)";
    while($inline =~ /\G(.*?)<(\/?)$inline_tags(\s.*?)?>/g) {
	my @tokens_before = split ' ',$1;
	my $num_tokens = scalar(@tokens_before);
	$i += $num_tokens;
	my $tag_text = defined $4 ? $3.$4 : $3;
	# opening or isolated tags
	if($2 ne '/') {
	    push @elements, {'el'=>$3,'s'=>$i,'txt'=>"<$tag_text>"};
	}
	# closing tags
	else {
	    # find the last corresponding opening tag in the list
	    for (my $j = $#elements; $j >= 0; $j--) {
		if($elements[$j]->{'el'} eq $3 && exists($elements[$j]->{'s'}) && !exists($elements[$j]->{'ct'})) {
		    push @elements, {'el'=>$3,'e'=>$i-1,'txt'=>"</$tag_text>",'ot'=>$j,'gap'=>$i-$elements[$j]->{'s'}};
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
    my @elements = @_;
    my %added;

    my $target = "";
    my $i;
    my @cur_open;
    my %pending_close;
    while($traced_target =~ /\G(.*?)\s*\|(\d+)-(\d+)\|\s*/g) {
	my %trace_elem = ();
	# Determine which inline elements are opened or closed in the current trace
	foreach $i (0..$#elements) {
	    if(exists $elements[$i]->{e}) {
		if($elements[$i]->{e} >= $2 && $elements[$i]->{e} <= $3) {
		    $trace_elem{$i} = $i;
		}
	    }
	    else {
		if($elements[$i]->{s} >= $2 && $elements[$i]->{s} <= $3) {
		    $trace_elem{$i} = $i;
		}
	    }
	}

	# Write opening tags before text
	foreach $i (sort keys %trace_elem) {
	    # Opening tag
	    if(exists $elements[$i]->{ct}) {
		$target .= $elements[$i]->{txt}." ";
		push @cur_open, $i;
		# Was the currently opened element waiting to be closed?
		# If yes, add it to the tags to close for the current trace
		if(exists $pending_close{$elements[$i]->{ct}}) {
		    $trace_elem{$elements[$i]->{ct}} = $elements[$i]->{ct};
		    delete $pending_close{$elements[$i]->{ct}};
		}
		delete $trace_elem{$i};
	    }
	    # Isolated tag
	    elsif(!exists $elements[$i]->{ot}) {
		$target .= $elements[$i]->{txt}." ";
		$added{$trace_elem{$i}} = 1;
		delete $trace_elem{$i};
	    }
	}

	# Only closing trace elements are left, add them if the tags are currently open
	# Determine the deepest tag that needs to be closed in the cur_open stack
	my ($deepest) = grep($trace_elem{$elements[$_]->{ct}},@cur_open);
	# Close all elements on the cur_open stack up to the deepest
	my $closing_before = "";
	my $closing_after = "";
	if(defined $deepest) {
	    my $ot;
	    while(defined($ot = pop @cur_open)) {
		my $ct = $elements[$ot]->{ct};
		if($elements[$ct]->{gap}) {
		    $closing_after .= $elements[$ct]->{txt}." ";
		}
		else {
		    $closing_before .= $elements[$ct]->{txt}." ";
		}
		$added{$ot} = 1;
		$added{$ct} = 1;
		if(exists $trace_elem{$ct}) {
		    delete $trace_elem{$ct};
		}
		if($ot == $deepest) {
		    last;
		}
	    }
	}

	# Append the tags closing before, the target text and the tags closing after
	$target .= $closing_before."$1 ".$closing_after;

	# Store remaining closing tags in a hash
	@pending_close{ keys %trace_elem } = values %trace_elem;
    }

    # Emit the elements that weren't added yet to the end of the target
    foreach $i (grep(!$added{$_},0..$#elements)) {
	$target .= $elements[$i]->{txt}." ";
    }

    $target =~ s/\s$//;
    return $target;
}

1;

__END__

=head1 NAME

reinsert.pm: Reinsert markup from source InlineText into translation
with Moses

=head1 USAGE

    perl reinsert.pm source_tokenized_InlineText_file < traced_target > target_tokenized_InlineText_file

Script to reinsert markup from source InlineText into plain text Moses output
with traces (traces are phrase alignment information). 

C<source_tokenized_InlineText_file> is expected to be a tokenized version of the 
InlineText file format output by the Moses Text Filter of 
L<Okapi|http://okapi.opentag.com>. 

C<traced_target> is the output of the Moses decoder invoked with the C<-t> 
option. When invoked with the C<-t> option, the Moses decoder outputs 
phrase alignment information which indicates which source phrases where 
translated with which target phrases. C<reinsert.pm> uses this information 
to insert XLIFF inline elements roughly at the correct positions in 
the target text.

The output C<target_tokenized_InlineText_file> is a tokenized version of the
target text with XLIFF inline elements inserted. Detokenization still needs
to be applied where appropriate.

The script follows these principles when reinserting inline elements:

=over

=item 1. All inline elements that are present in the source text have to be placed in the target text

=item 2. For paired inline elements the closing tag always has to be placed after the opening tag

=item 3. Multiple paired inline elements can only enclose each other, they cannot overlap (this is required by XML) 

=item 4. Opening tags of inline elements are to be placed as close as possible before the correct target word token

=item 5. Closing tags of inline elements are to be placed as close as possible after the correct target word token (unless this violates constraint 2.)

=back

Input is expected to be UTF-8 encoded (without a leading byte-order 
mark U+FEFF) and output will be UTF-8 encoded as well. 

