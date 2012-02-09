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

    if ($language !~ /^(cs|en|fr|it)$/) {
	die "No built-in rules for language $language, claim en for default behavior.\n";
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

