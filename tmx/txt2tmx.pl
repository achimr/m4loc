#!/usr/bin/perl -w

use strict;

# 
# Script to convert a bilingual corpus (represented as two text files) into TMX
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
