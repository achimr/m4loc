_This page was generated from POD using [pod2gcw](http://code.google.com/p/pod2gcw) and is not intended for editing._

## NAME ##
testset.pl - Random line selection from a text file

## USAGE ##
```
    perl testset.pl -n number [-o outputfile] [-h heldoutfile] < IN_FILE
```
This tool reads a text corpus from standard input and writes randomly selected `number` lines to the file `test.out` (file name can be changed with -o option). It also writes the line indices of the selected lines (zero-indexed) to standard output. The held out lines (i.e. lines that were not selected for the random test set) get written to the file `test.hld` (file name can be changed with -h option).

The line indices written to standard output can be captured in a file and used in conjunction with the scripts `lineextract.pl` and `heldextract.pl` to extract the selected and held out lines from another text file with the same number of lines. This is very useful for creating training, test and evaluation sets from parallel corpora.

```
```
## PREREQUISITES ##
Getopt::Std
