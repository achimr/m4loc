#!/usr/bin/perl 
#===============================================================================
#
#         FILE: resinsert_wordalign_test.pl
#
#        USAGE: ./reinsert_wordalign_test.pl  
#
#  DESCRIPTION: This is a simple test for reinsert_wordalign.pm module.
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Tomas Fulajtar 
# ORGANIZATION: Moravia a.s.
#      VERSION: 1.0
#      CREATED: 11/27/2013 09:58:25 AM
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use Data::Dumper;

use reinsert_wordalign;

use Test::Simple tests => 12;


test_extract1();
test_g1();
test_g2();
test_x1();
test_x2();
test_complex();
test_complex2();
test_empty_x_reorder();
test_nested_g_tags();

sub test_extract1 {
	my @wordalign = reinsert_wordalign::extract_wordalign("0-0 1-2");

	ok($wordalign[0]->{start} eq 0);
	ok($wordalign[0]->{end} eq 0);
	ok($wordalign[1]->{start} eq 2);
	ok($wordalign[1]->{end} eq 2);
}

sub test_g1 {
	my $src = '<g> Contact Management </g>';
	my $MT = 'Administración de contacto';
	my $align = '0-0 1-2';
	my $expected = '<g> Administración de contacto </g>';

	reinsert_ok($src, $expected, $MT, $align,"two words inside g tag");
}

sub test_g2 {
	my $src = '<g> Contact Management </g>';
	my $MT = 'kontaktverwaltung';
	my $align = '0-0 1-0';
	my $expected = '<g> kontaktverwaltung </g>';

	reinsert_ok($src, $expected, $MT, $align,"One word inside <g> tag");
}

sub test_x1 {
	my $src = '<x id="1"/> Search <x id="2"/>';
	my $MT = "Hledat";
	my $align = '0-0';
	my $expected = '<x id="1"/> Hledat <x id="2"/>';

	reinsert_ok($src, $expected, $MT, $align,"single word surrounded by <x> tags");
} 

sub test_x2 {
	my $src = '<x id="1"/> Search word <x id="2"/>';
	my $MT = "Hledat slovo";
	my $align = '0-0 1-1';
	my $expected = '<x id="1"/> Hledat slovo <x id="2"/>';

	reinsert_ok($src, $expected, $MT, $align,"two words surrounded by <x> tags");
}


sub test_complex {
	my $src = 'Click the search icon <g id="1"> </g> to expand the drop-down list';

	my $MT = 'Click das symbol suchen , erweitern sie die dropdownliste';
	my $align = '0-0 1-1 2-3 3-2 4-4 5-5 5-6 6-7 7-8 8-8';
	my $expected = 'Click das symbol suchen <g id="1"> </g> , erweitern sie die dropdownliste';
	reinsert_ok($src, $expected, $MT, $align," The empty <g> tag inside longer sentence with reordering");
}

sub test_complex2 {
	my $src = 'Tap the <g id="1"> Tablet PC Input Panel </g> icon on the taskbar .';
	my $MT = 'Klepněte na ikonu Vstupní panel na hlavním panelu .';
	my $align = '0-0 0-1 1-1 4-3 5-4 6-2 7-5 8-5 9-6 9-7 10-8';
	my $expected = 'Klepněte na ikonu <g id="1"> Vstupní panel </g> na hlavním panelu .';

	reinsert_ok($src, $expected, $MT, $align," The content inside the <g> tag inside longer sentence with reordering");
}


sub test_empty_x_reorder {
	my $src = 'In <g id="1"> </g> Center , the sync playlist can contain one or more <g id="2"> </g> Player playlists or auto playlists .';
	my $MT = 'v aplikaci Center může synchronizovaný seznam stop obsahovat jeden nebo více seznamů stop nebo automatických seznamů stop Player .';
	my $align = '0-0 1-1 1-2 3-5 4-4 5-6 6-3 7-7 8-8 9-9 10-10 12-11 12-12 13-13 14-14 15-15 15-16 11-17 16-18';
	my $expected = 'v aplikaci <g id="1"> </g> Center může synchronizovaný seznam stop obsahovat jeden nebo více seznamů stop nebo automatických seznamů stop <g id="2"> </g> Player .';

	reinsert_ok($src, $expected, $MT, $align,"first g tag should be empty and precede the 'Center' text");
}

sub test_nested_g_tags {
	my $src = '<g id="1"><g id="2"> Planning <x id="3"/> Designing Windows Vista Deployments </g> <g id="4"></g></g>';
	my $MT = 'plánování a návrh nasazení systému Windows Vista';
	my $align = '0-0 1-2 2-4 2-5 3-6 4-3';
	my $expected = '<g id="1"> <g id="2"> plánování a <x id="3"/> návrh nasazení systému Windows Vista </g> <g id="4"> </g> </g>';
	reinsert_ok($src, $expected, $MT, $align,"nest the g tags properly");




}

 
# ---- helper funcs
sub reinsert_ok{
	#helper func - to not repeat everything
	my ($source, $expected, $MT, $word_alignment, $info)= @_;

	my @wordalign = reinsert_wordalign::extract_wordalign($word_alignment);
	my @elements = reinsert_wordalign::extract_inline($source);
	my $result = reinsert_wordalign::reinsert_elements($MT, \@elements, \@wordalign);

	ok($result eq $expected, "$result - $info");
}

