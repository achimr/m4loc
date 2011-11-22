#!/usr/bin/perl -w
package fix_markup_ws;
run() unless caller();

use strict;

# Copyright 2011 Digital Silk Road
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


sub run {
    binmode(STDIN,":utf8");
    binmode(STDOUT,":utf8");

    if(@ARGV != 1) {
	die "Usage: perl $0 source < detokenized_target > fixed_target\n";
    }
    
    open(my $sfh, "<:utf8", $ARGV[0]) or die "Source file could not be opened";
    while(<STDIN>) {
	chomp;
	if(my $sourceline = <$sfh>) {
	    chomp $sourceline;
	    print fix_whitespace($sourceline,$_),"\n";
	}
	else {
	    die "Source file and detokenized target file have differing number of lines";
	}
    }

    close($sfh);

    return 1;
}

sub fix_whitespace {
    my $source = shift;
    my $target = shift;

    # Parse whitespace around tags in source and target
    my @source_elements = extract_inline($source);
    my @target_elements = extract_inline($target);

    # Map source and target elements and correct whitespace
    map_elements(\@source_elements,\@target_elements);

    # Assemble fixed up target InlineText
    my $fixed = "";
    my $i = 0;
    my $inline_tags = "g|x|bx|ex|lb|mrk";
    my $remainder = $target;
    while($target =~ /\G(.*?)\s*<(\/?)($inline_tags)(?:\s+id="(\d+)")?(.*?)>\s*/g) {
	# $1: content, $2: closing slash, $3: tag type, $4: id, 
	# $5: remaining tag content
	if($2 ne '/') {
	    # isolated or opening paired tag
	    $fixed .= $1.$target_elements[$i]->{'opws'}.'<'.$3.' id="'.$4.'"'.$5.'>'.$target_elements[$i]->{'osws'};
	}
	else {
	    # closing tag
	    $fixed .= $1.$target_elements[$i]->{'cpws'}.'</'.$3.$5.'>'.$target_elements[$i]->{'csws'};
	}
	$i++;
	# $' only scoped to the block
	$remainder = $';
    }
    # Add remaining content to fixed target
    $fixed .= $remainder;

    # If multiple spaces come together, reduce them to one
    $fixed =~ s/\s\s+/ /g;

    return $fixed;

}

sub map_elements {
    my $sourceref = shift;
    my $targetref = shift;

    foreach my $targetelement (@{$targetref}) {
	foreach my $sourceelement (@{$sourceref}) {
	    if($targetelement->{'id'} == $sourceelement->{'id'}) {
		# Opening tag matching
		if(exists($targetelement->{'opws'}) && exists($sourceelement->{'opws'})) {
		    $targetelement->{'opws'} = $sourceelement->{'opws'};
		    $targetelement->{'osws'} = $sourceelement->{'osws'};
		    last;
		}
		# Closing tag matching
		if(exists($targetelement->{'cpws'}) && exists($sourceelement->{'cpws'})) {
		    $targetelement->{'cpws'} = $sourceelement->{'cpws'};
		    $targetelement->{'csws'} = $sourceelement->{'csws'};
		    last;
		}
	    }
	}
    }
}

sub extract_inline {
    my $inline = shift;
    my @elements;

    my $inline_tags = "g|x|bx|ex|lb|mrk";
    #print "\$inline = $inline\n";
    while($inline =~ /\G.*?(\s*)<(\/?)($inline_tags)(?:\s+id="(\d+)")?.*?>(\s*)/g) {
	# $1: preceeding spaces, $2: closing slash, $3: tag type, $4: id, $5: succeeding spaces
	# opening or isolated tags
	if($2 ne '/') {
	    my $id = "$3$4";
	    #$elements{"$3$4"} = { 'opws' => $1, 'osws' => $5 };
	    push @elements, {'type'=>$3,'id'=>$4,'opws' => $1,'osws' => $5};
	}
	# closing tags
	else {
	    # find the last corresponding opening tag in the list
	    for (my $j = $#elements; $j >= 0; $j--) {
		if($elements[$j]->{'type'} eq $3 && !exists($elements[$j]->{'ot'}) && !exists($elements[$j]->{'ct'}) ) {
		    push @elements, {'type'=>$3,'id'=>$elements[$j]->{'id'},'ot'=>$j,'cpws'=>$1,'csws'=>$5};
		    $elements[$j]->{'ct'} = $#elements;
		    last;
		}
	    }
	}
    }
    return @elements;
}

1;

