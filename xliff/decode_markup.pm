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
    return decode_entities($source);
}

1;
__END__

=head1 NAME

decode_markup.pm: Decode markup that was escaped for funneling it through the decoder

=head1 DESCRIPTION

Using the script C<< wrap_markup.pm >> tagging markup gets escaped, wrapped in XML and using the C<< -xml-input exclusive >> Moses option funneled through the decoder. After decoding the tagging markup is still in its escaped form. The C<< decode_markup.pm >> modulino brings the escaped markup back into its previous form.

=head1 USAGE

    perl decode_markup.pm < encoded_target > decoded_target

=head2 EXPORT

=over

=item decode_markup(tokenized_target)  

Unescape markup contained in C<< tokenized_target >>

=back

=head1 KNOWN ISSUES

This could also decode entities that were already encoded before the application of wrap_markup.pm.

=head1 PREREQUISITES

HTML::Entities
