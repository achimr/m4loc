#!/usr/bin/perl -w
package wrap_markup;
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
	die "Usage: perl $0 < tokenized_source > wraped_source\n";
    }

    while(<STDIN>) {
	chomp;
	print wrap_markup($_),"\n";
    }
}

sub wrap_markup {
    my $source = shift;


    my $inline_tags = "g|x|bx|ex|lb|mrk";
    my $remainder = $source;
    my $result = "";
    while($source =~ /\G(.*?)(<\/?(?:$inline_tags).*?>)/g) {
	$result .= $1;
	$result .= encode_tag($2);
	$remainder = $';
    }
    $result .= $remainder;

    return $result;
}

sub encode_tag {
    my $tag = shift;

    my $num_tag = HTML::Entities::encode_entities($tag);
    my $encoded_tag = "<wall/><np translation=\"$num_tag\">$num_tag</np><wall/>";
    return $encoded_tag;
}

1;
