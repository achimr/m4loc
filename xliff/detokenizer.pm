#!/usr/bin/perl -w

package detokenizer;

__PACKAGE__->run(@ARGV) unless caller();

# $Id: detokenizer.perl 3880 2011-02-14 13:35:04Z bojar $
# Sample De-Tokenizer
# written by Josh Schroeder, based on code by Philipp Koehn
# further modifications by Ondrej Bojar


# converted into modulino by Achim Ruopp
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
use utf8; # tell perl this script file is in UTF-8 (see all funny punct below)
use Getopt::Std;
use I18N::LangTags qw(is_language_tag super_languages);

sub run() {
    binmode(STDIN, ":utf8");
    binmode(STDOUT, ":utf8");
    # This added by Herve Saint-Amand for compatibility with translate.cgi
    # Always flush buffers
    $|++;

    my %opts;
    getopts("ul:",\%opts);
    my $language = $opts{l} ? $opts{l} : "en";
    my $uppersent = $opts{u} ? 1 : 0;

    if(!is_language_tag($language)) {
	die "Invalid language id: $language";
    }
    my @superlangs = super_languages($language);
    if(@superlangs) {
	$language = pop @superlangs;
    }

    if ($language !~ /^(cs|en|fr|it)$/) {
	warn "No built-in rules for language $language, detokenizer falling back to English.\n";
	$language = "en";
    }

    while(<STDIN>) {
	chomp;
	if (/^<.+>$/ || /^\s*$/) {
		#don't try to detokenize XML/HTML tag lines
		print $_;
	}
	else {
		print &detokenize($language,$uppersent,$_);
	}
	print "\n";
    }
}


sub ucsecondarg {
  # uppercase the second argument
  my $arg1 = shift;
  my $arg2 = shift;
  return $arg1.uc($arg2);
}

