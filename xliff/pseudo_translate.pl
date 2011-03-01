#!/usr/bin/perl -w

#
# Translation of text into pig-latin with Moses traces for debugging
# purposes; input and output are expected to be UTF-8 encoded 
#
# Copyright 2011 Digital Silk Road
# Subroutine _translate_text_pig_latin: Copyright 2011 Herve Saint-Amand
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
use List::Util qw(shuffle);

binmode(STDIN,":utf8");
binmode(STDOUT,":utf8");

our $opt_n;
getopts("n:");
if(@ARGV != 0) {
    die "Usage: $0 [-n <max phrase length>] < <tokenized lowercased source file> > <pseudo translated output file>\n";
}
my $max_phrase_len = $opt_n?$opt_n:1;

# print "Maximum phrase length: $max_phrase_len\n";

while(<>) {
    chomp;
    my @tokens = split;
    # Create array of start/end hashes with maximum length $phrase_len
    if(@tokens) {
	my $i = 0;
	my @phrase_index;
	while($i <= $#tokens) {
	    # Conditional needed because rand(0) is special cased as rand(1) according to documentation
	    my $rand_pl = $max_phrase_len==1 ? 0 : int(rand($max_phrase_len));
	    my $phrase_end = $i+$rand_pl < $#tokens ? $i+$rand_pl : $#tokens;
	    push @phrase_index, {"s"=>$i,"e"=>$phrase_end};
	    $i = $phrase_end+1;
	} 

	# Shuffle start/end array
	my @shuffled_phrases = shuffle(@phrase_index);

	# Output pig latin translations and traces
	foreach my $phrase (@shuffled_phrases) {
	    print _translate_text_pig_latin(join(' ',@tokens[$phrase->{'s'}..$phrase->{'e'}]));
	    print ' ';
	    print '|'.$phrase->{'s'}.'-'.$phrase->{'e'}.'| ';
	}
    }
    # New line if there were tokens or not
    print "\n";

}

# This sub is used when you want to debug everything in this script except the
# actual translation. Translates to Pig Latin.
#
# This subroutine was written by Herve Saint-Amand
# and copied from translate.cgi in the Moses codebase
# insertion of fake traces removed

sub _translate_text_pig_latin {
    my ($text) = @_;

    $text =~ s/\b([bcdfhj-np-tv-z]+)([a-z]+)/
        ($1 eq ucfirst $1 ? ucfirst $2 : $2) .
        ($2 eq lc $2 ? lc $1 : $1) .
        'ay';
    /gei;

    return $text;
}

