#!/usr/bin/perl -w
$|++;


#
# Script to convert XLIFF file into input file for Moses
#
# Copyright 2012 Moravia Worldwide (xhudik@gmail.com)
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

# Usage: xliff2moses.pl  -sl en -tl de <Inline_source >Inline_target

use warnings;
use strict;
use Getopt::Long;
use remove_markup;
use wrap_tokenizer;
use wrap_detokenizer;
use reinsert;


    #source language
    my $sl = "en";

    #target language
    my $tl = "de";

    #tokenizer program
    my $tok_prog = "./tokenizer.perl";

    #tokenizer parameters
    my @tok_param;

    #moses
    my $moses_prog = "./moses";
    my $moses_param = "-f moses.ini -t";

    #tokenizer program
    my $detok_prog = "./detokenizer.perl";

    #tokenizer parameters
    my @detok_param;



    my $HELP=0;
    binmode( STDIN,":utf8");
    #binmode( STDOUT, ":utf8" );
    binmode( STDERR, ":utf8" );

 
  
    my $opt_status = GetOptions(
        'sl=s'   => \$sl,
        'tl=s'   => \$tl,
        'help!' => \$HELP,
    );

  if ( ( !$opt_status ) || ($HELP) ) {
        print "\n$0 converts source InlineText into target InlineText.\n";
        print "\nUSAGE: perl $0 [-sl -tl] < inFile > outFile\n";
        print "\t -sl source language (default en)\n";
        print "\t -tl target language (default: de)\n";
        print "\tinFile - InlineText source file, output of Okapi Tikal (parameter -xm)\n";
        print "\toutFile - InlineText taret file, input for Okapi Tikal (parameter -lm)\n";
	print "\tNote: many finer-grained options can be adjusted inside this program\n";

        exit;
    }

 
@tok_param = split(" ", "-l $sl -q");
my $tokenizer = new wrap_tokenizer($tok_prog, @tok_param);


my $detokenizer = new wrap_detokenizer($detok_prog, "-l $tl -q");



while(my $line = <STDIN>){
    chomp($line);

    #tokenization
    my $tok = $tokenizer->processLine($line);
    my $rem = remove_markup::remove("",$tok);

    #lowercasing
    my $lower = lc($rem);


    #moses
    my $tmp="cat 7.mos | $moses_prog $moses_param";
    my $moses = `$tmp`;


    #reinsert
    my @elements = reinsert::extract_inline($tok);
    my $reins  = reinsert::reinsert_elements($moses,@elements);

    #truecasing
   

    #detokenization

    $detokenizer->processLine($reins);
    my $detok = $detokenizer->detok();

   print "$detok\n";

}


__END__

TODO:
1. make uniform interface for each modulino script
2. wrap_detokenizer (detokenizer - only a few languages)
3. handling of STDERR 




