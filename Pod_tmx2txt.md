_This page was generated from POD using [pod2gcw](http://code.google.com/p/pod2gcw) and is not intended for editing._

## tmx2txt.pl: Extraction of a bilingual corpus from a TMX file ##
### USAGE ###
```
    perl tmx2txt.pl [-s] <source language> <target language> <output basename> <tmx file>
```
This tool extracts a bilingual corpus from a TMX file that contains segments in at least two languages. The resulting parallel corpus is stored in two files named `<output basename>.<source language>` and `<output basename>.<target language>` which are UTF-8 encoded. The tool does not verify if the two languages specified on the command line actually exist in the TMX file.

The tool removes any inline formatting markup to allow the use of the corpus for the training of statistical MT systems.

`<output basename>` and `<tmx file>` can contain a path component in case the files are contained in a different directory. The tool needs write permission in the output directory.

_-s_


> If option `-s` is set, inserts a single space for deleted markup instead of just deleting it.

> 
### PREREQUISITES ###
XML::TMX::Reader
