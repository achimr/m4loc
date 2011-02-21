#!/bin/bash

#
# Script to convert XLIFF file into input file for Moses
#
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
#

# Usage: xliff2moses.sh <xliff file name> <BCP 47 source language identifier>
# TBD: parameter check and usage description output

tikal.sh -xm $1
./mod_tokenizer.pl -l $2 < $1.$2 > $1.tok.$2
./remove_markup.pl < $1.tok.$2 > $1.nmk.$2
./lowercase.perl < $1.nmk.$2 > $1.lcs.$2
