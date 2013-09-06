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
# Untaint $Bin for use in REST API
BEGIN {
    if($Bin =~ /([\w\.:\/]+)/) {
	$Bin = $1;
    }
    else {
	die "Bad directory $Bin";
    }
}
use lib "$Bin";
use Getopt::Std;
use IPC::Open2;
use File::Spec qw(rel2abs);
use wrap_tokenizer;
use wrap_detokenizer;
use remove_markup;
use recase_preprocess;
use recase_postprocess;
use fix_markup_ws;
use reinsert;
use reinsert_greedy;

# Class Methods
sub run {
    ref(my $class= shift) and die "Class name needed";

    # Always flush buffers
    $|++;
    binmode(STDIN,":utf8");
    binmode(STDOUT,":utf8");

    my %opts;
    getopts("gres:l:k:d:m:c:",\%opts);

    if(@ARGV != 0) {
	die "Usage: perl $0 [-g][-r][-e][-s source_language][-t target_language][-m moses_ini_file][-c case_ini_file][-k tokenizer_command][-d detokenizer_command] < source_file > target_file\n";
    }

    # Source language
    my $sl = $opts{s} ? $opts{s} : "fr";

    # Target language
    my $tl = $opts{t} ? $opts{t} : "en";

    # Tokenizer configuration
    my $tok_prog;
    my @tok_param;
    if(!$opts{k}) {
	$tok_prog = "tokenizer.perl";
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
	$detok_prog = "detokenizer.perl";
	@detok_param = ("-l",$tl);
    }
    else {
	my @detok_command = split(/ /,$opts{d});
	$detok_prog = shift @detok_command;
	@detok_param = @detok_command;
    }

    # Moses configuration 
    my $moses_config = $opts{m} ? $opts{m} : "$Bin/moses.ini";

    # Casing configuration
    my $caser_config = $opts{c} ? $opts{c} : "$Bin/case.ini";

    my $inlinetextmt = $class->new($sl,$tl,$moses_config,$caser_config,$tok_prog,\@tok_param,$detok_prog,\@detok_param,$opts{g},$opts{r},$opts{e});
    while(my $source = <STDIN>){
	chomp $source;
	if($opts{g}) {
	    print $inlinetextmt->translate_tag($source),"\n";
	}
	else {
	    print $inlinetextmt->translate($source),"\n";
	}
    }
}

# Constructor
sub new {
    ref(my $class= shift) and die "Class name needed";
    my $sourcelang = shift;
    my $targetlang = shift;
    my $moses_config = shift;
    my $caser_config = shift;
    my $tok_prog = shift;
    my $tok_param_ref = shift;
    my $detok_prog = shift;
    my $detok_param_ref = shift;
    my $tag_mode = shift;
    my $recaser_mode = shift;
    my $reinsert_greedy_mode = shift;
    
    # New tokenizer and detokenizer objects
    if(!$tok_prog) {
	$tok_prog = "tokenizer.perl";
	$tok_param_ref = ['-l',$sourcelang];
    }
    if(!$detok_prog) {
	$detok_prog = "detokenizer.perl";
	$detok_param_ref = ['-l',$targetlang];
    }
    my $tokenizer = wrap_tokenizer->new($tok_prog, @{$tok_param_ref});
    my $detokenizer = wrap_detokenizer->new($detok_prog, @{$detok_param_ref});

    # spawn moses and caseing program
    my ($MOSES_IN, $MOSES_OUT);
    my $pid;
    if($tag_mode) {
	$pid = open2 ($MOSES_OUT, $MOSES_IN, 'moses', '-f', $moses_config, '-xml-input','exclusive');
    }
    else { 
	$pid = open2 ($MOSES_OUT, $MOSES_IN, 'moses', '-f', $moses_config, '-t');
    }
    binmode($MOSES_IN,":utf8");
    binmode($MOSES_OUT,":utf8");
    my ($CASE_IN, $CASE_OUT);
    my $pid6;
    if($recaser_mode) {
	$pid6 = open2 ($CASE_OUT, $CASE_IN, 'moses','-v',0,'-f',$caser_config,'-dl',0);
    }
    else {
	# truecase.perl in Moses v1.0 does not support -b|unbuffered option yet
	# $pid6 = open2 ($CASE_OUT, $CASE_IN, 'truecase.perl','--b','--model',$caser_config);
	$pid6 = open2 ($CASE_OUT, $CASE_IN, 'truecase.perl','--model',$caser_config);
    }
    binmode($CASE_IN,":utf8");
    binmode($CASE_OUT,":utf8");

    my $self = { 
	MosesIn => $MOSES_IN, 
	MosesOut => $MOSES_OUT, 
	MosesPid => $pid,
	CaseIn => $CASE_IN, 
	CaseOut => $CASE_OUT, 
	CasePid => $pid6,
	Tokenizer => $tokenizer, 
	Detokenizer => $detokenizer,
	TagMode => $tag_mode,
	RecaserMode => $recaser_mode,
	ReinsertGreedyMode => $reinsert_greedy_mode
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
    close $self->{CaseIn};
    close $self->{CaseOut};
    $exitpid = waitpid($self->{CasePid},0);
    $childstatus = $? >> 8;
    if($childstatus) {
	warn "Error in closing child caser process: $childstatus\n";
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
    my $target;
    if($self->{RecaserMode}) {
	$target = recase_preprocess::remove_trace($moses);
    }
    else {
	$target = $moses;
    }

    # Casing
    my $cin = $self->{CaseIn};
    my $cout = $self->{CaseOut};
    print $cin $target,"\n";
    $cin->flush ();
    my $case_target = scalar <$cout>;
    chomp $case_target;

    #recasing post-processing
    my $target_tok;
    if($self->{RecaserMode}) {
	$target_tok = recase_postprocess::retrace($moses, $case_target);
    }
    else {
	$target_tok = $case_target;
    }

    #reinsert
    my $reinserted;
    my @elements;
    if($self->{ReinsertGreedyMode}) {
	@elements = reinsert_greedy::extract_inline($tok);
	$reinserted  = reinsert_greedy::reinsert_elements($target_tok,@elements);
    }
    else {
	@elements = reinsert::extract_inline($tok);
	$reinserted  = reinsert::reinsert_elements($target_tok,@elements);
    }

    #detokenization
    my $detok = $self->{Detokenizer}->processLine($reinserted);

    #fix whitespaces around tags
    my $fix = fix_markup_ws::fix_whitespace($source, $detok);

    return $fix;
}

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

    # Casing
    my $cin = $self->{CaseIn};
    my $cout = $self->{CaseOut};
    print $cin $decoded_target,"\n";
    $cin->flush ();
    my $case_target = scalar <$cout>;
    chomp $case_target;

    #detokenization
    my $detok = $self->{Detokenizer}->processLine($case_target);

    #fix whitespaces around tags
    my $fix = fix_markup_ws::fix_whitespace($source, $detok);

    return $fix;
}

1;
