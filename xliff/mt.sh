#!/bin/bash
# (c) 2014: TAUS
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

# Read file name from command line argument
# ask user if missing
if [ "$1" = "" ]; then
	read -p "Full path to input file:" input
else
	input=$1
fi
filename=$(basename "$input")
dirname=$(dirname "$input")
extension="${filename##*.}"
file="${filename%.*}"

# Extract Moses InlineText from input file
if [ "$extension" = "tmx" -o "$extension" = "xlf" ]; then
	/opt/okapi/tikal.sh -xm $input
else
	/opt/okapi/tikal.sh -seg -xm $input
fi

# Machine translate the InlineText file
/opt/m4loc/xliff/m4loc.pm -o t -s en -t es -m /home/ubuntu/mtsys/en-es_tiny/binarized_model/moses.ini -c /home/ubuntu/mtsys/en-es_tiny/data/truecase-model.en < $input.en > $input.es

# Leverage translated version of input file from translated Moses InlineText 
if [ "$extension" = "tmx" -o "$extension" = "xlf" ]; then
	/opt/okapi/tikal.sh -lm -overtrg -from $input.es $input
else
	/opt/okapi/tikal.sh -seg -lm -overtrg -from $input.es $input
fi

read -p "Press [Enter] to continue ..."

