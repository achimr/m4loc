_This page was generated from POD using [pod2gcw](http://code.google.com/p/pod2gcw) and is not intended for editing._

## wrap\_tokenizer.pm: tokenizes InLineText ##
### Description ###
wrap\_tokenizer.pm is a part of M4Loc effort <http://code.google.com/p/m4loc/>.  It takes input (line, or file) in InlineText format ( this format is tikal -xm output; tikal is part of Okapi Framework).  The output is tokenized/segmented InlineText with untokenized XML/XLIFF tags and url addresses.

wrap\_tokenizer.pm is a wrapper for some external tokenizer. It splits out input into different chunks. The chunks with plain text intended for translation are sent to an external tokenizer and then, wrap\_tokenizer waits for the output (tokenized chunks). If dataset contain some strings which shouldn't be tokenized, an user can relatively seamlessly replace those strings into some non-terminal. Then, tokenization takes place. And finally, non-terminals are converted back into original form. For example, various URLs or special tags which are not correctly processed by a CAT tool, can be a subject of such transformation (e.g. URL->non\_terminal->URL). Non-terminals are unicode characters which are not used anywhere in the dataset. By default, URLs and XML entities are treated this way. But many others can be added.

Inline text format (wrap\_tokenizer's input) can consists of the following tags: `g,x,bx,ex,lb,mrk,n`. Where `g,x,bx,ex,lb,mrk` are XLIFF inline elements and `n` can be used for being processed by Moses' -xml-input (<http://www.statmt.org/moses/?n=Moses.AdvancedFeatures#ntoc4>).

The script takes data from standard input, process it and the output is written to the standard output. Input and output are UTF-8 encoded data.

The functinality of wrap\_tokenizer is the same as mod\_tokenizer. The difference is that mod\_tokenizer is sticked exclusively to Moses' tokenizer.perl. However, for some languages (mainly East-asian) is better to use different tokenizer, which is not possible in mod\_tokenizer. For more info on tokenizing and whole framework of XLIF`-`Moses is described in: <http://www.mt-archive.info/EAMT-2011-Hudik.pdf>

```
```
```
```
#### USAGE ####
`perl wrap_tokenizer.pm [-t -p ] < inFile 1> outFile 2>errFile`

```
```
where _inFile_ contains InlineText data (Okapi Framework, tikal -xm) and _outFile_  is tokenized, UTF-8 encoded file ready to processed by Markup remover (M4Loc).

-t specify an path to and external tokenizer itself (default -t "./tokenizer.perl" )

-p options for the selected tokenizer (default -p "-q -l en" - which means quiet run and English language"

WARNING: external tokenizer needs to:

1. run in quiet mode (no additional info, just tokenized string) 2. be able to process and output UTF-8 data

```
```
#### PREREQUISITES perl at least 5.10.0 ####
XML::LibXML::Reader

IPC::Run

Encode

#### Author ####
Tomáš Hudík, thudik@moraviaworldwide.com

```
```
#### TODO: ####
1. add - if str\_out is too long - print it to file

2. which XML entities (< is &lt;, & is &amp;,...) should be in "normal" form(<) and which should be encoded (&amp;)

3. rewrite script in order to avoid global variables

4. improve documentation
