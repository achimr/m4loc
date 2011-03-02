#!/usr/bin/perl -w

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
	my @traced = split;
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
	print $recased_traced,"\n";
    }
    else {
	die "Recased target file has fewer lines than Moses output file";
    }
}

close($ifh);


