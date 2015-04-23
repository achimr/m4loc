_This page was generated from POD using [pod2gcw](http://code.google.com/p/pod2gcw) and is not intended for editing._

## txt2tmx.pl: Parallel Corpus to TMX converter ##
### USAGE ###
```
    perl txt2tmx.pl <source language> <target language> <base name>
```
The purpose of this tool is to take two corpus input files named `<base name>.<source language>` and `<base name>.<target language>` and merge them into a bi-lingual TMX file named `<base name>.tmx`.

The input files need to be encoded encoded in UTF-8 (preferably without a leading Unicode byte-order mark U+FEFF), the tool will not perform a verification of the input encoding.

The base name can contain a path component in case the files are contained in a different directory. The tool needs write permission in the target directory.

### PREREQUISITES ###
XML::TMX::Writer
