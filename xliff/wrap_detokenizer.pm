#!/usr/bin/perl -w

package wrap_detokenizer;

__PACKAGE__->run(@ARGV) unless caller();

#
# Script wrap_detokenizer.pm detokenizes data from Markup Reinserter; after
# this step, tikal -lm takes place. wrap_detokenizer is a part of M4Loc effort
# http://code.google.com/p/m4loc/. If default (Moses) detokenizer is used,
# detokenizer.perl and nonbreaking_prefixes direcory are 
# required by this script.
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
use 5.10.0;
use FindBin qw($Bin);
use Getopt::Long;
use IPC::Run qw(start pump finish timeout pumpable);
#use IPC::Cmd qw(can_run);
use Encode;

sub run {
    ref(my $class= shift) and die "Class name needed";
    $|++;


    # parameters for detokenizer
    my $detok_param_str = "-l en";
    my @detok_param;

    #program for detokenization. Default: detokenizer.perl
    my $detok_program = "detokenizer.perl";

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
        print "\t -t detokenizer - program; (default: -t \"detokenizer.perl\")\n";
        print "\t -p detokenizer' options (default -p \"-l en\")\n";
        print "\tinFile - tokenized InlineText file, output of reinsert.pm\n";
        print "\toutFile - InlineText file, input for Tikal (-lm option)\n";
        exit;
    }

    #convert detok_param_str into array
    @detok_param = split( / /, $detok_param_str ) if length $detok_param_str;


    my $pokus = $class->new($detok_program,@detok_param);


    my $line;

    #read and process STDIN
    while ( $line = <STDIN> ) {
        chomp($line);
        print STDOUT $pokus->processLine($line)."\n";
    }
}

sub new {
   ref(my $class= shift) and die "Class name needed";
   my $detok_program = shift;
   my @detok_param = @_;

   my ( $DETOK_IN, $DETOK_OUT , $DETOK_ERR, $DETOK);

    my %self = (
        detok         => $DETOK,
        detok_in      => $DETOK_IN,
        detok_out     => $DETOK_OUT,
        detok_err     => $DETOK_ERR,
        detok_program => $detok_program
    );

#create array of tok_program and tok_param to be processable by IPC::Run start()
my @cmd = split(" ",$detok_program);
push(@cmd, @detok_param);

$self{detok} = start \@cmd, '<', \$self{detok_in}, '1>pty>',
      \$self{detok_out}, '2>', \$self{detok_err}, debug => 0
      or die "Can't exec detokenizer program: $?;\n";

    #check if tokenizer's STDERR or STDOUT is empty
    if (( length($self{detok_err} ) != 0 )||(length($self{detok_out})!=0)) {
        warn "Problem :". $self{detok_err}. " in program \"". $self{detok_program} . "\"\n";
        $self{tok_err} = '';
    }

    #is external detokenizer fully functional?
    $self{detok_in} =  "try it\n";
eval{    
    pump $self{detok} while $self{detok_out} !~ /\n\z/;    
}; warn "Problem in pumping:$@\n" if($@);

    $self{detok_out} = '';
    #check for STDERR from the detokenizer
    if ( $self{detok_err} ne "" ) {
        warn "External detokenizer: \"".$self{detok_program}."\" fired error: ".$self{detok_err}."\n";
        $self{detok_err} = '';
    }

if(!pumpable($self{detok})){
    die "Detokenizer \"".$self{detok_program}."\" died ...\n\tExit...\n";
}
#end of "is external detokenizer fully functional?"


    bless \%self, $class;
    return \%self;
}

sub DESTROY {
    my $self = shift;

    finish( $self->{detok} ) or die "Program: " . $self->{detok_program} . " returned $? and died.";
}

sub processLine{
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

   my $output = $self->detok($line);
   return $output;
}

sub detok {
    my $self = shift;
    my $text = shift;

    $self->{detok_in} = $text . "\n";
    pump $self->{detok} while $self->{detok_out} !~ /\n\z/;    

    $text = $self->{detok_out};
    $self->{detok_out} = '';

    #check for STDERR from the detokenizer
    if ( length($self->{detok_err} ) > 0 ) {
        warn "Problem :". $self->{detok_err}. " in program \"". $self->{detok_program} . "\"\n";
        $self->{detok_err} = '';
    }

    #almost equivalent to chomp - however \r differs
    $text =~ s/\r?\n\z//;
    $text = decode( "utf-8", $text );
    return $text;

} 

1;


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
"detokenizer.perl" )

-p options for the selected tokenizer (default -p "-l en" - which means English 
language

=head3 PREREQUISITES
perl at least 5.10.0

Getopt::Long;

=head3 Author

Tomáš Hudík, thudik@moraviaworldwide.com


=head3 TODO:

1. strict testing (QA), since it is likely that more sophisticated approach will be required
(de-tokenization is problematic in Moses since only a few languages are
supported and it is difficult to add a support for another language)

2. IPC::Run is not giving warning if some name of external program is mistyped, or not started properly

