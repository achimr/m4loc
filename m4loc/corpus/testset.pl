#!/usr/bin/perl -w

#
# Random line selection from a text file
#
# Copyright 2010 Digital Silk Road
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

our ($opt_n,$opt_o,$opt_h);
getopts("n:o:h:");
if(!$opt_n) {
    print STDERR "Usage: perl $0 -n number [-o outputfile] [-h heldoutfile] < IN_FILE\n";
    exit;
}
my $n = $opt_n;
my $outputfile = $opt_o?$opt_o:"test.out";
my $heldoutfile = $opt_h?$opt_h:"test.hld";

open(OUTFILE,">", $outputfile) or die "Could not open $outputfile.";
open(HLDFILE,">", $heldoutfile) or die "Could not open $heldoutfile.";

my @lines = ();
# Gather all lines of the input file into an array
while(<STDIN>)
{
	chomp;
	push @lines,$_;
}
my $num_lines = $#lines;
my @lineindex = (0..$num_lines);

my @randindex;
for(my $i = 0 ; $i < $n ; $i++) {
    push @randindex, splice @lineindex,rand($num_lines--),1;
}
my @randsorted = sort {$a <=> $b} @randindex;

# Write held out sentences
print STDERR "Writing held out lines ...\n";
for(my $i = 0; $i <= $#lineindex; $i++) {
    print HLDFILE $lines[$lineindex[$i]],"\n";
}

# Write randomly selected lines and indices on STDERR
print STDERR "Writing randomly selected lines ...\n";
for(my $i = 0; $i <= $#randsorted; $i++) {
    print OUTFILE $lines[$randsorted[$i]],"\n";
    print STDOUT $randsorted[$i],"\n";
}

close(HLDFILE);
close(OUTFILE);

__END__

=head1 NAME

testset.pl - Random line selection from a text file

=head1 USAGE

    perl testset.pl -n number [-o outputfile] [-h heldoutfile] < IN_FILE

This tool reads a text corpus from standard input and writes randomly selected C<number> lines to the file C<test.out> (file name can be changed with -o option). It also writes the line indices of the selected lines (zero-indexed) to standard output. The held out lines (i.e. lines that were not selected for the random test set) get written to the file C<test.hld> (file name can be changed with -h option).

The line indices written to standard output can be captured in a file and used in conjunction with the scripts C<lineextract.pl> and C<heldextract.pl> to extract the selected and held out lines from another text file with the same number of lines. This is very useful for creating training, test and evaluation sets from parallel corpora.


=head1 PREREQUISITES

Getopt::Std
