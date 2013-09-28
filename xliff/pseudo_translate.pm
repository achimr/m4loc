#!/usr/bin/perl -w
package pseudo_translate;

run() unless caller();

#
# Translation of text into pig-latin with Moses traces for debugging
# purposes; input and output are expected to be UTF-8 encoded 
#
# Copyright 2011,2012 Digital Silk Road
# Subroutine _translate_text_pig_latin: Copyright 2011 Herve Saint-Amand
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

use strict;
use Getopt::Std;
use List::Util qw(shuffle);

sub run {
    binmode(STDIN,":utf8");
    binmode(STDOUT,":utf8");

    my %opts;
    getopts("n:",\%opts);
    if(@ARGV != 0) {
	die "Usage: $0 [-n <max phrase length>] < <tokenized lowercased source file> > <pseudo translated output file>\n";
    }
    my $max_phrase_len = $opts{n}?$opts{n}:1;


    while(<>) {
	chomp;
	my @tokens = split;
	# Create array of start/end hashes with maximum length $phrase_len
	if(@tokens) {
	    print translate($max_phrase_len,@tokens);
	}
	# New line if there were tokens or not
	print "\n";

    }
}

sub translate {
    my $max_phrase_len = shift;
    my @tokens = @_;

    my $i = 0;
    my @phrase_index;
    my $pseudo = "";
    while($i <= $#tokens) {
	# Conditional needed because rand(0) is special cased as rand(1) according to documentation
	my $rand_pl = $max_phrase_len==1 ? 0 : int(rand($max_phrase_len));
	my $phrase_end = $i+$rand_pl < $#tokens ? $i+$rand_pl : $#tokens;
	push @phrase_index, {"s"=>$i,"e"=>$phrase_end};
	$i = $phrase_end+1;
    } 

    # Shuffle start/end array
    my @shuffled_phrases = shuffle(@phrase_index);

    # Output pig latin translations and traces
    foreach my $phrase (@shuffled_phrases) {
	$pseudo .= _translate_text_pig_latin(join(' ',@tokens[$phrase->{'s'}..$phrase->{'e'}]));
	$pseudo .= ' ';
	$pseudo .= '|'.$phrase->{'s'}.'-'.$phrase->{'e'}.'| ';
    }

    return $pseudo;
}

# This sub is used when you want to debug everything in this script except the
# actual translation. Translates to Pig Latin.
#
# This subroutine was written by Herve Saint-Amand
# and copied from translate.cgi in the Moses codebase
# insertion of fake traces removed

sub _translate_text_pig_latin {
    my ($text) = @_;

    $text =~ s/\b([bcdfhj-np-tv-z]+)([a-z]+)/
        ($1 eq ucfirst $1 ? ucfirst $2 : $2) .
        ($2 eq lc $2 ? lc $1 : $1) .
        'ay';
    /gei;

    return $text;
}

1;

__END__

=head1 NAME

pseudo_translate.pm: Pseudo-translation of text with trace output

=head1 DESCRIPTION

This script pseudo-translates text to L<pig latin|http://en.wikipedia.org/wiki/Pig_latin>. 
First it selects phrases up to length max_phrase_length (default: 1) from the source text. 
It then rearranges the phrases in random order and translates their content into pig latin.
The phrase selection and reordering information is output as traces which indicate the token 
indices in the original text: |start-end|. This is equivalent to the output of the
Moses SMT engine with the -t option specified. The pseudo translation script can therefore
be used as a standin for the engine for testing purposes.

The script does not handle upper- and lowercasing.

=head1 USAGE

    perl pseudo_translate.pm [-n max_phrase_length] < tokenized_lowercased_source_file > pseudo_translated_output_file

Input is expected to be UTF-8 encoded (without a leading byte-order mark U+FEFF) and 
output will be UTF-8 encoded as well. 

=head2 OPTIONS

=over

=item -n

Indicates the maximum phrase length for phrase selection from the source. Default is 1.

=back

=head2 EXPORT

=over

=item translate(max_phrase_len,token_array) 

Pseudo-translates tokens in C<token_array> into pig Latin with a longest phrase length of C<max_phrase_len>. Rearrages the phrases at random and includes the Moses trace information for the phrase reordering. Returns string.

=back
