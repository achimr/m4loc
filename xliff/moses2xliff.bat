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

rem Usage: moses2xliff.bat <file base name> <BCP 47 source language identifier> <BCP 47 target language identifier>

if "%1" == "" goto usage
if "%2" == "" goto usage
if "%3" == "" goto usage
if not exist %1.tok.%2 goto notok
if not exist %1.ucs.%3 goto notarget

perl %~dp0reinsert.pl %1.tok.%2 < %1.ucs.%3 > %1.ins.%3
if not exist %1.ins.%3 goto errinsert
perl %~dp0mod_detokenizer.pl -l %3 < %1.ins.%3 > %1.det.%3
if not exist %1.det.%3 goto errdetok
tikal.bat -lm %1.xlf 

goto end 

:notok
echo Error: tokenized source file %1.tok.$2 not found
goto end

:notarget
echo Error: Recased target file with phrase alignment %1.ucs.%3 not found
goto end

:errinsert
echo Error: Markup reinsertion failed. File %1.ins.%3 not found
goto end

:errdetok
echo Error: Detokenization failed. File %1.det.%3 not found
goto end

:usage
echo moses2xliff.sh ^<file base name^> ^<BCP 47 source language identifier^> ^<BCP 47 target language identifier^>
goto end

:end
