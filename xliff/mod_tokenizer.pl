#!/usr/bin/perl -w

#
# Script mod_tokenizer.pl tokenizes data from InlineText; this data format is
# tikal -xm output (Okapi Framework). mod_tokenizer is a part of M4Loc effort
# http://code.google.com/p/m4loc/. The output is tokenized/segmented text with
# not tokenized XML/XLIFF tags and url addresses - high level technical specification
# can be found at: http://code.google.com/p/m4loc/ ,click on "Specifications" and
# select "ModTokenizer - Technical Specification". Moses' tokenizer.perl and
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

#use at least version 5.10 (or higher, due to ~~ operator)
use 5.10.0;
use strict;
use File::Temp;
use XML::LibXML::Reader;
use Switch;

#GLOBAL VARIABLES

#array of placeholders. These XLIFF tags are treated differently than other XML tags. Textual
#strings inside placeholders are not tokenized instead of other XML tags
my @placeholders = qw/g sub mrk/;

#language can be specified by user, otherwise is used en as default. It is used in
#tokenizer.perl script (part of Moses SW package)
my $lang = "en";

#string to be tokenized by tokenizer.perl
my $str_tok = "";

#string with xml tags (which won't be tokenized)
my $str_tag = "";

#output string - it is a combination(merger) of $str_tok and $str_tag
my $str_out = "";

#tmp string
my $tmp;

#queue (array) of placeholder. It holds info  in which placeholder(s) the reader is embedded at
#some time. Can be zero, or more.
my @in_ph;

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
    print "\nmod_tokenizer.pl converts inLineText into pure tokenized text.\n";
    print "\nUSAGE: ./mod_tokenizer (-l [de|en|...]) < inFile > outFile\n";
    print "\t -l language for tokenization/segmentation (tokenizer.perl)\n";
    print "\tinFile - text file, textual output of Okapi Tikal (parameter -2tbl)\n";
    print "\toutFile - tokenized text file, possible input for Moses\n";
    exit;
}

#create tmp file for storing encapsulated inLineText data (output of tikal -xm)
my $tmpout = File::Temp->new( DIR => '.', TEMPLATE => "tempXXXXX", UNLINK => "1" );

#for some OS it can be good to uncomment these lines. New versions of linux are OK without them
#binmode( $tmpout, ":utf8" );
#binmode( STDIN,   ":utf8" );
#binmode( STDOUT,  ":utf8" );

#add XML init string to document to be processible by xml parser (XML::LibXML Reader)
print( $tmpout
      "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<xliff_inLines xml:space=\"preserve\">"
);

#read and store STDIN into the temporary file
my $line;
while ( $line = <STDIN> ) {
    chomp($line);
    print( $tmpout $line . "\n" );
}
print( $tmpout "</xliff_inLines>" );
close($tmpout);

#for QA purposes only
#my $f;
#open($f,$tmpout->filename);
#while(my $ll=<$f>){
#    print $ll;
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
print STDOUT $str_out;
$str_out = "";

#END OF MAIN PROGRAM

#FUNCTIONS---------------------------------------------------------------------------------------------

