#!/usr/bin/perl -w

#
# Generate template XML file for NIST BLEU scorer
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

if(@ARGV != 6) {
    die "Usage: perl $0 <src|tst|ref> <system id> <set id> <source language id> <target language id> <number of entries>\n"
}

my $type = shift;
my $systemID = shift;
my $setID = shift;
my $srcLangID = shift;
my $tgtLangID = shift;
my $entries = shift;
if ($type !~ /src|tst|ref/) {
    die "Type of generated file must be src|tst|ref\n"
}

print "<${type}set setid=\"$setID\" srclang=\"$srcLangID\" trglang=\"$tgtLangID\">\n";
print "<DOC sysid=\"$systemID\" docid=\"$setID\">\n";
for(my $i = 1 ; $i <= $entries ; $i++) {
    print "<seg id=$i>template</seg>\n";
}
print "</DOC>\n</${type}set>\n";

__END__

=head1 NAME

genEvalTemplate.pl - Generate template XML file for NIST BLEU scorer

=head1 USAGE

    perl genEvalTemplate.pl <src|tst|ref> <system id> <set id> <source language id> <target language id> <number of entries>\n"

This tool generates a template XML file for the NIST BLEU scorer (L<http://www.itl.nist.gov/iad/mig/tools/>; file: C<mteval*>). 

The following parameters need to be supplied:

=over

=item C<< <src|tst|ref> >>

Indicates if a template for a source, test or reference file should be generated

=item C<< <system id> >>

Name of MT sytem with which the set was created

=item C<< <set id> >>

Name of evaluation set

=item C<< <source language id> >>

2-letter ISO-639 source language identifier

=item C<< <target language id> >>

2-letter ISO-639 target language identifier

=item C<< <number of entries> >>

Number of lines in the evaluation set

=back

This script only generates a template - text for the evaluation still needs to be inserted with C<wrap-xml.pl> contained in the Moses MT scripts.
