#!/usr/bin/perl -w

package wrap_tokenizer;

__PACKAGE__->run(@ARGV) unless caller();

#
# Script wrap_tokenizer.pm takes input (line - STDIN, or file) split it into
# chunks. Chunks can be a plain text or special inlines (tags), URL adresses,... which
# should not be translated. The input needs to be in so-called InlineText format; this
# data format can be gained from tikal -xm (Okapi Framework) process. wrap_tokenizer
# is a part of M4Loc effort http://code.google.com/p/m4loc/.
# The output is tokenized/segmented InlineText.
# Note: If Moses' tokenizer.perl is chosen as the tokenizer (default) make sure that
# tokenizer.perl as well as nonbreaking_prefixes direcory are included in the
# same directory as wrap_tokenizer.pm.
#
#
#
# © 2012 Moravia a.s. (DBA Moravia WorldWide),
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
use IPC::Run qw(start pump finish timeout pumpable);
use Encode;
use Getopt::Long;

#use diagnostics;

sub run {
    ref( my $class = shift ) and die "Class name needed";

    $|++;

    #parameters for tokenizer
    my @tok_param;

    #tmp parameters for tokenizer
    my $tok_param_str = "-l en";

    #program for tokenization. Default: Moses' tokenizer.perl
    my $tok_program = "/opt/moses/scripts/tokenizer/tokenizer.perl";

    #print out help info if some incorrect options has been inserted
    my $HELP = 0;

    # !!!Be carefull: important for line-based approach, however, it is causing
    # useless delays in file-based (batch) approach
    autoflush STDIN;

    #binmode(STDIN,":utf8");
    binmode( STDOUT, ":utf8" );
    binmode( STDERR, ":utf8" );

    my $opt_status = GetOptions(
        't=s'   => \$tok_program,
        'p=s'   => \$tok_param_str,
        'help!' => \$HELP,
    );

    if ( ( !$opt_status ) || ($HELP) ) {
        print "\n$0 converts InlineText into tokenized InlineText.\n";
        print "\nUSAGE: perl $0 [-t -p] < inFile > outFile\n";
        print "\t -t tokenizer - program; (default: -t \"perl tokenizer.perl\")\n";
        print "\t -p tokenizer' options (default -p \"-l en -q\")\n";
        print "\tinFile - InlineText file, output of Okapi Tikal (parameter -xm)\n";
        print "\toutFile - tokenized InlineText file, input for markup_remover\n";
        exit;
    }

    #convert tok_param_str into array
    @tok_param = split( / /, $tok_param_str ) if length $tok_param_str;

    my $pokus = $class->new( $tok_program, @tok_param );

    my $line;
    while ( $line = <STDIN> ) {

        my $output = $pokus->processLine($line );
        print STDOUT "$output\n";
    }

}    #sub run

sub new {
    ref( my $class = shift ) and die "Class name needed";
    my $tok_program = shift;
    my @tok_param   = @_;

    #defining pipe(IPC::Run) for the external tokenizer
    my ( $TOK_IN, $TOK_OUT, $TOK_ERR, $TOK );

    my %self = (
        tok         => $TOK,
        tok_in      => $TOK_IN,
        tok_out     => $TOK_OUT,
        tok_err     => $TOK_ERR,
        tok_program => $tok_program
    );

#create array of tok_program and tok_param to be processable by IPC::Run start()
my @cmd = split(" ",$tok_program);
push(@cmd, @tok_param);

#    $self{tok} = start [ $tok_program, @tok_param ], '<', \$self{tok_in}, '1>pty>',
$self{tok} = start \@cmd, '<', \$self{tok_in}, '1>pty>',
      \$self{tok_out}, '2>', \$self{tok_err}, debug => 0
      or die "Can't exec tokenizer program: $?;\n";


    #check if tokenizer's STDERR or STDOUT is empty
    if (( length($self{tok_err} ) != 0 )||(length($self{tok_out})!=0)) {
        warn "Problem :". $self{tok_err}. " in program \"". $self{tok_program} . "\"\n";
        $self{tok_err} = '';
    }


#is external tokenizer fully functional?
    $self{tok_in} =  "try it\n";
eval{    
    pump $self{tok} while $self{tok_out} !~ /\n\z/;    
}; warn "Problem in pumping:$@\n" if($@);

    $self{tok_out} = '';
    #check for STDERR from the detokenizer
    if ( $self{tok_err} ne "" ) {
        warn "External tokenizer: \"".$self{tok_program}."\" fired error: ".$self{tok_err}."\n";
        $self{tok_err} = '';
    }

if(!pumpable($self{tok})){
    die "Tokenizer \"".$self{tok_program}."\" died ...\n\tExit...\n";
}
#end of "is external tokenizer fully functional?"


    bless \%self, $class;
    return \%self;

}

