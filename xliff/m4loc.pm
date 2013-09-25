#!/usr/bin/perl -w

package m4loc;

__PACKAGE__->run(@ARGV) unless caller();

#
# Modulino integrating tag-oriented processing of InlineText
#
# Copyright 2012-2013 Moravia Worldwide (xhudik@gmail.com), Digital Silk Road
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
use File::Temp qw(tempfile);
use wrap_tokenizer;
use wrap_detokenizer;
use remove_markup;
use recase_preprocess;
use recase_postprocess;
use wrap_markup;
use decode_markup;
use fix_markup_ws;
use reinsert;
use reinsert_greedy;
use reinsert_wordalign;

# Class Methods
sub run {
    ref(my $class= shift) and die "Class name needed";

    # Always flush buffers
    $|++;
    binmode(STDIN,":utf8");
    binmode(STDOUT,":utf8");

    my %opts;
    getopts("o:r:ens:t:k:d:m:c:",\%opts);

    if(@ARGV != 0) {
	die "Usage: perl $0 [-o p|w|t][-r recase_ini_file][-e][-n][-s source_language][-t target_language][-m moses_ini_file][-c truecase_ini_file][-k tokenizer_command][-d detokenizer_command] < source_file > target_file\n";
    }

    # Source language
    my $sl = $opts{s} ? $opts{s} : "fr";

    # Target language
    my $tl = $opts{t} ? $opts{t} : "en";

    # Tag handling mode determination
    my $tag_mode = "p";   # default tag handling mode is phrase-based
    if($opts{o}) {
	if($opts{o} =~ /[pwt]/) {
	    $tag_mode = $opts{o};
	}
	else {
	    die "Tag handling mode needs to be: phrase-based(p), word-based(w) or fixed tag(t)\n";
	}
    }

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
    my $no_detokenization = $opts{n} ? 1 : 0;

    # Moses configuration 
    my $moses_config = $opts{m} ? $opts{m} : "$Bin/moses.ini";

    # Casing configuration
    if($opts{c} && $opts{r}) {
	die "Cannot have both a truecaser (-c) and a recaser (-r).\n";
    }

    my $inlinetextmt = $class->new($sl,$tl,$moses_config,$opts{c},$tok_prog,\@tok_param,$detok_prog,\@detok_param,$opts{r},$opts{e},$tag_mode,$no_detokenization);
    while(my $source = <STDIN>){
	chomp $source;
	if($tag_mode eq "t") {
	    print $inlinetextmt->translate_tag($source),"\n";
	}
	elsif($tag_mode eq "w") {
	    print $inlinetextmt->translate_wordalign($source),"\n";
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
    my $true_caser_config = shift;
    my $tok_prog = shift;
    my $tok_param_ref = shift;
    my $detok_prog = shift;
    my $detok_param_ref = shift;
    my $recaser_config = shift;
    my $reinsert_greedy_mode = shift;
    my $tag_mode = shift;
    my $no_detokenization = shift;
    
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
    my ($alignfh,$alignfilename);
    if($tag_mode eq "t") {
	$pid = open2 ($MOSES_OUT, $MOSES_IN, 'moses', '-f', $moses_config, '-xml-input','exclusive');
    }
    elsif($tag_mode eq "w") {
	# TBD: Danger on larger files/web API use is that temp file could run out of space
	($alignfh,$alignfilename) = tempfile();
	$pid = open2 ($MOSES_OUT, $MOSES_IN, 'moses', '-f', $moses_config,'-print-alignment-info-in-n-best','-alignment-output-file',$alignfilename);
    }
    else { 
	$pid = open2 ($MOSES_OUT, $MOSES_IN, 'moses', '-f', $moses_config, '-t');
    }
    binmode($MOSES_IN,":utf8");
    binmode($MOSES_OUT,":utf8");

    my ($CASE_IN, $CASE_OUT);
    my ($TRUECASE_IN, $TRUECASE_OUT);
    my $pid6;
    my $pidtruecase;
    if($true_caser_config) {
	# truecase.perl in Moses v1.0 does not support -b|unbuffered option yet
	# $pid6 = open2 ($CASE_OUT, $CASE_IN, 'truecase.perl','--b','--model',$true_caser_config);
	$pidtruecase = open2 ($TRUECASE_OUT, $TRUECASE_IN, 'truecase.perl','--model',$true_caser_config);
	binmode($TRUECASE_IN,":utf8");
	binmode($TRUECASE_OUT,":utf8");
	$pid6 = open2 ($CASE_OUT, $CASE_IN, 'detruecase.perl');
    }
    elsif($recaser_config) {
	$pid6 = open2 ($CASE_OUT, $CASE_IN, 'moses','-v',0,'-f',$recaser_config,'-dl',0);
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
	TrueCaseIn => $TRUECASE_IN, 
	TrueCaseOut => $TRUECASE_OUT, 
	TrueCasePid => $pidtruecase,
	Tokenizer => $tokenizer, 
	Detokenizer => $detokenizer,
	TagMode => $tag_mode,
	ReinsertGreedyMode => $reinsert_greedy_mode,
	NoDetokenization => $no_detokenization,
	AlignFh => $alignfh,
	AlignFilename => $alignfilename
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

    if($self->{TrueCasePid}) {
	close $self->{TrueCaseIn};
	close $self->{TrueCaseOut};
	$exitpid = waitpid($self->{TrueCasePid},0);
	$childstatus = $? >> 8;
	if($childstatus) {
	    warn "Error in closing child caser process: $childstatus\n";
	}
    }

    if($self->{AlignFh}) {
	close($self->{AlignFh});
	unlink($self->{AlignFilename});
    }
}

# Object Methods
sub translate {
    my $self = shift;
    if(!ref $self) {
	return "Unnamed $self";
    }
    my $source = shift;
    my $contains_markup = ($source =~ /<.*>/);

    #tokenization
    my $tok = $self->{Tokenizer}->processLine($source);
    my $rem = $contains_markup ? remove_markup::remove("",$tok) : $tok;

    #lowercasing
    my $decoderinput;
    if($self->{TrueCasePid}) {
	my $tin = $self->{TrueCaseIn};
	my $tout = $self->{TrueCaseOut};
	print $tin $rem,"\n";
	$tin->flush ();
	$decoderinput = scalar <$tout>;
	chomp $decoderinput;
    }
    else {
	$decoderinput = lc($rem);
    }

    #moses
    my $min = $self->{MosesIn};
    my $mout = $self->{MosesOut};
    print $min $decoderinput,"\n";
    $min->flush();
    my $moses = scalar <$mout>;
    chomp $moses;

    #recasing pre-processing
    my $target;
    $target = recase_preprocess::remove_trace($moses);

    # Casing
    my $cin = $self->{CaseIn};
    my $cout = $self->{CaseOut};
    print $cin $target,"\n";
    $cin->flush ();
    my $case_target = scalar <$cout>;
    chomp $case_target;
    if(!$self->{TrueCasePid}) {
	my $recased_corrected = ucfirst($case_target);
	$case_target = $recased_corrected;
    }

    #recasing post-processing
    my $target_tok;
    if($contains_markup) {
	$target_tok = recase_postprocess::retrace($moses, $case_target);
    }
    else {
	$target_tok = $case_target;
    }

    #reinsert
    my $reinserted;
    my @elements;
    if($contains_markup) {
	if($self->{ReinsertGreedyMode}) {
	    @elements = reinsert_greedy::extract_inline($tok);
	    $reinserted  = reinsert_greedy::reinsert_elements($target_tok,@elements);
	}
	else {
	    @elements = reinsert::extract_inline($tok);
	    $reinserted  = reinsert::reinsert_elements($target_tok,@elements);
	}
    }
    else {
	$reinserted = $target_tok;
    }

    #detokenization
    if($self->{NoDetokenization}) {
	return $reinserted;
    }
    my $detok = $self->{Detokenizer}->processLine($reinserted);

    #fix whitespaces around tags
    my $fix = $contains_markup ? fix_markup_ws::fix_whitespace($source, $detok) : $detok;

    return $fix;
}

sub translate_wordalign {
    my $self = shift;
    if(!ref $self) {
	return "Unnamed $self";
    }
    my $source = shift;
    my $contains_markup = ($source =~ /<.*>/);

    #tokenization
    my $tok = $self->{Tokenizer}->processLine($source);
    my $rem = $contains_markup ? remove_markup::remove("",$tok) : $tok;

    #lowercasing
    my $decoderinput;
    if($self->{TrueCasePid}) {
	my $tin = $self->{TrueCaseIn};
	my $tout = $self->{TrueCaseOut};
	print $tin $rem,"\n";
	$tin->flush ();
	$decoderinput = scalar <$tout>;
	chomp $decoderinput;
    }
    else {
	$decoderinput = lc($rem);
    }

    #moses
    my $min = $self->{MosesIn};
    my $mout = $self->{MosesOut};
    print $min $decoderinput,"\n";
    $min->flush();
    my $moses = scalar <$mout>;
    chomp $moses;
    # Read alignment from alignment file
    my $alignfh = $self->{AlignFh};
    my $alignment = <$alignfh>;
    chomp $alignment;

    # Casing
    my $cin = $self->{CaseIn};
    my $cout = $self->{CaseOut};
    print $cin $moses,"\n";
    $cin->flush ();
    my $case_target = scalar <$cout>;
    chomp $case_target;
    if(!$self->{TrueCasePid}) {
	my $recased_corrected = ucfirst($case_target);
	$case_target = $recased_corrected;
    }

    #reinsert
    my $reinserted;
    if($contains_markup) {
	my @elements = reinsert_wordalign::extract_inline($tok);
	my @alignment = reinsert_wordalign::extract_wordalign($alignment);
	$reinserted = reinsert_wordalign::reinsert_elements($case_target,\@elements,\@alignment);
    }
    else {
	$reinserted = $case_target;
    }

    #detokenization
    if($self->{NoDetokenization}) {
	return $reinserted;
    }
    my $detok = $self->{Detokenizer}->processLine($reinserted);

    #fix whitespaces around tags
    my $fix = $contains_markup ? fix_markup_ws::fix_whitespace($source, $detok) : $detok;

    return $fix;
}

sub translate_tag {
    my $self = shift;
    if(!ref $self) {
	return "Unnamed $self";
    }
    my $source = shift;
    my $contains_markup = ($source =~ /<.*>/);

    #tokenization
    my $tok = $self->{Tokenizer}->processLine($source);

    # Wrap markup in Moses-specific XML
    my $wrapped_source = $contains_markup ? wrap_markup::wrap_markup($tok) : $tok;

    #lowercasing
    my $decoderinput;
    if($self->{TrueCasePid}) {
	my $tin = $self->{TrueCaseIn};
	my $tout = $self->{TrueCaseOut};
	print $tin $wrapped_source,"\n";
	$tin->flush ();
	$decoderinput = scalar <$tout>;
	chomp $decoderinput;
    }
    else {
	$decoderinput = lc($wrapped_source);
    }

    #moses
    my $min = $self->{MosesIn};
    my $mout = $self->{MosesOut};
    print $min $decoderinput,"\n";
    $min->flush();
    my $moses = scalar <$mout>;
    chomp $moses;

    # Decode XML entities
    my $decoded_target = $contains_markup ? decode_markup::decode_markup($moses) : $moses;

    # Casing
    my $cin = $self->{CaseIn};
    my $cout = $self->{CaseOut};
    print $cin $decoded_target,"\n";
    $cin->flush ();
    my $case_target = scalar <$cout>;
    chomp $case_target;
    if(!$self->{TrueCasePid}) {
	my $recased_corrected = ucfirst($case_target);
	$case_target = $recased_corrected;
    }

    #detokenization
    if($self->{NoDetokenization}) {
	return $case_target;
    }
    my $detok = $self->{Detokenizer}->processLine($case_target);

    #fix whitespaces around tags
    my $fix = $contains_markup ? fix_markup_ws::fix_whitespace($source, $detok) : $detok;

    return $fix;
}

1;
