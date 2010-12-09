#!/usr/bin/perl -w

#
# Removal of empty lines from a sentence aligned corpus
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
