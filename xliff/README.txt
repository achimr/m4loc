M4Loc project - User guide 
============================

This part of the M4Loc project is devoted to XLIFF <=> Moses 
transformations. M4Loc is released under GNU LGPL v3. 
All scripts in M4Loc project are written in the programming 
language Perl, however, the project is using other programs 
which are written in different programming languages 
(Okapi Tikal - Java). M4loc is capable to work with file formats 
which are processable by Okapi Tikal.

For installation and software prerequisites, read INSTALL.txt


XLIFF <=> Moses transformation
===============================
Scripts:
m4loc.pl
m4loc.pm
m4loc_tag.pm
wrap_tokenizer.pm
wrap_detokenizer.pm
remove_markup.pm
reinsert.pm
fix_markup_ws.pm
recase_preprocess.pm
recase_postprocess.pm
tokenizer.pm
detokenizer.pm
lowercase.perl

Process:
The whole XLIFF<=>Moses transformation is covered by m4loc.pl. It is
important to set up all variables and paths in this program before it is
executed.

Example:
./m4loc.pl -i my_file.xlf -sl en-us -tl de

Where, file my_file.xlf is going to be translated, and -sl stands for source
and -tl for target language. 

1. my_file.xlf is converted into so-called Inline text format, which is plain
text with a few XML tags. The conversion is done by an external program:
Okapi Tikal (option -xl). Be careful about setting up correct path to the
program (variable $tikal in m4loc.pl) as well as source and target language 
(-sl,-tl). The languages must be the same as it is specified in the xlf file 
(in "xml:lang=" for each source). If the source language is not specified 
explicitly, it will be chosen from Java system. If such a language doesn't 
exist in the input file then output will be empty. Many different
non-default parameters(www.opentag.com/okapi/wiki/index.php?title=Tikal) 
can be added to this step by specifying them in $command variable for tikal -xm 
process.


2. tokenization takes a place. External tokenizer can be set up
($tok_program) as well as its parameters (@tok_param). Now, default Moses'
tokenizer is set up. Be careful about setting up source language for
tokenization while Moses' default tokenizer requires BCP 47 standard. Even
conversion (step 1) and tokenization (step 2) are working with the same
source language, often it is written with different symbols. For example,
often it is used "en-us" in xlf file, while it needs to be specified by BCP 47 
as "en" in tokenization step. To avoid such inconvenience, it can be:
renamed file "nonbreaking_prefixes/nonbreaking_prefix.en" into 
"nonbreaking_prefixes/nonbreaking_prefix.en-us"; or specify correctly -sl
(for 1. step), and @tok_param (for  2. step)
To see whether the tokenization program is working correctly, small xlf
file can be processed with $debug=1 (debugging output will be printed)

3. Markup removing is provided by a simple perl script.

4. Lowercasing is carried out by internal Perl's function lc

5. Translation done by Moses. User is required to have fully functional
Moses with already trained engine (SMT system). Be careful about setting up 
$moses_prog and $moses_param. One of Moses' parameters has to be "-t", 
otherwise reinsertion process could not be carried. Another problem is with 
echo function. Echo prints out everything between ' and ', however, if the
string inside contains ' character - it will cause error.

6. Recase preprocessing. It prepares a string for recasing. This step can
be skipped if no recasing engine is trained.

7. Recasing. External program - Moses. User's recasing engine 
($recase_prog and $recase_param) makes recasing for an input string. Here is 
again problem with the echo function like in the step 5. This step is not 
mandatory.

8. Recase postprocess. Carried out by a simple Perl script

9. Reinsertion. Reinsert.pm is a difficult script even its parameter setting 
is simple. It requires 2 inputs: tokenized source (result of step 2) and 
recasing output (or Moses' output if recasing is omitted).

10.Detokenization. It is done by wrapper (it is executed by an external
program, Moses' detokenizer by default). Moses detokenizer is written only
for a few languages and is hardly extensible for other in contrary to
Moses' tokenizer. It is because of language specific rules are hard-coded
into Perl program, while Moses tokenizer is reading language specific rules
from external file (this file can be relatively easily written for any
language).

11. Fixing of white spaces around tags. It fixes a number of white spaces
around reinserted tags. Two inputsecho in calling of Moses
2. make better detokenization processare needed: $source (Tikal's output) and
$detok (detokenization output)


Problems and debugging:
=======================
In case of any problem, it is important to localize where (which script)
the problem occurred. This can by done by setting up parameter $debug=1 and 
processing of some toy-example file containing only a few segments. 


TODO
=====

1. change command echo in calling of Moses
2. make better detokenization process

