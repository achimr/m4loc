#!/usr/bin/perl -w -T

#
# Simple HTTP REST API to perform InlineText machine translations
#
# Copyright 2012 Digital Silk Road
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
use constant LIB_DIR => '/usr/local/bin/moses-scripts/m4loc/xliff';

use CGI;

use lib LIB_DIR;
use m4loc;

my $q = CGI->new;
my @tok_param = ('-l','fr');
my @detok_param = ('-l','en');

# Untaint environment
$ENV{'PATH'} = '/usr/local/bin:'.LIB_DIR;
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)}; 

my $m4loc = m4loc->new("fr","en",LIB_DIR."/tokenizer.pm",\@tok_param,LIB_DIR."/detokenizer.pm",\@detok_param,"./moses.ini","./recaser.ini");
my $source = $q->param('source');
if(length($source) > 500) {
    print $q->header('text/plain','413 Request Entity Too Large');
}
else {
    print $q->header('text/plain');
    print $m4loc->translate($source);
}
