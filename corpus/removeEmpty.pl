#!/usr/bin/perl -w

#
# Removal of empty lines from a sentence aligned corpus
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

use strict;

if(@ARGV != 4) {
    print STDERR "Usage: $0 <source input file> <target input file> <source output file> <target output file>\n";
    exit;
}

my ($srcin,$tgtin,$srcout,$tgtout) = @ARGV;

open(SRCIN,"<:utf8",$srcin) || die "Cannot open source input file: $srcin";
open(TGTIN,"<:utf8",$tgtin) || die "Cannot open target input file: $tgtin";
open(SRCOUT,">:utf8",$srcout) || die "Cannot open source output file: $srcout";
open(TGTOUT,">:utf8",$tgtout) || die "Cannot open target output file: $tgtout";

my ($src,$tgt);
while($src=<SRCIN>) {
    $tgt=<TGTIN>;
    if($src !~ /^\s*$/ && $tgt !~ /^\s*$/) {
	print SRCOUT $src;
	print TGTOUT $tgt;
    }
}

close(TGTOUT);
close(SRCOUT);
close(TGTIN);
close(SRCIN);

__END__

=head1 NAME

removeEmpty.pl - Removal of empty lines from a sentence aligned corpus

=head1 USAGE

    perl removeEmpty.pl <source input file> <target input file> <source output file> <target output file>

Reads a sentence-aligned, parallel corpus from C<< <source input file> >> and C<< <target input file> >>, removes any lines where either source or target sentences are empty and writes the results to C<< <source output file> >> and C<< <target output file> >>.

=head1 PREREQUISTES
