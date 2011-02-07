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
    die "Usage: $0 <source InlineText file> < <target plain text file > > <target InlineText file>\n";
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

sub extract_inline {
    my $inline = shift;
    my @elements;
    my $i = 0;

    while($inline =~ /\G(.*?)<(\/?)(g|x|bx|ex)(\s.*?)?>/g) {
	my @tokens_before = split ' ',$1;
	$i += @tokens_before;
	# opening or isolated tags
	# issue?: this doesn't capture id's or handle overlapping tags
	if($2 ne '/') {
	    push @elements, {'el'=>$3,'s'=>$i,'txt'=>"<$3$4>"};
	}
	# closing </g> tag
	elsif($2 eq '/' && $3 eq 'g') {
	    # find the last opening <g> tag in the list
	    foreach my $rev_element (reverse @elements) {
		if($rev_element->{'el'} eq 'g') {
		    $rev_element->{'e'} = $i;
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

    my $target = "";
    my $i;
    my %cur_open;
$DB::single = 2;
my $foo = 1;
    while($traced_target =~ /\G(.*?)\s*\|(\d+)-(\d+)\|\s*/g) {
	my %trace_open;
	my %trace_close;
	foreach $i (0..$#elements) {
	    if($elements[$i]->{s} >= $2 && $elements[$i]->{s} <= $3) {
		$trace_open{$i} = 1;
	    }
	    if($elements[$i]->{e} && $elements[$i]->{e} >= $2 && $elements[$i]->{e} <= $3) {
		$trace_close{$i} = 1;
	    }
	}
	foreach $i (grep($trace_close{$_},keys %cur_open)) {
	    $target .= "</g> ";
	    delete $cur_open{$i};
	}
	foreach $i (reverse keys %trace_open) {
	    $target .= $elements[$i]->{txt}." ";
	    if($elements[$i]->{el} eq "g") {
		# If inline element doesn't cover any text, close right away
		if($elements[$i]->{s} == $elements[$i]->{e}) {
		    $target .= "</g> ";
		}
		else {
		    $cur_open{$i} = 1;
		}
	    }
	}
	$target .= "$1 ";
	# Check if any just opened inline elements need to be closed after the current trace
	foreach $i (grep($trace_close{$_},keys %cur_open)) {
	    $target .= "</g> ";
	    delete $cur_open{$i};
	}
    }
    foreach $i (keys %cur_open) {
	# TBD: the only closing tag is hardcoded
	$target .= "</g> ";
    }

    return $target;
}

