#!/usr/bin/perl -w

package m4loc_tag;
use m4loc;
our @ISA = qw(m4loc);

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

use File::Basename;
use File::Spec qw(rel2abs);
use IPC::Open2;
use wrap_tokenizer;
use wrap_detokenizer;
use wrap_markup;
use decode_markup;

# Class Methods - inherited

# Constructor 
# Cannot be inherited b/c Moses is started with different parameters
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

# Object Methods
sub translate {
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
