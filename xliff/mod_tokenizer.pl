#!/usr/bin/perl -w

#
# Script mod_tokenizer.pl tokenizes text in InlineText format; this data format is
# tikal -xm output (Okapi Framework) output. mod_tokenizer is a part of M4Loc effort
# http://code.google.com/p/m4loc/. The output is tokenized/segmented InlineText
# that doesn't have tokenized InlineText tags and url addresses - high level
# technical specification can be found at: http://code.google.com/p/m4loc/ ,
# click on "Specifications" and select "ModTokenizer - Technical Specification".
# Moses' tokenizer.perl and nonbreaking_prefixes direcory are required by the script.
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

#use at least version 5.10 (or higher, due to ~~ operator)
use 5.10.0;
use strict;
use File::Temp;
use XML::LibXML::Reader;
use FindBin qw($Bin);

#GLOBAL VARIABLES

#language can be specified by user, otherwise is used en as default. It is used in
#tokenizer.perl script (part of Moses SW package)
my $language = "en";

#string to be tokenized by tokenizer.perl
my $str_tok = "";

#string with xml tags (which won't be tokenized)
my $str_tag = "";

#output string - it is a combination(merger) of $str_tok and $str_tag
my $str_out = "";

#array of allowed InlineText tags. Only these are allowed, any other will cause a warning
my @InlineTexttags = qw/g x bx ex/;

#for QA (testing) only; if it is needed to analyze tmp file (before tokenizer.perl)
#set up to 1, otherwise 0
my $deletetmp = 1;

my $mydir = "$Bin/nonbreaking_prefixes";

my %NONBREAKING_PREFIX = ();

#my $QUIET = 0;
#my $HELP = 0;
#my $AGGRESSIVE = 0;

#tmp string
my $tmp;

#print out help info if some incorrect options has been inserted
my $HELP = 0;

#END OF GLOBAL VARIABLES

#MAIN PROGRAM

while (@ARGV) {
    $_ = shift;
    /^-l$/ && ( $language = shift, next );
    /^(?!-l$)/ && ( $HELP = 1, next );
}

if ($HELP) {
    print "\nmod_tokenizer.pl converts InlineText into tokenized InlineText.\n";
    print "\nUSAGE: ./mod_tokenizer (-l [de|en|...]) < inFile > outFile\n";
    print "\t -l language for tokenization/segmentation\n";
    print "\tinFile - InlinText file, output of Okapi Tikal (parameter -xm)\n";
    print "\toutFile - tokenized InlineText file, input for markup_remover\n";
    exit;
}

#create tmp file for storing encapsulated inLineText data (output of tikal -xm)
my $tmpout  = File::Temp->new( DIR => '.', TEMPLATE => "tempXXXXX", UNLINK => $deletetmp );
my $tmpout2 = File::Temp->new( DIR => '.', TEMPLATE => "tempXXXXX", UNLINK => $deletetmp );

#for some OS it can be good to uncomment these lines.
#New versions of linux are OK with only STDOUT specified as utf8
#binmode( $tmpout, ":utf8" );
#binmode( STDIN,   ":utf8" );
binmode( STDOUT, ":utf8" );

#add XML init string to document to be processible by xml parser (XML::LibXML Reader)
print( $tmpout "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<InlineText xml:space=\"preserve\">" );

#read and store STDIN into the temporary file
my $line;
while ( $line = <STDIN> ) {
    chomp($line);

    #extra whitespace and new line added (white space - solve URL\n case; URL \n
    #is OK, however URL\n would cause leave one line out)
    print( $tmpout $line . " \n" );
}
print( $tmpout "</InlineText>" );
close($tmpout);

#loading nonbreaking_prefixes
load_prefixes( $language, \%NONBREAKING_PREFIX );

if ( scalar(%NONBREAKING_PREFIX) eq 0 ) {
    print STDERR "Warning: No known abbreviations for language '$language'\n";
}

#for QA purposes only
#my $f;
#open($f,$tmpout->filename);
#while(my $ll=<$f>){
#   print $ll;
#}
#close($f);
#print "\n----------------------------------------------------------------------\n";
#end

#open and process the tmp file with LibXML::Reader
my $reader = new XML::LibXML::Reader( location => $tmpout->filename )
  or die "Error: cannot read temp file: $tmpout->filename\n";

#read XML nodes
while ( $reader->read ) {
    processNode($reader);
}

