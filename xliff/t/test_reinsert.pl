#!/usr/bin/perl -w

#
# Test script to compare output of different tag reinsertion methods
#
# Copyright 2012 Digital Silk Road
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

if(@ARGV != 3) {
    die "Usage: perl $0 src_lang tgt_lang greedy\n";
}

my $src_lang = shift @ARGV;
my $tgt_lang = shift @ARGV;
my $greedy = shift @ARGV;
my $method = $greedy ? "reinsert_greedy" : "reinsert";

my @tok_files = <*.tok.$src_lang>;
# my @pseudo_files = map { s/tok\.$src_lang/psd.$tgt_lang/ } @tok_files;
my @pseudo_files = map { /(.*)\.tok\.$src_lang/; "$1.psd.$tgt_lang" } @tok_files;

if (!-d $method) {
    mkdir($method);
}
foreach my $tok_file (@tok_files) {
    $tok_file =~ /(.*)\.tok\.$src_lang/;
    my $base_name = $1;
    print "Processing: $base_name ...\n";
    `perl ../$method.pm $tok_file < $base_name.psd.$tgt_lang > $method/$base_name.ins.$tgt_lang`;
}
