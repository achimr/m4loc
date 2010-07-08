#!/usr/bin/perl -w

#
# Extraction of a bilingual corpus from a TMX file
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
use XML::TMX::Reader;

if(@ARGV != 4) {
    print STDERR "Usage: perl $0 <source language> <target language> <output basename> <tmx file>\n";
    exit;
}

my ($srcLang,$tgtLang,$outBase,$tmxFile) = @ARGV;

my $reader = XML::TMX::Reader->new($tmxFile);
die "TMX file $tmxFile could not be opened" unless defined($reader);
open(SRCOUT,">:utf8",$outBase.".".$srcLang) || die "Cannot open source output file: $outBase.$srcLang";
open(TGTOUT,">:utf8",$outBase.".".$tgtLang) || die "Cannot open target output file: $outBase.$tgtLang";

# Cannot use the for_tu interface here - process will run out of memory on larger files
$reader->for_tu2(sub{
    my $tu = shift;
    if(exists($$tu{$srcLang}) && exists($$tu{$tgtLang})) {
	# Necessary as some tu's can contain newlines
	my $srcText = $$tu{$srcLang};
	my $tgtText = $$tu{$tgtLang};
	$srcText =~ s/<ut>.*?<\/ut>//g;
	$srcText =~ s/<\S.*?>//g;
	$srcText =~ s/^\s*//;
	$srcText =~ s/\s*$//;
	$tgtText =~ s/<ut>.*?<\/ut>//g;
	$tgtText =~ s/<\S.*?>//g;
	$tgtText =~ s/^\s*//;
	$tgtText =~ s/\s*$//;
	chomp $srcText;
	chomp $tgtText;
	if($srcText && $tgtText) {
	    print SRCOUT $srcText."\n";
	    print TGTOUT $tgtText."\n";
	}
    }
});

close(TGTOUT);
close(SRCOUT);

__END__

=head1 tmx2txt.pl: Extraction of a bilingual corpus from a TMX file

=head2 USAGE

    perl tmx2txt.pl <source language> <target language> <output basename> <tmx file>

This tool extracts a bilingual corpus from a TMX file that contains segments in at least two languages. The resulting parallel corpus is stored in two files named C<< <output basename>.<source language> >> and C<< <output basename>.<target language> >> which are UTF-8 encoded. The tool does not verify if the two languages specified on the command line actually exist in the TMX file.

The tool removes any inline formatting markup to allow the use of the corpus for the training of statistical MT systems.

C<< <output basename> >> and C<< <tmx file> >> can contain a path component in case the files are contained in a different directory. The tool needs write permission in the output directory.

=head2 PREREQUISITES

XML::TMX::Reader
