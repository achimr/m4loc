_This page was generated from POD using [pod2gcw](http://code.google.com/p/pod2gcw) and is not intended for editing._

## NAME ##
removeEmpty.pl - Removal of empty lines from a sentence aligned corpus

## USAGE ##
```
    perl removeEmpty.pl <source input file> <target input file> <source output file> <target output file>
```
Reads a sentence-aligned, parallel corpus from `<source input file>` and `<target input file>`, removes any lines where either source or target sentences are empty and writes the results to `<source output file>` and `<target output file>`.

## PREREQUISTES ##