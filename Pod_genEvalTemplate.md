_This page was generated from POD using [pod2gcw](http://code.google.com/p/pod2gcw) and is not intended for editing._

## NAME ##
genEvalTemplate.pl - Generate template XML file for NIST BLEU scorer

## USAGE ##
```
    perl genEvalTemplate.pl <src|tst|ref> <system id> <set id> <source language id> <target language id> <number of entries>\n"
```
This tool generates a template XML file for the NIST BLEU scorer (<http://www.itl.nist.gov/iad/mig/tools/>; file: `mteval*`).

The following parameters need to be supplied:

`<src|tst|ref>`


> Indicates if a template for a source, test or reference file should be generated

> 
`<system id>`


> Name of MT sytem with which the set was created

> 
`<set id>`


> Name of evaluation set

> 
`<source language id>`


> 2-letter ISO-639 source language identifier

> 
`<target language id>`


> 2-letter ISO-639 target language identifier

> 
`<number of entries>`


> Number of lines in the evaluation set

> 
This script only generates a template - text for the evaluation still needs to be inserted with `wrap-xml.pl` contained in the Moses MT scripts.
