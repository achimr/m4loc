#!/usr/bin/perl -w
package recase_preprocess;

run() unless caller();

#
# Remove Moses traces (phrase alignment info) from translated text
# in preparation for correcting upper-/lowercase with the recaser
#
# Copyright 2011,2012 Digital Silk Road
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

sub run {
    binmode(STDIN,":utf8");
    binmode(STDOUT,":utf8");
    $|++;

    while(<>) {
	chomp;
	print remove_trace($_),"\n";
    }
}

sub remove_trace {
    my $traced = shift;

    $traced =~ s/\|\d+\-\d+\|\s*//g;
    return $traced;
}

1;

__END__

=head1 NAME

recase_preprocess.pm: Remove Moses traces from translated text

=head1 DESCRIPTION

Script to remove Moses traces (phrase alignment info) from translated text
in preparation for correcting upper-/lowercase with the recaser. Moses traces -
phrase alignment information enclosed in vertical bars C<|start-end|> - are
required to reinsert XLIFF inline element markup back into the text. However,
when applying a recaser model, the traces negatively impact the upper- and
lowercasing. To avoid this, the traces can be temporarily removed before
recasing and then reinserted with C<recase_postprocess.pm>. 

=head1 USAGE

    perl recase_preprocess.pm < target_with_traces > target_tokenized

Input is expected to be UTF-8 encoded (without a leading byte-order 
mark U+FEFF) and output will be UTF-8 encoded as well. 

=head2 EXPORT

=over

=item remove_trace(traced_target)  

Remove trace (phrase alignment) information from a sentence decoded with the Moses C<-t> option. Returns string with traces removed.

=back

