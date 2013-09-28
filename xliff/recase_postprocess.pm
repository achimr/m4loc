#!/usr/bin/perl -w
package recase_postprocess;

run() unless caller();

#
# Reinsert Moses traces (phrase alignment info) into recased Moses output
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

sub run {
    binmode(STDIN,":utf8");
    binmode(STDOUT,":utf8");

    if(@ARGV != 1) {
	die "Usage: $0 <Moses output with traces> < <recased target file> > <recased target file with traces>\n";
    }

    open(my $ifh,"<:utf8",$ARGV[0]);

    while(<$ifh>) {
	chomp;
	if(my $recased_target = <STDIN>) {
	    chomp $recased_target;
	    print retrace($_,$recased_target),"\n";
	}
	else {
	    die "Recased target file has fewer lines than Moses output file";
	}
    }

    close($ifh);
}

sub retrace {
    my $traced = shift;
    my $recased_target = shift;

    my @traced = split (' ',$traced);
    my @recased = split(' ',$recased_target);
    my $recased_traced = "";
    foreach my $traced_token (@traced) {
	if($traced_token =~ /\|\d+\-\d+\|/) {
	    $recased_traced .= $&." ";
	}
	else {
	    $recased_traced .= shift @recased;
	    $recased_traced .= " ";
	}
    }
    return $recased_traced;
}

1;

__END__

=head1 NAME

recase_postprocess.pm: Reinsert Moses traces into recased Moses output

=head1 DESCRIPTION

Script to reinsert Moses traces (phrase alignment info) into recased target
language text. The traces are required to correctly reinsert formatting
markup (e.g. XLIFF inline elements) with the script C<reinsert.pm>.
C<lowercased_traced_target> is the output of Moses with the
C<-t> option. C<recased_target> is the output of a recasing model
created with Moses (refer to the Moses documentation for further information).

=head1 USAGE

    perl recase_postprocess.pm lowercased_traced_target < recased_target > recased_traced_target

Input is expected to be UTF-8 encoded (without a leading byte-order 
mark U+FEFF) and output will be UTF-8 encoded as well. 

=head2 EXPORT

=over

=item retrace(traced_target,recased_target)  

Reinsert Moses traces (phrase alignment info) present in C<traced_target> into recased target language text C<recased_target>. Returns string.

=back

