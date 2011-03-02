#!/usr/bin/perl -w

#
# Remove Moses traces (phrase alignment info) from translated text
# in preparation for correcting upper-/lowercase with the recaser
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

while(<>) {
    chomp;
    s/\|\d+\-\d+\|\s*//g;
    print;
    print "\n";
}
