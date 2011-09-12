#!/usr/bin/perl -w
$|++;

#
# Script wrap_tokenizer.pl takes input (line - STDIN, or file) split it into
# chunks. Chunks can be a plain text or special inlines (tags), URL adresses,... which 
# should not be translated. The input needs to be in so-called InlineText format; this 
# data format can be obtained from tikal -xm (Okapi Framework) output. wrap_tokenizer 
# is a part of M4Loc effort http://code.google.com/p/m4loc/. 
# The output is tokenized/segmented InlineText.
# Note: If Moses' tokenizer.perl is chosen as the tokenizer (default) make sure that 
# tokenizer.perl as well as nonbreaking_prefixes direcory are included in the
# same directory as wrap_tokenizer.pl. 
#
#
#
# © 2011 Moravia a.s. (DBA Moravia WorldWide),
# Tomáš Hudík thudik@moraviaworldwide.com
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

use warnings;
use strict;
#use at least version 5.10 (or higher, due to ~~ operator)
use 5.10.0;
use XML::LibXML::Reader;
use FindBin qw($Bin);
use IPC::Run qw(start pump finish timeout);
use Encode;
use utf8;

# !!!Be carefull: important for line-based approach, however, it is causing
# useless delays in file-based (batch) approach
autoflush STDIN;
#binmode(STDIN,":utf8");
binmode(STDOUT,":utf8");
binmode(STDERR,":utf8");


#GLOBAL VARIABLES

my @tok_param = qw/ -l en -q/;

#program for tokenization. Default: Moses' tokenizer.perl
my $tok_program = "$Bin/./tokenizer.perl"; 

#string to be tokenized by tokenizer.perl
my $str_tok = "";

#string with xml tags (which won't be tokenized)
my $str_tag = "";

#output string - it is a combination(merger) of $str_tok and $str_tag
my $str_out = "";

my $tmp;

#print out help info if some incorrect options has been inserted
my $HELP = 0;

#END OF GLOBAL VARIABLES

#MAIN PROGRAM
my $tok_param_str="";

while (@ARGV) {
    $_ = shift;
    /^-p$/ && ( $tok_param_str = shift, next );
    /^-t$/ && ( $tok_program = shift, next );

    /^(?!-l$)/ && ( $HELP = 1, next );
}

if ($HELP) {
    print "\nwrap_tokenizer.pl converts InlineText into tokenized InlineText.\n";
    print "\nUSAGE: ./wrap_tokenizer [-t -p] < inFile > outFile\n";
    print "\t -p tokenizer' options (default -p \"-l en -q\"\n";
    print "\t -t tokenizer - program; (default: -t \"perl tokenizer.perl\")\n";
    print "\tinFile - InlinText file, output of Okapi Tikal (parameter -xm)\n";
    print "\toutFile - tokenized InlineText file, input for markup_remover\n";
    exit;
}

#convert tok_param_str into array
@tok_param = split(/ /, $tok_param_str) if length $tok_param_str;


#defining pipe(IPC::Run) for the external tokenizer
my ($TOK_IN, $TOK_OUT, $TOK_ERR);

my $TOK = start [$tok_program, @tok_param], '<', \$TOK_IN,'1>pty>',\$TOK_OUT, '2>', \$TOK_ERR, debug=>0 or die "Can't exec tokenizer program: $?;\n"; 


my $line;
while ( $line = <STDIN> ) {
    $str_out = "";
    chomp($line);

    my $inline_xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<InlineText xml:space=\"preserve\">";
    #extra whitespace and new line added (white space - solve URL\n case; URL \n
    #is OK, however URL\n would cause leave one line out)
    $inline_xml .= $line . " \n</InlineText>";
    
    #process $inline_xml(now is valid xml documnet) with LibXML::Reader
    my $reader = new XML::LibXML::Reader( string => $inline_xml );
    
    #read XML nodes
    while ( eval{$reader->read} ) {
        # AR bad: this subroutine modifies the global $str_out
        processNode($reader);
    }

    if($@) {
	warn $line,"\n",$@;
	print "-1\n";
	next;
    }

    
    #tokenize remaining str_tok if any
    if ( length($str_tok) > 0 ) {
        $str_out .= " " . tokenize($str_tok);
        $str_tok = "";
    }
    
    #clean extra spaces and substitute special characters ([,],|;<> are solved already) that can't be given as Moses input. 
    my $line = $str_out;
    chomp($line);

    $line =~ s/\s+/ /g;
    $line =~ s/^ //;
    $line =~ s/ $//;
    $line =~ s/\[/&#x5b;/g;
    $line =~ s/\]/&#x5d;/g;
    $line =~ s/\|/&#x7c;/g;
    #this is still open question whether character '&' should be represented as  '&amp;' or '&' 
    $line =~ s/\&amp;/\&/g;

  print STDOUT $line,"\n";
}