sub detokenize {
	my $language = shift;
	my $UPPERCASE_SENT = shift;
	my($text) = @_;
	chomp($text);
	$text = " $text ";
        $text =~ s/ \@\-\@ /-/g;
	
	my $word;
	my $i;
	my @words = split(/ /,$text);
	$text = "";
	my %quoteCount =  ("\'"=>0,"\""=>0);
	my $prependSpace = " ";
	for ($i=0;$i<(scalar(@words));$i++) {		
		if ($words[$i] =~ /^[\p{IsSc}\(\[\{\¿\¡]+$/) {
			#perform right shift on currency and other random punctuation items
			$text = $text.$prependSpace.$words[$i];
			$prependSpace = "";
		} elsif ($words[$i] =~ /^[\,\.\?\!\:\;\\\%\}\]\)]+$/){
			#perform left shift on punctuation items
			$text=$text.$words[$i];
			$prependSpace = " ";
		} elsif (($language eq "en") && ($i>0) && ($words[$i] =~ /^[\'][\p{IsAlpha}]/) && ($words[$i-1] =~ /[\p{IsAlnum}]$/)) {
			#left-shift the contraction for English
			$text=$text.$words[$i];
			$prependSpace = " ";
		} elsif (($language eq "cs") && ($i>1) && ($words[$i-2] =~ /^[0-9]+$/) && ($words[$i-1] =~ /^[.,]$/) && ($words[$i] =~ /^[0-9]+$/)) {
			#left-shift floats in Czech
			$text=$text.$words[$i];
			$prependSpace = " ";
		}  elsif ((($language eq "fr") ||($language eq "it")) && ($i<(scalar(@words)-1)) && ($words[$i] =~ /[\p{IsAlpha}][\']$/) && ($words[$i+1] =~ /^[\p{IsAlpha}]/)) {
			#right-shift the contraction for French and Italian
			$text = $text.$prependSpace.$words[$i];
			$prependSpace = "";
		} elsif (($language eq "cs") && ($i<(scalar(@words)-3))
				&& ($words[$i] =~ /[\p{IsAlpha}]$/)
				&& ($words[$i+1] =~ /^[-–]$/)
				&& ($words[$i+2] =~ /^li$|^mail.*/i)
				) {
			#right-shift "-li" in Czech and a few Czech dashed words (e-mail)
			$text = $text.$prependSpace.$words[$i].$words[$i+1];
			$i++; # advance over the dash
			$prependSpace = "";
		} elsif ($words[$i] =~ /^[\'\"„“`]+$/) {
			#combine punctuation smartly
                        my $normalized_quo = $words[$i];
                        $normalized_quo = '"' if $words[$i] =~ /^[„“”]+$/;
                        $quoteCount{$normalized_quo} = 0
                                if !defined $quoteCount{$normalized_quo};
                        if ($language eq "cs" && $words[$i] eq "„") {
                          # this is always the starting quote in Czech
                          $quoteCount{$normalized_quo} = 0;
                        }
                        if ($language eq "cs" && $words[$i] eq "“") {
                          # this is usually the ending quote in Czech
                          $quoteCount{$normalized_quo} = 1;
                        }
			if (($quoteCount{$normalized_quo} % 2) eq 0) {
				if(($language eq "en") && ($words[$i] eq "'") && ($i > 0) && ($words[$i-1] =~ /[s]$/)) {
					#single quote for posesssives ending in s... "The Jones' house"
					#left shift
					$text=$text.$words[$i];
					$prependSpace = " ";
				} else {
					#right shift
					$text = $text.$prependSpace.$words[$i];
					$prependSpace = "";
					$quoteCount{$normalized_quo} ++;

				}
			} else {
				#left shift
				$text=$text.$words[$i];
				$prependSpace = " ";
				$quoteCount{$normalized_quo} ++;

			}
			
		} else {
			$text=$text.$prependSpace.$words[$i];
			$prependSpace = " ";
		}
	}
	
	# clean up spaces at head and tail of each line as well as any double-spacing
	$text =~ s/ +/ /g;
	$text =~ s/\n /\n/g;
	$text =~ s/ \n/\n/g;
	$text =~ s/^ //g;
	$text =~ s/ $//g;
	
        $text =~ s/^([[:punct:]\s]*)([[:alpha:]])/ucsecondarg($1, $2)/e if $UPPERCASE_SENT;

	return $text;
}

1;

__END__

=head1 NAME

detokenizer.pm: Detokenize sentences based on language-specific rules

=head1 USAGE

    perl detokenizer.pm [-l language_id][-u] < in > out

C<-l language_id>: RFC-3066 language tag. The currently supported languages are

=over

=item Czech (cs)

=item English (en)

=item French (fr)

=item Italian (it)

=back

C<-u>: uppercase the first word of the sentence. This is useful for truecase MT systems.

C<in>: sentence separated text file in UTF-8 encoding

C<out>: output file (written in UTF-8 encoding)

=head2 Language Fallback Rules

If C<language_id> is not specified the default is en (English).
If C<language_id> is a more specific language (e.g. en-US), the tokenizer will fall back to the super language (e.g. en). 
If the language is not supported or invalid, the script will fall back to using English rules for the tokenization. 

=head1 SYNOPSIS

    use detokenizer;

    print detokenizer::detokenize("en",1,"mister Jones , working fast , fixed the broken leg ."),"\n";

=head1 DESCRIPTION

This modulino can be used as a script or module. 
It allows to detokenize sentences based on language-specific rules. 

If a word is followed by a space and punctuation, the tokenizer usually removes the space. 

=head1 FUNCTIONS

=head2 detokenize($langid,$uppersent,$text)

This function detokenizes the text in C<$text>, which is expected to be a single sentence. 
The detokenization is done under language specific rules specified with C<$langid> (RFC-3066 language identifier). The language fallback rules explaine for script use above B<are not> applied for module use.
If C<$uppersent> is true, the first word will be uppercased as well (useful for the use with truecase models in MT).

=head1 CREDITS

Copyright (c) 2012 Josh Schroeder, Philipp Koehn, Ondrej Bojar, Achim Ruopp

This modulino is based on a detokenizer script written by Josh Schroeder, based on code by Philipp Koehn; further modifications by Ondrej Bojar
It was converted into a modulino by Achim Ruopp

