#!/usr/bin/perl -w

use strict;

#
# Extract complement lines from a text file based on  line numbers file 
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

if(@ARGV != 1) {
    print STDERR "Usage: perl $0 linesfile < INFILE > OUTFILE\n";
    exit;
}

open(LINES,"<",$ARGV[0]) or die "Could not open lines file $ARGV[0]";

my $counter = 0;
my $nextline = <LINES>;
while(<STDIN>) {
    if($nextline && $counter == $nextline) {
	$nextline = <LINES>;
    } else {
	print;
    }
    $counter++;
}

close(LINES);

__END__

=head1 NAME

heldextract.pl - Extract complement lines from a text file based on line numbers file

=head1 USAGE

    perl heldextract.pl linesfile < INFILE > OUTFILE

This tool reads a text corpus from standard input and a line numbers (zero-indexed) from C<linesfile>. It outputs the text corpus lines I<*not*> specified in the line numbers file to standard output.

The line numbers file can for example be created by the script C<testset.pl>.

=head1 PREREQUISITES
