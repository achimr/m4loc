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
    my %pending_close;
    while($traced_target =~ /\G(.*?)\s*\|(\d+)-(\d+)\|\s*/g) {
	my $content = $1;
	my @trace_elements =();
	# Determine which inline elements are opened or closed in the current trace
	foreach $i (0..$#elements) {
	    if(exists $elements[$i]->{s}) {
		if($elements[$i]->{s} >= $2 && $elements[$i]->{s} <= $3) {
		    push @trace_elements, $i;
		    $added{$i} = 1;
		    # Check if corresponding closing element is expecting close
		    if(exists $elements[$i]->{ct} && $pending_close{$elements[$i]->{ct}}) {
			push @trace_elements, $elements[$i]->{ct};
			$added{$elements[$i]->{ct}} = 1;
			# Eliminate gap for closing elements emitted late
			$elements[$elements[$i]->{ct}]->{gap} = 0;
			delete $pending_close{$elements[$i]->{ct}};
		    }
		}
	    }
	    else {
		if($elements[$i]->{e} >= $2 && $elements[$i]->{e} <= $3) {
		    # Corresponding opening tag already emmitted?
		    if($added{$elements[$i]->{ot}}) {
			push @trace_elements, $i;
			$added{$i} = 1;
		    }
		    else {
			$pending_close{$i} = 1;
		    }
		}
	    }
	}

	# Emit tags and content for trace
	my $content_emitted = 0;
	foreach $i (@trace_elements) {
	    if(!$content_emitted && exists $elements[$i]->{gap} && $elements[$i]->{gap}) {
		$target .= $content." ";
		$content_emitted = 1;
	    }
	    $target .= $elements[$i]->{txt}." ";
	}
	if(!$content_emitted) {
	    $target .= $content." ";
	}
    }

    # Emit the elements that weren't added yet to the end of the target
    # TBD: This really should not be necessary, if the algorithm is working
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

