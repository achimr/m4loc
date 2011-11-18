#!/usr/bin/perl -w
package decode_markup;
run() unless caller();

use strict;

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

use HTML::Entities;

sub run {
    binmode(STDIN,":utf8");
    binmode(STDOUT,":utf8");

    if(@ARGV != 0) {
	die "Usage: perl $0 < encoded_target > decoded_target\n";
    }

    while(<STDIN>) {
	chomp;
	print decode_markup($_),"\n";
    }
}

sub decode_markup {
    my $source = shift;

    # TBD: This could also decode entities that were already encoded before the application of wrap_markup
    return decode_entities($_);
}

1;
