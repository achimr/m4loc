_This page was generated from POD using [pod2gcw](http://code.google.com/p/pod2gcw) and is not intended for editing._

## NAME ##
epRemoveMarkup.pl - Europarl corpus preparation

## USAGE ##
```
    perl epRemoveMarkup.pl <base name old> <base name new> <source language> <target language>
```
Cleans up Europarl corpus files for use as training input for Giza++ as suggested on <http://www.statmt.org/europarl/>

  * strip empty lines and their corresponding lines (highly recommended)
  * remove lines with XML-Tags (starting with "<") (required)
The input corpus has to be available in the files `<base name old>.<source language>` and `<base name old>.<target language>`. The cleaned corpus will be written to the files `<base name new>.<source language>` and `<base name new>.<target language>`.

The script does not perform tokenization and lowercasing of the corpus - the Europarl tool set already has the tools `tokenizer.perl` and `lowercase.perl` available for this purpose.

## PREREQUISITES ##