#!/usr/bin/perl -w

#
# Removal of markup from sentence-split, optionally tokenized text file
# to allow the translation of the contained text with Moses, output and input
# are expected to be UTF-8 encoded (without leading byte-order mark)
#
# Copyright 2011 Digital Silk Road
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

binmode(STDIN,":utf8");
binmode(STDOUT,":utf8");

if(@ARGV != 0) {
    die "Usage: $0 < <text file with markup> > <plain text file>\n";
}

while(<>) {
    chomp;
    s/<.*?>//g;
    s/\s\s+/ /g;
    print;
    print "\n";
}


__END__

=head1 remove_markup.pl: Removal of bracketed markup from text file

=head2 USAGE

    perl remove_markup.pl < <text file with markup> > <plain text file>

This tool removes markup from a sentence-split, optionally tokenized text file 
to allow the translation of the contained text with Moses. Input is 
expected to be UTF-8 encoded (without a leading byte-order mark U+FEFF) and output will be UTF-8 encoded as well. Any text between C<< < >> and C<< > >> brackets gets removed. Any unmatched brackets do not get removed as these can be valid text that needs to be translated (e.g. "The thermometer shows a temperature < 32 E<deg>F .".

As part of the markup removal the script also collapses consecutive whitespace 
into one space character.
