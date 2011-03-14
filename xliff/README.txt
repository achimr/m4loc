M4Loc project - User guide 
============================

This part of the M4Loc project is devoted to XLIFF <=> Moses 
transformations. M4Loc is released under GNU LGPL v3. 
Almost all scripts in M4Loc project are written in the
Perl programming language. Only xliff2moses and moses2xliff are written in 
shell (Linux), or as a bat file (Windows).

For installation and other software prerequisites, read INSTALL.txt


XLIFF => Moses transformation
===============================
Scripts:
xliff2moses.sh(bat)
mod_tokenizer.pl      
lowercase.perl
tokenizer.perl

Process:
The whole XLIFF => Moses transformation can be automated via xliff2moses.sh 
(or, xliff2moses.bat on Windows) script. 

Example:
./xliff2moses.sh  XLIFF_file lang
Where lang means BCP 47 language identifier, e.g. en

If some special options are needed to be set up, xliff2moses can be updated, 
or the whole process can be run manually:

1. Okapi Tikal - creates InlineText from XLIFF file
tikal.sh -xm languagetool.xlf -sl en-us -tl fr-fr
Note: 2 files are created

2. tokenize source and target language files
./mod_tokenizer.pl -l en < languagetool.xlf.en-us > l.tok.en
./mod_tokenizer.pl -l fr < languagetool.xlf.fr-fr > l.tok.fr


3. remove markup
./remove_markup.pl < l.tok.en > l.tok.rem.en
./remove_markup.pl < l.tok.fr > l.tok.rem.fr

4. lowercase, clean and translate in Moses decoder. 


Moses => XLIFF transformation
===============================
Scripts:
moses2xliff.sh(bat)       
reinsert.pl
mod_tokenizer.pl

Process:
The whole Moses => XLIFF transformation can be automated via moses2xliff.sh 
script. 

Example:
./moses2xliff.sh  l en fr
Where l is file name, en and fr means BCP 47 language identifiers

Also in this case, the whole process can be run manually:

1. re-insert markups from translated text
./reinsert.pl l.tok.en < translated.tok.rem.fr > translated.tok.fr

2. detokenize
./mod_detokenizer.pl -l fr < translated.tok.fr > translated.fr

3. put the translated french InlineText back to the original XLIFF file as 
<alt-trans> elements
tikal -lm languagetool.xlf -sl en-us -tl fr-fr -from translated.fr





