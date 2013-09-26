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
	die "Usage: perl $0 < tokenized_source > wrapped_source\n";
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
__END__

=head1 NAME

wrap_markup.pm: Script to wrap markup present in tokenized source to funnel it unaffected through the Moses decoder

=head1 DESCRIPTION

InlineText markup is a subset of XLIFF inline markup for segments. One method to preserve InlineText markup present in source segments in Moses is to protect it from "I<translation>" by the decoder. This script wraps markup in XML that when used with the Moses option C<< -xml-input exclusive >> protects the markup from translation. It also introduces C<< <wall/> >> tags between the markup and surrounding text to keep tags in the exact order as in the source during decoding. This prevents phrase reordering across walls and can negatively impact translation quality.

=head1 USAGE

    perl wrap_markup.pm < tokenized_source > wrapped_source

=head2 EXPORT

=over

=item wrap_markup(tokenized_source)  

Wraps InlineText markup in XML markup compliant with the Moses XML input feature and inserts C<< <wall/> >> markup between formatting markup and translatable text. Returns wrapped text ready for decoding.

=back

=head1 PREREQUISITES

HTML::Entities
