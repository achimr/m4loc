#!/usr/bin/perl -w

package m4loc;

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
use lib "$Bin";
use Getopt::Std;
use IPC::Open2;
use File::Basename;
use File::Spec qw(rel2abs);
use wrap_tokenizer;
use wrap_detokenizer;
use remove_markup;
use recase_preprocess;
use recase_postprocess;
use fix_markup_ws;
use reinsert;

# Class Methods
sub run {
    ref(my $class= shift) and die "Class name needed";

    # Always flush buffers
    $|++;
    binmode(STDIN,":utf8");
    binmode(STDOUT,":utf8");

    my %opts;
    getopts("s:l:k:d:m:r:",\%opts);

    if(@ARGV != 0) {
	die "Usage: perl $0 [-s source_language][-t target_language][-m moses_ini_file][-r recaser_ini_file][-k tokenizer_command][-d detokenizer_command] < source_file > target_file\n";
    }

    # Source language
    my $sl = $opts{s} ? $opts{s} : "fr";

    # Target language
    my $tl = $opts{t} ? $opts{t} : "en";

    # Tokenizer configuration
    my $tok_prog;
    my @tok_param;
    if(!$opts{k}) {
	$tok_prog = "$Bin/tokenizer.pm";
	@tok_param = ("-l",$sl);
    }
    else {
	my @tok_command = split(/ /,$opts{k});
	$tok_prog = shift @tok_command;
	@tok_param = @tok_command;
    }

    # Detokenizer program
    my $detok_prog;
    my @detok_param;
    if(!$opts{d}) {
	$detok_prog = "$Bin/detokenizer.pm";
	@detok_param = ("-l",$tl);
    }
    else {
	my @detok_command = split(/ /,$opts{d});
	$detok_prog = shift @detok_command;
	@detok_param = @detok_command;
    }

    # Moses configuration 
    my $moses_config = $opts{m} ? $opts{m} : "$Bin/moses.ini";

    # Recaser configuration file
    my $recaser_config = $opts{r} ? $opts{r} : "$Bin/recaser.ini";

    my $inlinetextmt = $class->new($sl,$tl,$moses_config,$recaser_config,$tok_prog,\@tok_param,$detok_prog,\@detok_param);
    while(my $source = <STDIN>){
	chomp $source;
	print $inlinetextmt->translate($source),"\n";
    }
}

# Constructor
sub new {
    ref(my $class= shift) and die "Class name needed";
    my $sourcelang = shift;
    my $targetlang = shift;
    my $moses_config = shift;
    my $recaser_config = shift;
    my $tok_prog = shift;
    my $tok_param_ref = shift;
    my $detok_prog = shift;
    my $detok_param_ref = shift;
    
    # New tokenizer and detokenizer objects
    # Use __FILE__ to determine library directory
    my ($myfile,$mydir) = fileparse(File::Spec->rel2abs(__FILE__));
    if(!$tok_prog) {
	$tok_prog = "$mydir/tokenizer.pm";
	$tok_param_ref = ['-l',$sourcelang];
    }
    if(!$detok_prog) {
	$detok_prog = "$mydir/detokenizer.pm";
	$detok_param_ref = ['-l',$targetlang];
    }
    my $tokenizer = wrap_tokenizer->new($tok_prog, @{$tok_param_ref});
    my $detokenizer = wrap_detokenizer->new($detok_prog, @{$detok_param_ref});

    # spawn moses and recaser
    my ($MOSES_IN, $MOSES_OUT);
    my $pid = open2 ($MOSES_OUT, $MOSES_IN, 'moses', '-f', $moses_config, '-t');
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
sub translate {
    my $self = shift;
    if(!ref $self) {
	return "Unnamed $self";
    }
    my $source = shift;

    #tokenization
    my $tok = $self->{Tokenizer}->processLine($source);
    my $rem = remove_markup::remove("",$tok);

    #lowercasing
    my $lower = lc($rem);

    #moses
    my $min = $self->{MosesIn};
    my $mout = $self->{MosesOut};
    print $min $lower,"\n";
    $min->flush();
    my $moses = scalar <$mout>;
    chomp $moses;

    #recasing pre-processing
    my $target_notrace = recase_preprocess::remove_trace($moses);

    #recasing
    my $rin = $self->{RecaseIn};
    my $rout = $self->{RecaseOut};
    print $rin $target_notrace,"\n";
    $rin->flush ();
    my $recase_target = scalar <$rout>;
    chomp $recase_target;

    #recasing post-processing
    my $target_tok = recase_postprocess::retrace($moses, $recase_target);

    #reinsert
    my @elements = reinsert::extract_inline($tok);
    my $reinserted  = reinsert::reinsert_elements($target_tok,@elements);

    #detokenization
    my $detok = $self->{Detokenizer}->processLine($reinserted);

    #fix whitespaces around tags
    my $fix = fix_markup_ws::fix_whitespace($source, $detok);

    return $fix;
}

1;
