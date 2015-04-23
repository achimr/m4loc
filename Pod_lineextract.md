_This page was generated from POD using [pod2gcw](http://code.google.com/p/pod2gcw) and is not intended for editing._

## NAME ##
lineextract.pl - Extract lines from a text file based on line numbers file

## USAGE ##
```
    perl lineextract.pl linesfile < INFILE > OUTFILE
```
This tool reads a text corpus from standard input and a line numbers (zero-indexed) from `linesfile`. It outputs the text corpus lines specified in the line numbers file to standard output.

The line numbers file can for example be created by the script `testset.pl`.

## PREREQUISITES ##