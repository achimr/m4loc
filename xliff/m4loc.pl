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
    my $tok_prog = "perl tokenizer.pm";

    #tokenizer parameters
    my @tok_param;

    #moses
    my $moses_prog = "./moses";
    my $moses_param = "-f moses.ini -t";

    #recasing program
    my $recase_prog = "./moses";
    my $recase_param = "-f moses.ini";


    #tokenizer program
    my $detok_prog = "perl detokenizer.pm";

    #tokenizer parameters
    my @detok_param;


    #input & output program
    my $input;
    my $output;

    #if debug=1 some debug info are written into STDERR
    my $debug = 0;

    my $HELP=0;
    binmode( STDIN,":utf8");
    binmode( STDOUT, ":utf8" );
    binmode( STDERR, ":utf8" );

 
  
    my $opt_status = GetOptions(
        'sl=s'   => \$sl,
        'tl=s'   => \$tl,
	'i=s' => \$input,
        'help!' => \$HELP,
    );


  if ( (!defined($input)) || ( !$opt_status ) || ($HELP) ) {
        print "\n$0 converts source InlineText into target InlineText.\n";
        print "\nUSAGE: perl $0 [-sl -tl]  -i input \n";
        print "\t -sl source language (default en)\n";
        print "\t -tl target language (default: de)\n";
        print "\t -i input - any translation format acceptable by Okapi Tikal (tmx, xliff, ...)\n";
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


@tok_param = split(" ", "-l $sl");
@detok_param = split(" ","-l $sl");
my $tokenizer = new wrap_tokenizer($tok_prog, @tok_param);
my $detokenizer = new wrap_detokenizer($detok_prog, @detok_param);

print "\n\n\n";
print "Processing $tmpin file...\n";

NEW_LINE:while(my $source = <TMPIN>){
    chomp($source);

    #filter out empty lines
    if($source eq ""){
	print TMPOUT "\n";
	next NEW_LINE;
    }

    #tokenization
    print "tokenize ... " if $debug;
    my $tok = $tokenizer->processLine($source);
    warn "Problem during tokenization -- input:\"$source\"; no output!\n"    if($tok eq "");
    print "ok\nremove ..." if $debug;
    my $rem = remove_markup::remove("",$tok);
    warn "Problem during markup removal -- input:\"$tok\"; no output!\n"    if($rem eq "");
    print "ok\nlowercasing ..." if $debug;

    #lowercasing
    my $lower = lc($rem);
    print "ok\nmoses (translation) ..." if $debug;


    #moses - BE CAREFUL - USER SPECIFIC WAY OF CALLING OF MOSES HAS TO BE SET UP!!!

    #replace " by \" not to harm echo function
    $lower =~ s/"/\\"/g;
    my $tmp="echo \"". $lower. "\" | $moses_prog $moses_param";
    my $moses = `$tmp`;
    chomp($moses);
    warn "Problem during Moses' translation -- input:\"$lower\"; no output!\n"    if($moses eq "");
    print "ok\nrecase_preprocess ..." if $debug;


    #recasing preprocess
    my $recase_pre = recase_preprocess::remove_trace($moses);    
    warn "Problem during recase preprocessing -- input:\"$moses\"; no output!\n"    if($recase_pre eq "");
    print "ok\nrecasing ..." if $debug;


    #moses recaser - BE CAREFUL - USER SPECIFIC WAY OF CALLING OF MOSES HAS TO BE SET UP!!!

    #replace " by \" not to harm echo function
    $recase_pre =~ s/"/\\"/g;
    $tmp="echo \"".$recase_pre."\" | $recase_prog $recase_param";
    my $recase = `$tmp`;
    chomp($recase);
    warn "Problem during Moses' recasing -- input:\"$recase_pre\"; no output!\n"    if($recase eq "");
    print "ok\nrecase_postprocess ..." if $debug;

    my $recase_post = recase_postprocess::retrace($moses, $recase);
    warn "Problem during recase postprocess -- input:\"$moses\" and \"$recase\"; no output!\n"    if($recase_post eq "");
    print "ok\nreinsert ..." if $debug;


    #reinsert
    my @elements = reinsert::extract_inline($tok);
    my $reins  = reinsert::reinsert_elements($recase_post,@elements);
    warn "Problem during reinsertion -- input:\"$tok\" and \"$recase_post\"; no output!\n" if($reins eq "");
    print "ok\ndetokenization ..." if $debug;


    #detokenization
    my $detok = $detokenizer->processLine($reins);
    warn "Problem during detokenization -- input:\"$reins\"; no output!\n"    if($detok eq "");
    print "ok\nfix_whitespaces ..." if $debug;

    #fix whitespaces around tags
    my $fix = fix_markup_ws::fix_whitespace($source, $detok);
    warn "Problem during white spaces fixation -- input:\"$source\" and \"$detok\"; no output!\n"    if($fix eq "");
    print "ok\n" if $debug;


   print TMPOUT "$fix\n";
}

print "\nfile $tmpin ...done\n\n\n";
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




