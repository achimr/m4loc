#!/usr/bin/perl -w

package m4loc_tag;

__PACKAGE__->run(@ARGV) unless caller();

#
# Modulino integrating tag-oriented processing of InlineText
#
# Copyright 2012 Moravia Worldwide (xhudik@gmail.com), Digital Silk Road
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

use warnings;
use strict;

use FindBin qw($Bin);
use Getopt::Std;
use IPC::Open2;
use wrap_tokenizer;
use wrap_detokenizer;
use fix_markup_ws;
use wrap_markup;
use decode_markup;

# Class Methods
sub run {
    ref(my $class= shift) and die "Class name needed";

    # Always flush buffers
    $|++;
    binmode(STDIN,":utf8");
    binmode(STDOUT,":utf8");

    my %opts;
    getopts("s:l:k:d:m:r:",\%opts);

    # Source language
    my $sl = $opts{s} ? $opts{s} : "fr";

    # Target language
    my $tl = $opts{t} ? $opts{t} : "en";

    # Tokenizer configuration
    my $tok_prog = $opts{k} ? $opts{k} : "$Bin/tokenizer.pm";
    my @tok_param = ("-l",$sl);

    # Detokenizer program
    my $detok_prog = $opts{d} ? $opts{d} : "$Bin/detokenizer.pm";
    my @detok_param = ("-l",$tl);

    # Moses configuration 
    my $moses_config = $opts{m} ? $opts{m} : "$Bin/moses.ini";

    # Recaser configuration file
    my $recaser_config = $opts{r} ? $opts{r} : "$Bin/recaser.ini";

    my $inlinetextmt = $class->new($sl,$tl,$tok_prog,\@tok_param,$detok_prog,\@detok_param,$moses_config,$recaser_config);
    while(my $source = <STDIN>){
	chomp $source;
	print $inlinetextmt->translate_tag($source),"\n";
    }
}

# Constructor
sub new {
    ref(my $class= shift) and die "Class name needed";
    my $sourcelang = shift;
    my $targetlang = shift;
    my $tok_prog = shift;
    my $tok_param_ref = shift;
    my $detok_prog = shift;
    my $detok_param_ref = shift;
    my $moses_config = shift;
    my $recaser_config = shift;
    
    # New tokenizer and detokenizer objects
    my $tokenizer = wrap_tokenizer->new($tok_prog, @{$tok_param_ref});
    my $detokenizer = wrap_detokenizer->new($detok_prog, @{$detok_param_ref});

    # spawn moses and recaser
    my ($MOSES_IN, $MOSES_OUT);
    my $pid = open2 ($MOSES_OUT, $MOSES_IN, 'moses', '-f', $moses_config, '-xml-input','exclusive');
    binmode($MOSES_IN,":utf8");
    binmode($MOSES_OUT,":utf8");
    my ($RECASE_IN, $RECASE_OUT);
    my $pid6 = open2 ($RECASE_OUT, $RECASE_IN, 'moses','-v',0,'-f',$recaser_config,'-dl',0);
    binmode($RECASE_IN,":utf8");
    binmode($RECASE_OUT,":utf8");

    my $self = { 
	MosesIn => $MOSES_IN, 
	MosesOut => $MOSES_OUT, 
	MosesPid => $pid,
	RecaseIn => $RECASE_IN, 
	RecaseOut => $RECASE_OUT, 
	RecasePid => $pid6,
	Tokenizer => $tokenizer, 
	Detokenizer => $detokenizer 
    };
    bless $self,$class;
    return $self;
}

sub DESTROY {
    my $self = shift;

    close $self->{MosesIn};
    close $self->{MosesOut};
    my $exitpid = waitpid($self->{MosesPid},0);
    my $childstatus = $? >> 8;
    if($childstatus) {
	warn "Error in closing child Moses process: $childstatus\n";
    }
    close $self->{RecaseIn};
    close $self->{RecaseOut};
    $exitpid = waitpid($self->{RecasePid},0);
    $childstatus = $? >> 8;
    if($childstatus) {
	warn "Error in closing child recaser process: $childstatus\n";
    }
}

# Object Methods
sub translate_tag {
    my $self = shift;
    if(!ref $self) {
	return "Unnamed $self";
    }
    my $source = shift;

    #tokenization
    my $tok = $self->{Tokenizer}->processLine($source);

    # Wrap markup in Moses-specific XML
    my $wrapped_source = wrap_markup::wrap_markup($tok);

    #lowercasing
    my $lower = lc($wrapped_source);

    #moses
    my $min = $self->{MosesIn};
    my $mout = $self->{MosesOut};
    print $min $lower,"\n";
    $min->flush();
    my $moses = scalar <$mout>;
    chomp $moses;

    # Decode XML entities
    my $decoded_target = decode_markup::decode_markup($moses);

    #recasing
    my $rin = $self->{RecaseIn};
    my $rout = $self->{RecaseOut};
    print $rin $decoded_target,"\n";
    $rin->flush ();
    my $recase_target = scalar <$rout>;
    chomp $recase_target;

    #detokenization
    my $detok = $self->{Detokenizer}->processLine($recase_target);

    #fix whitespaces around tags
    my $fix = fix_markup_ws::fix_whitespace($source, $detok);

    return $fix;
}

1;
