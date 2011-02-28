@echo off
rem
rem
rem Batch to convert XLIFF file into input file for Moses
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

rem Usage: xliff2moses.bat <xliff file name> <BCP 47 source language identifier>

if "%1" == "" goto usage
if "%2" == "" goto usage
if not exist %1 goto noxliff

call tikal.bat -xm %1 
if not exist %1.%2 goto nosource

perl %~dp0\mod_tokenizer.pl -l %2 < %1.%2 > %1.tok.%2
perl %~dp0\remove_markup.pl < %1.tok.%2 > %1.nmk.%2
perl %~dp0\lowercase.perl < %1.nmk.%2 > %1.lcs.%2
goto end

:usage
echo Usage: xliff2moses.bat ^<xliff file name^> ^<BCP 47 source language identifier^>
goto end

:noxliff
echo Error: input XLIFF file %1 not found
goto end

:nosource
echo Error: after extraction with Okapi source file %1.%2 not found
goto end

:end