#XML's nodes proccessing
sub processNode {
    my $reader = shift;

    #don't process top element (xliff_inLines)
    if ( $reader->name eq "xliff_inLines" ) {
        return;
    }

    #if a node is a string
    if ( $reader->name eq "#text" ) {

      #if this text node is in some placeholder - assign it to str_tok (will be tokenized)
        if ( $#in_ph == -1 ) {
            $str_tok .= $reader->value;
        }

        #otherwise (if it belogs to a placeholder), add it to str_tag (won't be tokenized)
        else {
            $str_tag .= $reader->value;
        }
    }

    #if node is a start of some element
    if ( $reader->nodeType == 1 ) {
        $str_tag .= "<" . $reader->name;

        #read and add attributes if any
        if ( $reader->moveToFirstAttribute ) {
            do {
                {
                    $str_tag .= " " . $reader->name() . "=\"" . $reader->value . "\"";
                }
            } while ( $reader->moveToNextAttribute );
            $reader->moveToElement;
        }

        #tokenize and put it to the output string
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

        #if the opening tag is placeholder add its name to queue
        if ( $reader->name ~~ @placeholders ) {
            push( @in_ph, $reader->name );
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

        #if it was placeholder - add content and remove it from queue
        if ( $reader->name ~~ @placeholders ) {
            $str_out .= $str_tag;
            $str_tag = "";
            pop(@in_ph);
        }

        #add closing element tag
        $str_out .= "</" . $reader->name . ">";
    }

}

#tokenize $str_tok and write it to $str_out
sub tokenize {
    my $str       = shift;
    my $tokenized = "";

    #check whether string contains some URL patterns
    my @arr = split( /((http[s]?:\/\/|ftp[s]?:\/\/|www\.)\S*)/i, $str );
    for ( my $i = 0 ; $i <= $#arr ; $i++ ) {
        switch ( ( $i + 1 ) % 3 ) {
            case 0 {
            }    # do nothing; or create a better regexp and remove this useless case ;)
            case 1 {

                #substitute " for \",otherwise echo command would end up with fail
                #improve regexp to add \ whenever even number of \ is before " ???
                $arr[$i] =~ s/"/\\"/g;
                $tokenized .=
                  `echo -n "$arr[$i]" | ./tokenizer.perl -l $lang 2> /dev/null`;
                chomp($tokenized);

              #if $arr[$i] ends with a newline (\n), add one also at the end of $tokenized
                if ( $arr[$i] =~ /\n$/ ) {
                    $tokenized .= "\n";
                }
            }
            case 2 { $tokenized .= " $arr[$i] "; }
        }
    }
    return $tokenized;
}

__END__

=encoding utf8

=head1 mod_tokenizer.pl: tokenize InLineText text 

=head2 Description 

It tokenizes data from InlineText; this data format is tikal -xm output (Okapi Framework). 
mod_tokenizer.pl is a part of M4Loc effort L<http://code.google.com/p/m4loc/>. The output is 
tokenized/segmented text with untokenized XML/XLIFF tags, url addresses  and placeholders are 
treated in a special way. High level technical specification can be found at: 
L<http://code.google.com/p/m4loc/wiki/TableOfContents?tm=6> , click on "Specifications" and 
select "ModTokenizer - Technical Specification". For lower level specification, check the code,
it is well-documented and sometimes written in self-documenting  style.

The script takes data from standard input, process it and the output is written to the standard 
output. Input and output are UTF-8 encoded data. 


=head3 USAGE

C<< perl mod_tokenizer.pl (-l [en|de|...]) < inFile > outFile >>


where B<inFile> contains InLineText data (Okapi Framework, tikal -xm) and B<outFile> 
is tokenized, UTF-8 encoded file ready to processed by Markup Remover (M4Loc). Workflow:
L<http://bit.ly/gOms1Y>

The tokenization process is language specific. The option B<-l> specifies the language. The script has to be put in
the same directory as Moses' tokenizer.perl is, since the script is using tokenizer.perl and languge specific
tokenization rules written in nonbreaking_prefixes sub-directory.

=head3 PREREQUISITES

XML::LibXML::Reader

=head3 Author

Tomáš Hudík, thudik@moraviaworldwide.com


=head3 TODO:

1. follow examples from the Technical Specification - 1. example (C<FE<lt>x equiv-text=''/E<gt>ile>) 
is still missing. It is tricky since C<equive-text> is optional and can point to a hotkey (a word 
is divided by the tag) but to line, or page break, as well (the tag between 2 different words without
any whitespace). Probably it will be solved in XLIFF 2.0

2. add - if str_out is too long - print it to file

3. speed up by copying tokenizer.perl inside mod_tokenizer.pl

4. function tokenize - improve regexp to add \ whenever even number of \ is before " . Would be usefull? 
Can I expect input like: hello \\"World\\" - would it be covered by tikal?

