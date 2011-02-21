#!/bin/bash

#
# Script to convert and import Moses output into XLIFF file
#
# Reinsertion of markup from source InlineText into plain text translated
# with Moses, output and input are expected to be UTF-8 encoded 
# (without leading byte-order mark)
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

# Fixing word case with a recaser/truecaser is outside the scope of this
# script, but is a pre-requisite

# Usage: moses2xliff.sh <file base name> <BCP 47 source language identifier> <BCP 47 target language identifier>
# TBD: parameter check and usage description output

./reinsert.pl $1.tok.$2 < $1.ucs.$3 > $1.ins.$2
./mod_detokenize.pl -l $3 < $1.ins.$3 > $1.det.$3
tikal.sh -lm $1.xlf 
