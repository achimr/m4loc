#!/usr/bin/perl -w

package tokenizer;

__PACKAGE__->run(@ARGV) unless caller();

# tokenizer.pm
# Sample Tokenizer
# written by Josh Schroeder, based on code by Philipp Koehn
# converted into class by Achim Ruopp
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
use File::Basename;
use File::Spec qw(rel2abs);
use Getopt::Std;
use I18N::LangTags qw(is_language_tag super_languages);


# Class Methods
sub run {
    ref(my $class= shift) and die "Class name needed";

    binmode(STDIN,":utf8");
    binmode(STDOUT,":utf8");
    # Always flush buffers
    $|++;

    my %opts;
    getopts("al:",\%opts);
    my $langid = $opts{l} ? $opts{l} : "en";
    my $aggressive = $opts{a} ? 1 : 0;

    my $tok = $class->new($langid,$aggressive);
    while(<STDIN>) {
	chomp;
	print $tok->tokenize($_),"\n";
    }
}

sub new {
    ref(my $class= shift) and die "Class name needed";
    my $langid = shift;
    $langid = "en" unless defined $langid;
    if(!is_language_tag($langid)) {
	die "Invalid language id: $langid";
    }
    my @superlangs = super_languages($langid);
    if(@superlangs) {
	$langid = pop @superlangs;
    }
    my $aggressive = shift;
    $aggressive = 0 unless defined $aggressive;

    my %nonbr;
    
    # Use __FILE__ to determine library directory
    my ($myfile,$mydir) = fileparse(File::Spec->rel2abs(__FILE__));
    #print STDERR "Lang: ".$langid."\n";
    my $prefixfile = "$mydir/nonbreaking_prefixes/nonbreaking_prefix.$langid";
    
    #default back to English if we don't have a language-specific prefix file
    if (!(-e $prefixfile)) {
	    $prefixfile = "$mydir/nonbreaking_prefixes/nonbreaking_prefix.en";
	    die ("ERROR: No abbreviations files found in $mydir\n") unless (-e $prefixfile);
    }
    
    if (-e "$prefixfile") {
	    open(PREFIX, "<:utf8", "$prefixfile");
	    while (<PREFIX>) {
		    my $item = $_;
		    chomp($item);
		    if (($item) && (substr($item,0,1) ne "#")) {
			    if ($item =~ /(.*)[\s]+(\#NUMERIC_ONLY\#)/) {
				    $nonbr{$1} = 2;
			    } else {
				    $nonbr{$item} = 1;
			    }
		    }
	    }
	    close(PREFIX);
    }
    my $self = { LangID => $langid, Aggressive => $aggressive, Nonbreaking => \%nonbr };
    bless $self,$class;
    return $self;
}

# Object Methods
sub tokenize {
    my $self = shift;
    if(!ref $self) {
	return "Unnamed $self";
    }
    my $text = shift;

    if ($text =~ /^<.+>$/ || $text =~ /^\s*$/) {
	    #don't try to tokenize XML/HTML tag lines or empty lines
	    return $text;
    }

    chomp($text);
    $text = " $text ";
    
    # seperate out all "other" special characters
    $text =~ s/([^\p{IsAlnum}\s\.\'\`\,\-])/ $1 /g;
    
    # aggressive hyphen splitting
    if ($self->{Aggressive}) {
       $text =~ s/([\p{IsAlnum}])\-([\p{IsAlnum}])/$1 \@-\@ $2/g;
    }

    #multi-dots stay together
    $text =~ s/\.([\.]+)/ DOTMULTI$1/g;
    while($text =~ /DOTMULTI\./) {
	    $text =~ s/DOTMULTI\.([^\.])/DOTDOTMULTI $1/g;
	    $text =~ s/DOTMULTI\./DOTDOTMULTI/g;
    }

    # seperate out "," except if within numbers (5,300)
    $text =~ s/([^\p{IsN}])[,]([^\p{IsN}])/$1 , $2/g;
    # separate , pre and post number
    $text =~ s/([\p{IsN}])[,]([^\p{IsN}])/$1 , $2/g;
    $text =~ s/([^\p{IsN}])[,]([\p{IsN}])/$1 , $2/g;
	  
    # turn `into '
    $text =~ s/\`/\'/g;
    
    #turn '' into "
    $text =~ s/\'\'/ \" /g;

    if ($self->{LangID} eq "en") {
	    #split contractions right
	    $text =~ s/([^\p{IsAlpha}])[']([^\p{IsAlpha}])/$1 ' $2/g;
	    $text =~ s/([^\p{IsAlpha}\p{IsN}])[']([\p{IsAlpha}])/$1 ' $2/g;
	    $text =~ s/([\p{IsAlpha}])[']([^\p{IsAlpha}])/$1 ' $2/g;
	    $text =~ s/([\p{IsAlpha}])[']([\p{IsAlpha}])/$1 '$2/g;
	    #special case for "1990's"
	    $text =~ s/([\p{IsN}])[']([s])/$1 '$2/g;
    } elsif (($self->{LangID} eq "fr") or ($self->{LangID} eq "it")) {
	    #split contractions left	
	    $text =~ s/([^\p{IsAlpha}])[']([^\p{IsAlpha}])/$1 ' $2/g;
	    $text =~ s/([^\p{IsAlpha}])[']([\p{IsAlpha}])/$1 ' $2/g;
	    $text =~ s/([\p{IsAlpha}])[']([^\p{IsAlpha}])/$1 ' $2/g;
	    $text =~ s/([\p{IsAlpha}])[']([\p{IsAlpha}])/$1' $2/g;
    } else {
	    $text =~ s/\'/ \' /g;
    }
    
    #word token method
    my @words = split(/\s/,$text);
    $text = "";
    for (my $i=0;$i<(scalar(@words));$i++) {
	    my $word = $words[$i];
	    if ( $word =~ /^(\S+)\.$/) {
		    my $pre = $1;
		    if (($pre =~ /\./ && $pre =~ /\p{IsAlpha}/) || ($self->{Nonbreaking}{$pre} && $self->{Nonbreaking}{$pre}==1) || ($i<scalar(@words)-1 && ($words[$i+1] =~ /^[\p{IsLower}]/))) {
			    #no change
		    } elsif (($self->{Nonbreaking}{$pre} && $self->{Nonbreaking}{$pre}==2) && ($i<scalar(@words)-1 && ($words[$i+1] =~ /^[0-9]+/))) {
			    #no change
		    } else {
			    $word = $pre." .";
		    }
	    }
	    $text .= $word." ";
    }		

    # clean up extraneous spaces
    $text =~ s/ +/ /g;
    $text =~ s/^ //g;
    $text =~ s/ $//g;

    #restore multi-dots
    while($text =~ /DOTDOTMULTI/) {
	    $text =~ s/DOTDOTMULTI/DOTMULTI./g;
    }
    $text =~ s/DOTMULTI/./g;
    
    return $text;
}

1;

__END__

=head1 NAME

tokenizer.pm: Tokenize sentences based on language-specific rules

=head1 USAGE

    perl tokenizer.pm [-l language_id][-a] < in > out

C<-l language_id>: RFC-3066 language tag. The currently supported languages are

=over

=item Catalan (ca)

=item Dutch (nl)

=item English (en)

=item French (fr)

=item German (de)

=item Greek (el)

=item Icelandic (is)

=item Italian (it)

=item Polish (pl)

=item Portuguese (pt)

=item Romanian (ro)

=item Russian (ru)

=item Slovak (sk)

=item Slovene (sl)

=item Spanish (es)

=item Swedish (sv)

=back

C<-a>: agressive tokenization

C<in>: sentence separated text file in UTF-8 encoding

C<out>: output file (written in UTF-8 encoding)

=head1 SYNOPSIS

    use tokenizer;

    my $tok = tokenizer->new("en-US",0);
    print $tok->tokenize("Dr. Jones, working fast, fixed the broken leg."),"\n";

=head1 DESCRIPTION

This modulino can be used as a script or module. It allows to tokenize sentences based on language-specific rules. The language-specific rules are stored in non-breaking prefix files.

If a word is immediately followed by punctuation, the tokenizer usually separates the two with a space. If the word preceeding the period is a nonbreaking prefix, this space is not inserted.

=head2 Nonbreaking Prefixes Files

Nonbreaking prefixes are loosely defined as any word ending in a period that indicates an abbreviation. A basic example is Mr. and Ms. in English.

The tokenizer uses the nonbreaking prefix files included in the nonbreaking_prefixes folder.

To add a file for other languages, follow the naming convention nonbreaking_prefix.?? and use the two-letter language code you intend to use when creating a tokenizer object.

The tokenizer will first look for a file for the language it is processing, and fall back to English if a file for that language is not found. 

A modifier for prefixes, #NUMERIC_ONLY#, can be added separated by a space for special cases where the prefix should be handled ONLY when before numbers.
For example, "Article No. 24 states this." the No. is a nonbreaking prefix. However, in "No. It is not true." No functions as a word.

See the example prefix files included in the nonbreaking_prefixes folder for more examples.

=head2 Language Fallback Rules

If C<language_id> is not specified the default is en (English).
If C<language_id> is a more specific language (e.g. en-US), the tokenizer will fall back to the super language (e.g. en). 
If the language is not supported, the script will fall back to using English rules for the tokenization. 
If C<language_id> is invalid, the script will fail.

=head1 FUNCTIONS

=head2 new($langid,$agressive)

Creates new tokenizer object with the language specified by C<$langid> (RFC-3066 language identifier expected, same language fallback rules as described above). More agressive tokenization can be specified with the boolean parameter C<$agressive>.

=head2 tokenize($text)

Member function of tokenizer object to tokenize text in C<$text>) parameter, which is expected to be a single sentence. The function returns the tokenized text.

=head1 CREDITS

Copyright (c) 2012 Josh Schroeder, Philipp Koehn, Achim Ruopp, Bas Rozema, HilE<aacute>rio Leal Fontes,  JesE<uacute>s GimE<eacute>nez 

The modulino is based on the tokenizer script in Moses written by Josh Schroeder, based on code by Philipp Koehn.
It was converted into a modulino by Achim Ruopp

Thanks for the following individuals for supplying nonbreaking prefix files:
Bas Rozema (Dutch), HilE<aacute>rio Leal Fontes (Portuguese), JesE<uacute>s GimE<eacute>nez (Catalan & Spanish)