sub DESTROY {
    my $self = shift;
    finish( $self->{tok} ) or die "Program: " . $self->{tok_program} . " returned $? and died.";
}

sub processLine {
    my $self       = shift;
    my $line       = shift;
    chomp($line);
    my $inline_xml = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<InlineText
xml:space=\"preserve\">" . $line . " </InlineText>";

    #process $inline_xml(now is valid xml documnet) with LibXML::Reader
    my $reader = new XML::LibXML::Reader( string => $inline_xml );

    my $tmp = "";

    #read XML nodes
    while ( eval { $reader->read } ) {

        $tmp .= $self->processNode($reader );
    }

    if ($@) {
        warn $line, "\n", $@;
        print "-1\n";
        next;
    }

#clean extra spaces and substitute special characters ([,],|;<> ) that can't be given as Moses input.
    $line = $tmp;    #$m4loc::str_out;
    chomp($line);

    $line =~ s/\s+/ /g;
    $line =~ s/^ //;
    $line =~ s/ $//;
    $line =~ s/\[/&#x5b;/g;
    $line =~ s/\]/&#x5d;/g;
    $line =~ s/\|/&#x7c;/g;

#this is still open question whether character '&' should be represented as  '&amp;' or '&'
    $line =~ s/\&amp;/\&/g;
    return $line;
}

#XML's nodes proccessing
sub processNode {
    my $self = shift;
    my $reader = shift;

    # function result
    my $result = "";

    #temporal string which will undergo tokenize() (is not yet tokenized)
    my $tok = "";

    #temporal string which won't be tokenized (because it is tag, or parameter)
    my $tag = "";

    #don't process top element (InlineText)
    if ( $reader->name eq "InlineText" ) {
        return $result;
    }

    #if a node is a string -- add content to $tok
    if ( $reader->name eq "#text" ) {
        my $node = $reader->preserveNode();

        #!!NOTE: if: $tok .=#$reader->value; special strings are not treated correctly
        $tok .= $node->toString();

        #$tok .= $reader->value;
    }

    #if node is a start of some element
    if ( $reader->nodeType == 1 ) {
        $tag .= "<" . $reader->name;

        #read and add attributes, if any
        if ( $reader->moveToFirstAttribute ) {
            do {
                {
                    $tag .= " " . $reader->name() . "=\"" . $reader->value . "\"";

                }
            } while ( $reader->moveToNextAttribute );
            $reader->moveToElement;
        }

        #if tok is not empty,tokenize and put it to the output string
        if ( length($tok) > 0 ) {
            $result .= " " . $self->tokenize($tok) . " ";
            $tok = "";
        }

        #if is empty node (e.g. <a/>) add closing bracket and return
        #there is no string for tokenization ($tok should be empty)
        if ( $reader->isEmptyElement ) {
            $result .= $tag . "/>";
            $tag = "";
            return $result;
        }

        #check whether the tag is correct InlineText tag
        if ( $reader->name !~ /(g|x|bx|ex|lb|mrk|n)/ ) {
            warn "Warning: input is non-valid InlineText format!!\n"
              . "Problematic tag: <"
              . $reader->name
              . ">\nContinue...\n";
        }

        #add starting tag
        $result .= $tag . ">";
        $tag = "";
    }

    #if node is an end of some element
    if ( $reader->nodeType == 15 ) {

        #tokenize $tok if any
        if ( length($tok) > 0 ) {

            #add it to the output string
            $result .= " " . $self->tokenize($tok) . " ";
            $tok = "";
        }

        #add closing element tag
        $result .= "</" . $reader->name . ">";
    }

    if ( length($tok) > 0 ) {
        $result .= " " . $self->tokenize($tok) . " ";
    }

    return $result;

}    #processNode()

