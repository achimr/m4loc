#!/usr/bin/perl -w
#
# Europarl corpus preparation
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
if(@ARGV != 4)
{
	print "Usage: perl $0 <base name old> <base name new> <source language> <target language>\n";
	exit;
}

my ($oldBase,$newBase,$srcLang,$tgtLang) = @ARGV;

open(EFILE, $oldBase.".".$srcLang) or die "Can't open source language input file $oldBase.$srcLang: $!\n";
open(FFILE, $oldBase.".".$tgtLang) or die "Can't open target language input file $oldBase.$tgtLang: $!\n";
open(EFILEC, ">$newBase.$srcLang") or die "Can't open source language output file $newBase.$srcLang: $!\n";
open(FFILEC, ">$newBase.$tgtLang") or die "Can't open target language output file $newBase.$tgtLang: $!\n";

my $eline;
my $fline;

while(defined($eline = <EFILE>) && defined($fline = <FFILE>))
{
	chomp $eline;
	chomp $fline;
	# Skip markup lines
	if($eline =~ /^\s*<.*>$/ || $fline =~ /^\s*<.*>$/ )
	{
		next;
	}
	# If there is one empty line in a file skip
	if($eline =~ /^\s*$/ || $fline =~ /^\s*$/)
	{
		next;
	}
	print EFILEC $eline,"\n";
	print FFILEC $fline,"\n";
}

close(FFILEC);
close(FFILE);
close(EFILEC);
close(EFILE);

__END__

=head1 NAME

epRemoveMarkup.pl - Europarl corpus preparation

=head1 USAGE

    perl epRemoveMarkup.pl <base name old> <base name new> <source language> <target language>

Cleans up Europarl corpus files for use as training input for Giza++ as suggested on L<http://www.statmt.org/europarl/>

=over

=item *

strip empty lines and their corresponding lines (highly recommended)

=item *

remove lines with XML-Tags (starting with "<") (required)

=back

The input corpus has to be available in the files C<< <base name old>.<source language> >> and C<< <base name old>.<target language> >>. The cleaned corpus will be written to the files C<< <base name new>.<source language> >> and C<< <base name new>.<target language> >>.

The script does not perform tokenization and lowercasing of the corpus - the Europarl tool set already has the tools C<tokenizer.perl> and C<lowercase.perl> available for this purpose.

=head1 PREREQUISITES