#tokenize remaining str_tok if any
if ( length($str_tok) > 0 ) {
    $str_out .= " " . tokenize($str_tok);
    $str_tok = "";
}

#write down output
print $tmpout2 $str_out;
$str_out = "";

close $tmpout2;

#clean extra spaces and substitute special characters ([,],|;<> are solved already) that can't be given as Moses input. 
#The output print into STDOUT
open($tmpout2);
while (<$tmpout2>) {
    my $line = $_;
    chomp($line);

    $line =~ s/ +/ /g;
    $line =~ s/^ //;
    $line =~ s/ $//;
    $line =~ s/\[/&#x5b;/g;
    $line =~ s/\]/&#x5d;/g;
    $line =~ s/\|/&#x7c;/g;

    print STDOUT $line . "\n";
}
close $tmpout2;

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
        if ( !( $reader->name ~~ @InlineTexttags ) ) {
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
        my @arr = split( /((http[s]?:\/\/|ftp[s]?:\/\/|www\.)\S*)/i, $lin );
        for ( my $i = 0 ; $i <= $#arr ; $i++ ) {

            #insert not-tokenized URL
            if ( $i % 2 ) { $tokenized .= " $arr[$i] "; }
            else {

                #badly created XLIFFes can contain hidden XML tags(e.g. &lt;...) - don't tokenize them
                my @btag = split( /(&\w+;\S*)/i, $arr[$i] );
                for ( my $j = 0 ; $j <= $#btag ; $j++ ) {

                    #insert not-tokenized btag
                    if ( $j % 2 ) {
                        $tokenized .= " $btag[$j] ";
                        print STDERR "WARNING: incorrectly created original XLIFF. String: \"$btag[$j]\" should be wrapped in special tags.\n";
                    }
                    else {

                        #insert tokenized rest of the line
                        $tokenized .= tokenize_str( $btag[$j] );
                        chomp($tokenized);
                    }
                }
            }
        }
        $tokenized .= "\n";
    }

    #if the input ($str) doesn't end with \n (problem between lines and xlm tags) then chomp
    if ( $str !~ /\n$/ ) { chomp($tokenized); }

    return $tokenized;
}

