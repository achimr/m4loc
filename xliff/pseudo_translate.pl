#!/usr/bin/perl -w

#
# Translation of text into pig-latin with Moses traces for debugging
# purposes; input and output are expected to be UTF-8 encoded 
#
# Copyright 2011 Digital Silk Road
# Subroutine _translate_text_pig_latin: Copyright 2011 Herve Saint-Amand
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

while(<>) {
    chomp;
    print _translate_text_pig_latin($_);
    print "\n";
}

# This sub is used when you want to debug everything in this script except the
# actual translation. Translates to Pig Latin.
#
# This subroutine was written by Herve Saint-Amand
# and copied from translate.cgi in the Moses codebase

sub _translate_text_pig_latin {
    my ($text) = @_;

    $text =~ s/\b([bcdfhj-np-tv-z]+)([a-z]+)/
        ($1 eq ucfirst $1 ? ucfirst $2 : $2) .
        ($2 eq lc $2 ? lc $1 : $1) .
        'ay';
    /gei;

    # insert fake traces
    my $i = -1;
    $text .= ' ';
    $text =~ s/\s+/$i++; " |$i-$i| "/ge;

    return $text;
}

