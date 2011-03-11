#!/usr/bin/perl -w

#
# Reinsertion of markup from source InlineText into plain text translated
# with Moses, output and input are expected to be UTF-8 encoded 
# (without leading byte-order mark)
#
# Copyright 2011 Digital Silk Road
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

binmode(STDIN,":utf8");
binmode(STDOUT,":utf8");

#our $opt_a;
#getopts("a");
if(@ARGV != 1) {
    die "Usage: perl $0 source_InlineText_file < target_plain_text_file > target_InlineText_file\n";
}

my $inline_tags = "(g|x|bx|ex|lb|mrk)";

open(my $ifh,"<:utf8",$ARGV[0]);

# Read line from InlineText file
while(<$ifh>) {
    my @elements = extract_inline($_);
    if(my $traced_target = <STDIN>) {
	print reinsert_elements($traced_target,@elements);
	print "\n";
	#print $traced_target;
    }
    else {
	die "Target file has fewer lines than source file";
    }
}

close($ifh);

sub extract_inline {
    my $inline = shift;
    my @elements;
    my $i = 0;

    while($inline =~ /\G(.*?)<(\/?)$inline_tags(\s.*?)?>/g) {
	my @tokens_before = split ' ',$1;
	$i += @tokens_before;
	my $tag_text = defined $4 ? $3.$4 : $3;
	# opening or isolated tags
	if($2 ne '/') {
	    push @elements, {'el'=>$3,'s'=>$i,'txt'=>"<$tag_text>"};
	}
	# closing tags
	else {
	    # find the last corresponding opening tag in the list
	    for (my $j = $#elements; $j >= 0; $j--) {
		if($elements[$j]->{'el'} eq $3) {
		    push @elements, {'el'=>$3,'e'=>$i-1,'txt'=>"</$tag_text>",'ot'=>$j};
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

	# Append the target text
	$target .= "$1 ";

	# Only closing trace elements are left, add them if the tags are currently open
	# Determine the deepest tag that needs to be closed in the cur_open stack
	my ($deepest) = grep($trace_elem{$elements[$_]->{ct}},@cur_open);
	# Close all elements on the cur_open stack up to the deepest
	if(defined $deepest) {
	    my $ot;
	    while(defined($ot = pop @cur_open)) {
		my $ct = $elements[$ot]->{ct};
		$target .= $elements[$ct]->{txt}." ";
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

	# Store remaining closing tags in a hash
	@pending_close{ keys %trace_elem } = values %trace_elem;
    }

    # Emit the elements that weren't added yet to the end of the target
    foreach $i (grep(!$added{$_},0..$#elements)) {
	$target .= $elements[$i]->{txt}." ";
    }

    return $target;
}