#tokenize string (taken from Moses' tokenizer.perl - function tokenize)
sub tokenize_str {
    my ($text) = @_;
    chomp($text);
    $text = " $text ";

    # seperate out all "other" special characters
    $text =~ s/([^\p{IsAlnum}\s\.\'\`\,\-])/ $1 /g;

    #multi-dots stay together
    $text =~ s/\.([\.]+)/ DOTMULTI$1/g;
    while ( $text =~ /DOTMULTI\./ ) {
        $text =~ s/DOTMULTI\.([^\.])/DOTDOTMULTI $1/g;
        $text =~ s/DOTMULTI\./DOTDOTMULTI/g;
    }

    # seperate out "," except if within numbers (5,300)
    $text =~ s/([^\p{IsN}])[,]([^\p{IsN}])/$1 , $2/g;

    # separate , pre and post number
    $text =~ s/([\p{IsN}])[,]([^\p{IsN}])/$1 , $2/g;
    $text =~ s/([^\p{IsN}])[,]([\p{IsN}])/$1 , $2/g;

    # turn `into '
    $text =~ s/\`/\'/g;

    #turn '' into "
    $text =~ s/\'\'/ \" /g;

    if ( $language eq "en" ) {

        #split contractions right
        $text =~ s/([^\p{IsAlpha}])[']([^\p{IsAlpha}])/$1 ' $2/g;
        $text =~ s/([^\p{IsAlpha}\p{IsN}])[']([\p{IsAlpha}])/$1 ' $2/g;
        $text =~ s/([\p{IsAlpha}])[']([^\p{IsAlpha}])/$1 ' $2/g;
        $text =~ s/([\p{IsAlpha}])[']([\p{IsAlpha}])/$1 '$2/g;

        #special case for "1990's"
        $text =~ s/([\p{IsN}])[']([s])/$1 '$2/g;
    }
    elsif ( ( $language eq "fr" ) or ( $language eq "it" ) ) {

        #split contractions left
        $text =~ s/([^\p{IsAlpha}])[']([^\p{IsAlpha}])/$1 ' $2/g;
        $text =~ s/([^\p{IsAlpha}])[']([\p{IsAlpha}])/$1 ' $2/g;
        $text =~ s/([\p{IsAlpha}])[']([^\p{IsAlpha}])/$1 ' $2/g;
        $text =~ s/([\p{IsAlpha}])[']([\p{IsAlpha}])/$1' $2/g;
    }
    else {
        $text =~ s/\'/ \' /g;
    }

    #word token method
    my @words = split( /\s/, $text );
    $text = "";
    for ( my $i = 0 ; $i < ( scalar(@words) ) ; $i++ ) {
        my $word = $words[$i];
        if ( $word =~ /^(\S+)\.$/ ) {
            my $pre = $1;
            if ( ( $pre =~ /\./ && $pre =~ /\p{IsAlpha}/ ) || ( $NONBREAKING_PREFIX{$pre} && $NONBREAKING_PREFIX{$pre} == 1 ) || ( $i < scalar(@words) - 1 && ( $words[ $i + 1 ] =~ /^[\p{IsLower}]/ ) ) ) {

                #no change
            }
            elsif ( ( $NONBREAKING_PREFIX{$pre} && $NONBREAKING_PREFIX{$pre} == 2 ) && ( $i < scalar(@words) - 1 && ( $words[ $i + 1 ] =~ /^[0-9]+/ ) ) ) {

                #no change
            }
            else {
                $word = $pre . " .";
            }
        }
        $text .= $word . " ";
    }

    # clean up extraneous spaces
    $text =~ s/ +/ /g;
    $text =~ s/^ //g;
    $text =~ s/ $//g;

    #restore multi-dots
    while ( $text =~ /DOTDOTMULTI/ ) {
        $text =~ s/DOTDOTMULTI/DOTMULTI./g;
    }
    $text =~ s/DOTMULTI/./g;

    #ensure final line break
    $text .= "\n" unless $text =~ /\n$/;

    return $text;
}

#taken from Moses' tokenizer.perl
sub load_prefixes {
    my ( $language, $PREFIX_REF ) = @_;

    my $prefixfile = "$mydir/nonbreaking_prefix.$language";

    #default back to English if we don't have a language-specific prefix file
    if ( !( -e $prefixfile ) ) {
        $prefixfile = "$mydir/nonbreaking_prefix.en";
        print STDERR "WARNING: No known abbreviations for language '$language', attempting fall-back to English version...\n";
        die("ERROR: No abbreviations files found in $mydir\n") unless ( -e $prefixfile );
    }

    if ( -e "$prefixfile" ) {
        open( PREFIX, "<:utf8", "$prefixfile" );
        while (<PREFIX>) {
            my $item = $_;
            chomp($item);
            if ( ($item) && ( substr( $item, 0, 1 ) ne "#" ) ) {
                if ( $item =~ /(.*)[\s]+(\#NUMERIC_ONLY\#)/ ) {
                    $PREFIX_REF->{$1} = 2;
                }
                else {
                    $PREFIX_REF->{$item} = 1;
                }
            }
        }
        close(PREFIX);
    }

}

__END__

=encoding utf8

=head1 mod_tokenizer.pl: tokenize InLineText text 

=head2 Description 

It tokenizes data in InlineText format; this data format is tikal -xm output (Okapi Framework). 
mod_tokenizer.pl is a part of M4Loc effort L<http://code.google.com/p/m4loc/>. The output is 
tokenized/segmented InlineText with untokenized XML/XLIFF tags and url addresses. High level 
technical specification can be found at: L<http://code.google.com/p/m4loc/wiki/TableOfContents?tm=6> , 
click on "Specifications" and select "ModTokenizer - Technical Specification". For lower level 
specification, check the code, it is well-documented and sometimes written in
self-documenting  style :).

The script takes data from standard input, process it and the output is written to the standard 
output. Input and output are UTF-8 encoded data. 


=head3 USAGE

C<< perl mod_tokenizer.pl (-l [en|de|...]) < inFile > outFile >>


where B<inFile> contains InlineText data (Okapi Framework, tikal -xm) and B<outFile> 
is tokenized, UTF-8 encoded file ready to processed by Markup remover (M4Loc). Workflow:
L<http://bit.ly/gOms1Y>

The tokenization process is language specific. The option B<-l> specifies the
language. The script and the subdirectory nonbreaking_prefixes has to be put in
the same directory, since the script is using languge specific tokenization rules stored 
in nonbreaking_prefixes sub-directory.

=head3 PREREQUISITES

XML::LibXML::Reader

=head3 Author

Tomáš Hudík, thudik@moraviaworldwide.com


=head3 TODO:

1. add - if str_out is too long - print it to file

