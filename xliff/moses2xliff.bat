@echo off
rem
rem Batch to convert and import Moses output into XLIFF file
rem
rem Reinsertion of markup from source InlineText into plain text translated
rem with Moses, output and input are expected to be UTF-8 encoded 
rem (without leading byte-order mark)
rem
rem Copyright 2011 Digital Silk Road
rem 
rem This program is free software: you can redistribute it and/or modify
rem it under the terms of the GNU Lesser General Public License as published by
rem the Free Software Foundation, either version 3 of the License, or
rem (at your option) any later version.
rem 
rem This program is distributed in the hope that it will be useful,
rem but WITHOUT ANY WARRANTY; without even the implied warranty of
rem MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
rem GNU Lesser General Public License for more details.
rem 
rem You should have received a copy of the GNU Lesser General Public License
rem along with this program.  If not, see <http://www.gnu.org/licenses/>.
rem

rem Fixing word case with a recaser/truecaser is outside the scope of this
rem script, but is a pre-requisite

rem Usage: moses2xliff.sh <file base name> <BCP 47 source language identifier> <BCP 47 target language identifier>
rem TBD: parameter check and usage description output

perl %~dp0\reinsert.pl %1.tok.%2 < %1.ucs.%3 > %1.ins.%2
perl %~dp0\mod_detokenize.pl -l %3 < %1.ins.%3 > %1.det.%3
tikal.bat -lm %1.xlf 
