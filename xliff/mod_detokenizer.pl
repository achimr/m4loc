#!/usr/bin/perl -w

#
# Script mod_detokenizer.pl detokenizes data from Markup Reinserter; after 
# this step, tikal -lm takes place. mod_detokenizer is a part of M4Loc effort
# http://code.google.com/p/m4loc/. Moses' detokenizer.perl and 
# nonbreaking_prefixes direcory are required by the script.
#
#
#
# © 2011 Moravia a.s. (DBA Moravia WorldWide),
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
#
#

use strict;
use File::Temp;

#GLOBAL VARIABLES

#language can be specified by user, otherwise is used en as default. It is used in
#tokenizer.perl script (part of Moses SW package)
my $lang = "en";


#print out help info if some incorrect options has been inserted
my $HELP = 0;

#END OF GLOBAL VARIABLES

#MAIN PROGRAM

while (@ARGV) {
    $_ = shift;
    /^-l$/ && ( $lang = shift, next );
    /^(?!-l$)/ && ( $HELP = 1, next );
}

if ($HELP) {
    print "\nmod_detokenizer.pl detokenize inLineText format.\n";
    print "\nUSAGE: ./mod_detokenizer (-l [de|en|...]) < inFile > outFile\n";
    print "\t -l language for detokenization/segmentation (detokenizer.perl)\n";
    print "\tinFile - tokenized text file, output of Markup Reinserter\n";
    print "\toutFile - detokenized text file, possible input for Tikal\n";
    exit;
}


my $line;

#create tmp file for storing encapsulated inLineText data (output of tikal -xm)
my $tmpout = File::Temp->new( DIR => '.', TEMPLATE => "tempXXXXX", UNLINK => "1" );

#for QA only
my $str="";

#read and process STDIN
while ( $line = <STDIN> ) {
chomp($line);
#for QA only
#$str .= $line."\n";

     #insert space before < tag if is not already
     if( $line =~ /\S\<(?!\/)/ ){
    	$line =~ s/(\S)\<(?!\/)/$1 \</g;
    }

    #remove space after closing tag /> if there is some
    if($line =~ /(\/\>|\<\/)\s+\S/){
    	$line =~ s/(\/\>|\<\/)\s+/$1/g;
    }

    #remove space after closing tag </ ..> if there is some
    if($line =~ /(\<\/(\w+|\s+))\>\s+/){
      $line =~ s/(\<\/(\w+|\s+))\>\s+/$1\>/g;
    }

     print($tmpout $line . "\n" );
}

#for QA only
#print "-------------------------------------------------------\n";
#print "$str\n";

close($tmpout);

system("perl detokenizer.perl -q -l $lang < $tmpout");
#2> /dev/null ");

__END__

=encoding utf8

=head1 mod_detokenizer.pl: detokenize InLineText format

=head2 Description 

It detokenizes data to InlineText; this data is ready for tikal -lm input (Okapi Framework). 
mod_detokenizer.pl is a part of M4Loc effort L<http://code.google.com/p/m4loc/>. The output is 
detokenized text with proper XML/XLIFF tags. For lower level specification, check the code,
it is well-documented and sometimes written in self-documenting  style.

The script takes data from standard input, process it and the output is written to the standard 
output. Input and output are UTF-8 encoded data. 


=head3 USAGE

C<< perl mod_detokenizer.pl (-l [en|de|...]) < inFile > outFile >>


where B<inFile> contains  data from Markup Reinserter (M4Loc) and B<outFile> 
is ready to be processed by tikal -lm process (Okapi framework). Workflow:
L<http://bit.ly/gOms1Y>

The detokenization process is language specific. The option B<-l> specifies the language. The script has to be put in
the same directory as Moses' detokenizer.perl is, since the script is using detokenizer.perl and languge specific
detokenization rules written in nonbreaking_prefixes sub-directory.


=head3 Author

Tomáš Hudík, thudik@moraviaworldwide.com


=head3 TODO:

1. strict testing (QA), since it is likely that more sophisticated approach will be required