finish($TOK) or die "$tok_program returned $?";

#END OF MAIN PROGRAM

#FUNCTIONS---------------------------------------------------------------------------------------------

#XML's nodes proccessing
sub processNode {
    my $reader = shift;

    #don't process top element (xliff_inLines)
    if ( $reader->name eq "InlineText" ) {
        return;
    }

    #if a node is a string -- add content to str_tok
    if ( $reader->name eq "#text" ) {
        my $node = $reader->preserveNode();
        $str_tok .= $node->toString();    #$reader->value;
    }

    #if node is a start of some element
    if ( $reader->nodeType == 1 ) {
        $str_tag .= "<" . $reader->name;

        #read and add attributes, if any
        if ( $reader->moveToFirstAttribute ) {
            do {
                {
                    $str_tag .= " " . $reader->name() . "=\"" . $reader->value . "\"";
                }
            } while ( $reader->moveToNextAttribute );
            $reader->moveToElement;
        }

        #if str_tok is not empty,tokenize and put it to the output string
        if ( length($str_tok) > 0 ) {
            $str_out .= " " . tokenize($str_tok) . " ";
            $str_tok = "";
        }

        #if is empty node (e.g. <a/>) add closing bracket and return
        #there is no string for tokenization (str_tok should be empty)
        if ( $reader->isEmptyElement ) {
            $str_out .= $str_tag . "/>";
            $str_tag = "";
            return;
        }

        #check whether the tag is correct InlineText tag
	if ( $reader->name !~ /(g|x|bx|ex|lb|mrk)/  ) {
            print STDERR "Warning: input has not valid InlineText format!!\n" . "Problematic tag: <" . $reader->name . ">\nContinue...\n";
        }

        #add starting tag
        $str_out .= $str_tag . ">";
        $str_tag = "";
    }

    #if node is an end of some element
    if ( $reader->nodeType == 15 ) {

        #tokenize str_tok if any
        if ( length($str_tok) > 0 ) {

            #add it to the output string
            $str_out .= " " . tokenize($str_tok) . " ";
            $str_tok = "";
        }

        #add closing element tag
        $str_out .= "</" . $reader->name . ">";
    }

}

