#!/bin/perl -w
package pos_tokenizer;

run() unless caller();

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

# Always flush output buffers
$|++;

use strict;
use IPC::Open2;
use Algorithm::Diff qw(compact_diff);
use FindBin qw($Bin);

sub run {
    # Initialize external tokenizer process
    my @tokenizer = @ARGV ? @ARGV : ("perl","$Bin/tokenizer.perl");
    my ($tokin, $tokout) = initalize(@tokenizer);

    while(<STDIN>) {
	# Remove markup and record positions
	chomp;
	print tokenize($tokin,$tokout,$_);
	print "\n";
    }
}

sub initalize {
    my ($TOK_IN, $TOK_OUT);
    my $pid = open2 ($TOK_OUT, $TOK_IN, @_);
    return ($TOK_IN,$TOK_OUT);
}

sub tokenize {
    my $tokin = shift;
    my $tokout = shift;
    my $in = shift;

    my $lastpos = 0;
    my $nomarkup = "";
    my @markup;
    while($in =~ /<\/?(g|x|bx|ex|lb|mrk).*?>/g) {
	$nomarkup .= substr($in,$lastpos,$-[0]-$lastpos);
	push @markup, [length($nomarkup), substr($in,$-[0],$+[0] - $-[0])];
	$lastpos = $+[0];
    }
    $nomarkup .= substr($in,$lastpos);
    $nomarkup =~ s/\s\s+/ /g;

    # Call tokenizer
    print $tokin $nomarkup,"\n";
    $tokin->flush();
    my $tok = scalar <$tokout>;
    chomp $tok;
    $tok =~ s/\r$//;

    # Call diff
    my @nomarksplit = split(//,$nomarkup);
    my @toksplit = split(//,$tok);
    # This is sensitive to the tokenizer not removing any characters
    # Possible alternative: simpler algorithm detecting extra spaces
    my @cdiff = compact_diff(\@nomarksplit,\@toksplit);

    # Adjust indexes for removed markup
    my $hunk = 2;
    foreach my $mark (@markup) {
	while($hunk*2+2 < $#cdiff) {
	    if($$mark[0] >= @cdiff[$hunk*2] && $$mark[0] <= @cdiff[$hunk*2+2]-1) {
		$$mark[0] += @cdiff[$hunk*2+1]-@cdiff[$hunk*2];
		last;
	    }
	    else {
		$hunk +=2;
	    }
	}
    }

    # Reinsert removed markup into tokenized string
    my $output = "";
    my $index = 0;
    for my $mark (@markup) {
	$output .= substr($tok,$index,$$mark[0]-$index);
	$output .= " ".$$mark[1]." ";
	$index = $$mark[0];
    }
    if($index < length($tok)) {
	$output .= substr($tok,$index);
    }
    $output =~ s/\s\s+/ /g;
    $output =~ s/^\s//;
    $output =~ s/\s$//;

    return $output;

}

1;
