#!/usr/bin/perl -w

package wrap_detokenizer;

__PACKAGE__->run(@ARGV) unless caller();

#
# Script wrap_detokenizer.pl detokenizes data from Markup Reinserter; after
# this step, tikal -lm takes place. wrap_detokenizer is a part of M4Loc effort
# http://code.google.com/p/m4loc/. Moses' detokenizer.perl and
# nonbreaking_prefixes direcory are required by the script.
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
use 5.10.0;
use File::Temp;
use FindBin qw($Bin);
use Getopt::Long;

sub run {
    ref(my $class= shift) and die "Class name needed";
    $|++;


    #tmp parameters for detokenizer
    my $detok_param_str = "-l en -q";

    #program for detokenization. Default: Moses' tokenizer.perl
    my $detok_program = "$Bin/./detokenizer.perl";

    #print out help info if some incorrect options has been inserted
    my $HELP = 0;

    # !!!Be carefull: important for line-based approach, however, it is causing
    # useless delays in file-based (batch) approach
    autoflush STDIN;

    #binmode(STDIN,":utf8");
    binmode( STDOUT, ":utf8" );
    binmode( STDERR, ":utf8" );

    my $opt_status = GetOptions(
        't=s'   => \$detok_program,
        'p=s'   => \$detok_param_str,
        'help!' => \$HELP,
    );

    if ( ( !$opt_status ) || ($HELP) ) {
        print "\n$0 converts tokenized InlineText into InlineText.\n";
        print "\nUSAGE: perl $0 [-t -p] < inFile > outFile\n";
        print "\t -p detokenizer' options (default -p \"-l en -q\")\n";
        print "\t -t detokenizer - program; (default: -t \"perl detokenizer.perl\")\n";
        print "\tinFile - tokenized InlineText file, output of reinsert.pm\n";
        print "\toutFile - InlineText file, input for Tikal (-lm option)\n";
        exit;
    }


    my $pokus = $class->new($detok_program,$detok_param_str);


    my $line;

    #read and process STDIN
    while ( $line = <STDIN> ) {
        chomp($line);
        $pokus->process_line($line);
    }

    close($pokus->{tmpout});

    print $pokus->detok();
}

sub new {
   ref(my $class= shift) and die "Class name needed";
   my $detok_program = shift;
   my $detok_param_str = shift;

  die "$class\->new(program, parameters); detokenizer program and parameters have to be specified!" 
    unless defined($detok_program) and defined($detok_param_str);


     #defining pipe(IPC::Run) for the external tokenizer
#    our ( $DETOK_IN, $DETOK_OUT, $DETOK_ERR, $DETOK );


   #create tmp file for storing encapsulated inLineText data (output of tikal -xm)
    my $tmpout = File::Temp->new( DIR => '.', TEMPLATE => "tempXXXXX", UNLINK => "0" );

    my $self = {detok_program => $detok_program, detok_param_str => $detok_param_str, tmpout => $tmpout};
    bless $self, $class;
    return $self;
}

sub DESTROY{
    my $self = shift;
   unlink($self->{tmpout});
}

sub process_line{
    my $self = shift;
    my $line = shift;

	#insert space before < tag if is not already
        if ( $line =~ /\S\<(?!\/)/ ) {
            $line =~ s/(\S)\<(?!\/)/$1 \</g;
        }

        #remove space after closing tag /> if there is some
        if ( $line =~ /(\/\>|\<\/)\s+\S/ ) {
            $line =~ s/(\/\>|\<\/)\s+/$1/g;
        }

        #remove space after closing tag </ ..> if there is some
        if ( $line =~ /(\<\/(\w+|\s+))\>\s+/ ) {
            $line =~ s/(\<\/(\w+|\s+))\>\s+/$1\>/g;
        }

        #put back Moses' sensitive characters
        $line =~ s/&#x5b;/\[/g;
        $line =~ s/&#x5d;/\]/g;
        $line =~ s/&#x7c;/\|/g;
        $line =~ s/&amp;/&/g;

   print {$self->{tmpout} } $line;
}

sub detok{
    my $self = shift;

    #if tokenizer is Moses' default, it can work only with a few languages!!!
    my $lang;
    ($lang) = ($self->{detok_param_str} =~ /\-l (\S+)/p);
    if (($self->{detok_program} =~ /detokenizer\.perl/)&&( $lang !~ /(en|cs|fr|it)/ )) {


       print STDERR "WARNING: Moses detokenizer can work only with en, cs, fr and it languages, not with $lang\n";
    }

#  system("perl $self->{detok_program} $self->{detok_param_str} < $self->{tmpout}");
return `perl $self->{detok_program} $self->{detok_param_str} < $self->{tmpout}`;

} 

__END__

=encoding utf8

=head1 wrap_detokenizer.pm: detokenize InLineText format

=head2 Description 

It detokenizes data back to InlineText; this data is ready for tikal -lm input (Okapi Framework). 
wrap_detokenizer.pm is a part of M4Loc effort L<http://code.google.com/p/m4loc/>. The output is 
detokenized text with proper XML/XLIFF tags. For lower level specification, check the code.

The script takes data from standard input, process it and the output is written to the standard 
output. Input and output are UTF-8 encoded data. 


=head3 USAGE

C<< perl wrap_detokenizer.pm [-t -p ] < inFile 1> outFile 2>errFile >>


where B<inFile> contains  data from Markup Reinserter (M4Loc) and B<outFile> 
is ready to be processed by tikal -lm process (Okapi framework). Workflow:
L<http://bit.ly/gOms1Y>

-t specify an path to and external detokenizer itself (default -t
"./tokenizer.perl" )

-p options for the selected tokenizer (default -p "-q -l en" - which means quiet
run and English language"

=head3 PREREQUISITES
perl at least 5.10.0

Getopt::Long;

=head3 Author

TomE<aacute>E<scaron> HudE<iacute>k, thudik@moraviaworldwide.com


=head3 TODO:

1. strict testing (QA), since it is likely that more sophisticated approach will be required
(de-tokenization is problematic in Moses since only a few languages are
supported and it is difficult to add a support for another language)

