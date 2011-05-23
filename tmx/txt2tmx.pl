#!/usr/bin/perl -w

use strict;

# 
# Script to convert a bilingual corpus (represented as two text files) into TMX
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

use XML::TMX::Writer;

if(@ARGV != 3) {
    die "Usage: perl $0 <source language> <target language> <base name>";
    exit;
}

my $srclang = shift @ARGV;
my $tgtlang = shift @ARGV;
my $basename = shift @ARGV;

open(SRCFILE,"<:utf8",$basename.".".$srclang) || die "Source file could not be opened";
open(TGTFILE,"<:utf8",$basename.".".$tgtlang) || die "Target file could not be opened";

my $tmx = new XML::TMX::Writer();
$tmx->start_tmx(SRCLANG=>$srclang,OUTPUT=>"$basename.tmx");
my ($srctext,$tgttext);
my $id=1;
while($srctext = <SRCFILE>) {
    $tgttext = <TGTFILE>;
    chomp $srctext;
    chomp $tgttext;
    $tmx->add_tu(ID=>$id,$srclang=>$srctext,$tgtlang=>$tgttext);
    $id++;
}
$tmx->end_tmx();

close(SRCFILE);
close(TGTFILE);

__END__

=head1 txt2tmx.pl: Parallel Corpus to TMX converter

=head2 USAGE

    perl txt2tmx.pl <source language> <target language> <base name>

The purpose of this tool is to take two corpus input files named C<< <base name>.<source language> >> and C<< <base name>.<target language> >> and merge them into a bi-lingual TMX file named C<< <base name>.tmx >>. 

The input files need to be encoded encoded in UTF-8 (preferably without a leading Unicode byte-order mark U+FEFF), the tool will not perform a verification of the input encoding. 

The base name can contain a path component in case the files are contained in a different directory. The tool needs write permission in the target directory.

=head2 PREREQUISITES

XML::TMX::Writer
