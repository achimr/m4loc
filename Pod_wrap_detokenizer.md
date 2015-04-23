_This page was generated from POD using [pod2gcw](http://code.google.com/p/pod2gcw) and is not intended for editing._

## wrap\_detokenizer.pm: detokenize InLineText format ##
### Description ###
It detokenizes data back to InlineText; this data is ready for tikal -lm input (Okapi Framework).  wrap\_detokenizer.pm is a part of M4Loc effort <http://code.google.com/p/m4loc/>. The output is  detokenized text with proper XML/XLIFF tags. For lower level specification, check the code.

The script takes data from standard input, process it and the output is written to the standard  output. Input and output are UTF-8 encoded data.

```
```
#### USAGE ####
`perl wrap_detokenizer.pm [-t -p ] < inFile 1> outFile 2>errFile`

```
```
where _inFile_ contains  data from Markup Reinserter (M4Loc) and _outFile_  is ready to be processed by tikal -lm process (Okapi framework).

-t specify an path to and external detokenizer itself (default -t "detokenizer.perl" )

-p options for the selected tokenizer (default -p "-l en" - which means English  language

#### PREREQUISITES perl at least 5.10.0 ####
Getopt::Long;

#### Author ####
Tomáš Hudík, thudik@moraviaworldwide.com

```
```
#### TODO: ####
1. strict testing (QA), since it is likely that more sophisticated approach will be required (de-tokenization is problematic in Moses since only a few languages are supported and it is difficult to add a support for another language)

2. IPC::Run is not giving warning if some name of external program is mistyped, or not started properly
