#!/usr/bin/perl -w
$|++;


#
# Script to convert XLIFF file into input file for Moses
#
# Copyright 2011-2012 Moravia Worldwide (xhudik@gmail.com)
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

# Usage: m4loc.pl  -sl en -tl de -i file.tmx

use warnings;
use strict;
use FindBin qw/$Bin/;
use Getopt::Long;
use remove_markup;
use wrap_tokenizer;
use wrap_detokenizer;
use recase_preprocess;
use recase_postprocess;
use fix_markup_ws;
use reinsert;



    #source language
    my $sl = "en";

    #target language
    my $tl = "de";

    #Okapi Tikal
    my $tikal = "~/sources/okapi/./tikal.sh";

    #tokenizer program
    my $tok_prog = "perl $Bin/tokenizer.pm";

    #tokenizer parameters
    my @tok_param;

    #moses
    my $moses_prog = "./moses";
    my $moses_param = "-f moses.ini -t";

    #truecasing program
    my $truecase_prog = "./moses";
    my $truecase_param = "-f moses.ini";


    #tokenizer program
    my $detok_prog = "perl detokenizer.pm";

    #tokenizer parameters
    my @detok_param;


    #input & output program
    my $input;
    my $output;

    my $HELP=0;
    #binmode( STDIN,":utf8");
    #binmode( STDOUT, ":utf8" );
    #binmode( STDERR, ":utf8" );

 
  
    my $opt_status = GetOptions(
        'sl=s'   => \$sl,
        'tl=s'   => \$tl,
	'i=s' => \$input,
	#'o=s' => \$output,
        'help!' => \$HELP,
    );


  if ( (!defined($input)) || ( !$opt_status ) || ($HELP) ) {
        print "\n$0 converts source InlineText into target InlineText.\n";
        print "\nUSAGE: perl $0 [-sl -tl]  -i input  -o output\n";
        print "\t -sl source language (default en)\n";
        print "\t -tl target language (default: de)\n";
        print "\t -i input - any translation format acceptable by Okapi Tikal (tmx, xliff, ...)\n";
        #print "\t-o output - output file\n";
	print "\tNote: many finer-grained options/paths/programs can be adjusted inside this program\n";

        exit;
    }


#tikal - conversion into Inline format 

my $command = "$tikal -xm $input -2 -sl $sl -tl $tl -to tmpfile";
print "$command\n";
system($command);

my $tmpin = "tmpfile.$sl";
open(TMPIN, "<:encoding(UTF-8)",$tmpin);
my $tmpout = "outtmp";
open(TMPOUT, ">:encoding(UTF-8)",$tmpout);


@tok_param = split(" ", "-l $sl -q");
my $tokenizer = new wrap_tokenizer($tok_prog, @tok_param);
my $detokenizer = new wrap_detokenizer($detok_prog, "-l $tl -q");


print "Processing $tmpin file...\n";

while(my $source = <TMPIN>){
    chomp($source);

    #tokenization
    my $tok = $tokenizer->processLine($source);
    my $rem = remove_markup::remove("",$tok);

    #lowercasing
    my $lower = lc($rem);


    #moses - BE CAREFUL - USER OWN WAY OF CALLING MOSES HAS TO BE SET UP!!!
    #ECHO IS NOT GOOD FUNCTION SINCE INPUT CAN'T CONTAIN ' CHAR
    my $tmp="echo '$lower' | $moses_prog $moses_param";
    my $moses = `$tmp`;

    #truecasing
    my $truecasing_pre = recase_preprocess::remove_trace($moses);
    #moses trucaser - BE CAREFUL - USER OWN WAY OF CALLING MOSES HAS TO BE SET UP!!!
    #ECHO IS NOT GOOD FUNCTION SINCE INPUT CAN'T CONTAIN ' CHAR   
    $tmp="echo '$truecasing_pre' | $truecase_prog $truecase_param";
    my $truecasing = `$tmp`;
    my $truecasing_post = recase_postprocess::retrace($moses, $truecasing);

    #reinsert
    my @elements = reinsert::extract_inline($tok);
    my $reins  = reinsert::reinsert_elements($truecasing_post,@elements);

    #detokenization
    $detokenizer->processLine($reins);
    my $detok = $detokenizer->detok();

    #fix whitespaces around tags
    my $fix = fix_markup_ws::fix_whitespace($source, $detok);

   print TMPOUT "$fix\n";

}

print "...Done\n";
close(TMPIN);
close(TMPOUT);

#pick up results and put it back into original file
$command = "$tikal -lm  $input -from $tmpout ";
print "$command\n";
system($command);

unlink $tmpin or warn "Couldn't delete $tmpin file";
unlink $tmpout or warn "Couldn't delete $tmpout file";


__END__

TODO:
1. make uniform interface for each modulino script
2. wrap_detokenizer (detokenizer - only a few languages)
3. handling of STDERR 