#tokenize $str_tok and write it to $str_out (do not tokenize URL addresses)
sub tokenize {
    my $str       = shift;
    my $tokenized = "";

    #split input into lines, since tokenize_str can treat lines only
    my @lines = split( /\n/, $str );
    foreach my $lin (@lines) {

        #check whether string contains some URL patterns
        my @arr = split( /((http[s]?:\/\/|ftp[s]?:\/\/|www\.)\S+)/i, $lin );
	#necessary to employ special variable which is $i+1$, since it is needed to remove every third item, (e.g. 3,6), from regexp 
	#with $i staring from 0 would be difficult
	my $iter = 1;
        for ( my $i = 0 ; $i <= $#arr ; $i++ ) {
            #if second item in the regexp => insert not-tokenized URL
            if ( ($iter % 3) == 2) { $tokenized .= " $arr[$i] "; }
	    #if first item in the regexp => 
            if ( ($iter % 3) == 1) {

                #badly created XLIFFes can contain hidden XML tags(e.g. &lt;...)
		#don't tokenize these hidden XML tags (choose them from string and put to $tokenized untokenized)
                my @btag = split( /(&\w{2,4};)/i, $arr[$i] );
                for ( my $j = 0 ; $j <= $#btag ; $j++ ) {

		#treating UNICODE numbers
		$btag[$j] =~ s/(&amp;)( )(\#\w+;)/$1$3/g;
		$btag[$j] =~ s/(&amp;)( )(\#x\w+;)/$1$3/g;

                    #insert not-tokenized btag
                    if ( $j % 2 ) {		
			#put space between the last hidden tag and the next standard character
			#$btag[$j] =~ s/(.*)(&\w+;)(.*)/$1$2 $3/g;
			$btag[$j] =~ s/(\w+;)(\w+)$/$1 $2/;
                        $tokenized .= " $btag[$j] ";
                        print STDERR "WARNING: incorrectly created original XLIFF. String: \"$btag[$j]\" should be wrapped in special tags.\n";
                    }
                    else {

                        #insert tokenized rest of the line
                        $tokenized .= tokenize_str( $btag[$j] );
                        #chomp($tokenized);
                    }
                }
            }
	    $iter++;
        }
        $tokenized .= "\n";
    }

    #if the input ($str) doesn't end with \n (problem between lines and xml tags) then chomp
    if ( $str !~ /\n$/ ) { chomp($tokenized); }

    return $tokenized;
}

#tokenize string (call external tokenizer and receive its output)
sub tokenize_str {
    my ($text) = @_;
    $TOK_IN = $text."\n";
    pump $TOK while $TOK_OUT !~ /\n\z/;

    $text = $TOK_OUT;
    $TOK_OUT = '';
    #check for STDERR from the tokenizer
    if(length($TOK_ERR)>0){
	print STDERR "$tok_program:$TOK_ERR\n";
	$TOK_ERR='';
    }
    #almost equivalent to chomp - however \r differs
    $text =~ s/\r?\n\z//;
    $text = decode("utf-8",$text);
    return $text;
}



__END__


=head1 wrap_tokenizer.pl: tokenizes InLineText 

=head2 Description 

wrap_tokenizer.pl is a part of M4Loc effort L<http://code.google.com/p/m4loc/>. 
It takes input (line, or file) in InlineText format ( this format is tikal
-xm output; tikal is part of Okapi Framework).  The output is
tokenized/segmented InlineText with untokenized XML/XLIFF tags and url addresses. 

wrap_tokenizer.pl is a wrapper for some external tokenizer. It splits out input into
different chunks. The chunks with plain text intended for translation are send
to an external tokenizer and then, wrap_tokenizer waits for the tokenized
chunks. The tokenized chunks are further joined with untokenized ones (special
Inlines, URL addresse, or poorly-created XLIFF
strings) and print out as STDOUT.

The script takes data from standard input, process it and the output is written
to the standard output. Input and output are UTF-8 encoded data. 

The functinality of wrap_tokenizer is the same as mod_tokenizer. The difference
is that mod_tokenizer is sticked exclusively to Moses' tokenizer.perl. However,
for some languages (mainly East-asian) is better to use different tokenizer,
which is not possible in mod_tokenizer. For more info on tokenizing and whole
framework of XLIFF<->Moses is described in:
http://www.mt-archive.info/EAMT-2011-Hudik.pdf



=head3 USAGE

C<< perl wrap_tokenizer.pl [-t -p ] < inFile 1> outFile 2>errFile >>


where B<inFile> contains InlineText data (Okapi Framework, tikal -xm) and B<outFile> 
is tokenized, UTF-8 encoded file ready to processed by Markup remover (M4Loc). Workflow:
L<http://bit.ly/gOms1Y>.

-t specify an path to and external tokenizer itself (default -t
"./tokenizer.perl" )

-p options for the selected tokenizer (default -p "-q -l en" - which means quiet
run and English language"

WARNING: external tokenizer needs to:

1. run in quiet mode (no additional info, just tokenized string)
2. be able to process and output UTF-8 data


=head3 PREREQUISITES
perl at least 5.10.0

XML::LibXML::Reader

IPC::Run

Encode

=head3 Author

Tomáš Hudík, thudik@moraviaworldwide.com


=head3 TODO:

1. add - if str_out is too long - print it to file

2. which XML entities (< is &lt;, & is &amp;,...) should be in "normal" form(<) and which should be encoded (&amp;)

