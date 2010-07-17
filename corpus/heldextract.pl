#!/usr/bin/perl -w

use strict;

#
# Extract complement lines from a text file based on  line numbers file 
#
# Copyright 2010 Digital Silk Road
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
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
