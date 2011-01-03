#!/usr/bin/perl -w

#
# Script xml_entity.pl converts numeric character reference or character entity reference into 
# UTF-8 characters (http://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references).
# It also give a warning if data contains special character "|" 
# (http://www.mail-archive.com/moses-support@mit.edu/msg00860.html). The script is a part of M4Loc 
# effort http://code.google.com/p/m4loc/
#
#
#
# © 2010 Moravia a.s. (DBA Moravia WorldWide), 
# Moral Rights asserted by Tomáš Hudík thudik@moraviaworldwide.com
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




use strict;
use XML::Entities;


binmode(STDOUT,":utf8");
binmode(STDIN,":utf8");

my $lnumber = 0;

if(@ARGV > 0){
	print "\nIt converts XML entities into UTF-8 characters.\n";
	print "\nUSAGE: xml_entity < inFile > outFile\n"; 
	print "\tinFile - text file, textual output of Okapi Tikal (parameter -2tbl)\n";
	print "\toutFile - text file, input for Moses' tokenizer.pl\n";
	exit;
}

while (<STDIN>){
	$lnumber++;
	chomp;
	my $line = $_;
	XML::Entities::decode('all', $line);
	if ($line =~ m/\|/){
		print(STDERR "WARNING: line(".$lnumber.") contains \"|\". Moses' training will fail!\n");
	}
	print(STDOUT $line."\n");
}

print(STDERR "\nThat's it, dude ☻\n")


__END__

=head1 xml_entity.pl: converts XML entities into UTF-8

=head2 Description 

It converts XML entities (numeric character reference or character entity reference) into 
UTF-8 characters ( http://en.wikipedia.org/wiki/List_of_XML_and_HTML_character_entity_references ).
It also gives a warning if data contains special character "|" 
( http://www.mail-archive.com/moses-support@mit.edu/msg00860.html ).

The script takes data from standard input, decodes it and the output is written to standard 
output (e.g. "Tom &amp; Jerry &copy; Warner Bros&period;" is decoded to 
"Tom & Jerry © Warner Bros."). 


=head3 USAGE

C<< perl xml_entity.pl < inFile > outFile >>

where B<inFile> contains txt file (most likely a XLIFF file converted by Okapi Tikal into tab txt file) and B<outFile> 
is correctly UTF-8 encoded file 

It should be used after Okapi's Tikal (XLIFF to txt; parameter -2tbl) and before Moses' tokenizer.pl

=head3 PREREQUISITES

XML::Entities


=head3 Author

Tomas Hudik, thudik@moraviaworldwide.com



