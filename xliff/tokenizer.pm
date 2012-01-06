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


# Class Methods
sub run {
    ref(my $class= shift) and die "Class name needed";

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
    if($langid !~ /^[a-z][a-z]$/) {
	die "Invalid language id: $langid";
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