#tokenize $str and write it to $str_out (do not tokenize special strings
#specified by an user)
sub tokenize {
    my $self = shift;
    my $str       = shift;
    my $tokenized = "";

    #split input into lines, since tokenize_str can treat lines only
    my @lines = split( /\n/, $str );
    foreach my $lin (@lines) {

        ###############################################################
	######### INSERT DATASET SPECIFIC RULES HERE ##################
        #which strings should be replaced, or not tokenized
        #e.g. replace:  $lin =~ s/&lt;&gt;/<>/g;
	###############################################################


        #URLs  - do not tokenize URLs
        my (@url) = ( $lin =~ /((https?:\/\/|ftps?:\/\/|www\.)\S+)/gi );

        #replace
        $lin =~ s/(https?:\/\/|ftps?:\/\/|www\.)\S+/ \x{22D9} /gi;

        #ENT - do not tokenize XML entities
        my (@ent) = ( $lin =~ /&\w{2,4};/gi );

        #replace
        $lin =~ s/&\w{2,4};/ \x{29F2} /gi;

        ###############################################################
	#tokenization
        my $tmp_tok = $self->tokenize_str($lin );



	################################################################
        #after tokenization, replace non-terminals back to non-tokenized strings
        my $i;

        #URL - replace non-terminal back into non-tokenized strings
        for ( $i = 0 ; $i < ( $#url + 1 ) ; $i++ ) {

	#note: "unless" clause takes places due to necessity filter out the innner bracket in theregexp
            $tmp_tok =~ s/\x{22D9}/$url[$i]/i unless $i % 2;
        }

        #ENT - replace non-terminal back into non-tokenized strings
        for ( $i = 0 ; $i < ( $#ent + 1 ) ; $i++ ) {
            $tmp_tok =~ s/\x{29F2}/$ent[$i]/i;
        }


	################################################################
        ############ END OF DATASET" SPECIFIC RULES ####################
	################################################################

        $tokenized .= $tmp_tok;

        $tokenized .= "\n";
    }

  #if the input ($str) doesn't end with \n (problem between lines and xml tags) then chomp
    if ( $str !~ /\n$/ ) { chomp($tokenized); }

    return $tokenized;
}


#tokenize string (call external tokenizer and receive its output)
sub tokenize_str {
    my $self = shift;    
    my $text = shift;

    $self->{tok_in} = $text . "\n";
    pump $self->{tok} while $self->{tok_out} !~ /\n\z/;    

    $text = $self->{tok_out};
    $self->{tok_out} = '';

    #check for STDERR from the tokenizer
    if ( length($self->{tok_err} ) > 0 ) {
        warn "Problem :". $self->{tok_err}. " in program \"". $self->{tok_program} . "\"\n";
        $self->{tok_err} = '';
    }

    #almost equivalent to chomp - however \r differs
    $text =~ s/\r?\n\z//;
    $text = decode( "utf-8", $text );
    return $text;
}

1;
__END__


=head1 wrap_tokenizer.pm: tokenizes InLineText 

=head2 Description 

wrap_tokenizer.pm is a part of M4Loc effort L<http://code.google.com/p/m4loc/>. 
It takes input (line, or file) in InlineText format ( this format is tikal
-xm output; tikal is part of Okapi Framework).  The output is
tokenized/segmented InlineText with untokenized XML/XLIFF tags and url addresses. 

wrap_tokenizer.pm is a wrapper for some external tokenizer. It splits out input into
different chunks. The chunks with plain text intended for translation are sent
to an external tokenizer and then, wrap_tokenizer waits for the output (tokenized
chunks). If dataset contain some strings which shouldn't be tokenized, an user
can relatively seamlessly replace those strings into some non-terminal. Then,
tokenization takes place. And finally, non-terminals are converted back into
original form. For example, various URLs or special tags which are not
correctly processed by a CAT tool, can be a subject of such transformation (e.g.
URL->non_terminal->URL). Non-terminals are unicode characters which are not used
anywhere in the dataset. By default, URLs and XML entities are treated this way.
But many others can be added.

Inline text format (wrap_tokenizer's input) can consists of the following tags:
C<g,x,bx,ex,lb,mrk,n>. Where C<g,x,bx,ex,lb,mrk> are XLIFF inline elements and
C<n> can be used for being processed by Moses' -xml-input
(L<http://www.statmt.org/moses/?n=Moses.AdvancedFeatures#ntoc4>).

The script takes data from standard input, process it and the output is written
to the standard output. Input and output are UTF-8 encoded data. 

The functinality of wrap_tokenizer is the same as mod_tokenizer. The difference
is that mod_tokenizer is sticked exclusively to Moses' tokenizer.perl. However,
for some languages (mainly East-asian) is better to use different tokenizer,
which is not possible in mod_tokenizer. For more info on tokenizing and whole
framework of XLIFF<->Moses is described in:
L<http://www.mt-archive.info/EAMT-2011-Hudik.pdf>



=head3 USAGE

C<< perl wrap_tokenizer.pm [-t -p ] < inFile 1> outFile 2>errFile >>


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

3. rewrite script in order to avoid global variables

4. improve documentation
