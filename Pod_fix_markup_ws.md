_This page was generated from POD using [pod2gcw](http://code.google.com/p/pod2gcw) and is not intended for editing._

## NAME ##
fix\_markup\_ws.pm: Fix whitespace around markup in target according to whitespace in source

## DESCRIPTION ##
Tokenization and tag preservation/reinsertion introduces whitespace around markup. To achieve the best possible output, this script retrieves information about whitespace around markup in the source segment and tries to project this whitespace to the target translation. This is usually the last step in the markup handling process.

## USAGE ##
```
    perl fix_markup_ws.pm source < detokenized_target > fixed_target
```
### EXPORT ###
fix\_whitespace(source,detokenized\_target)


> Fixes the whitespace around markup in `detokenized_target` based on whitespace around markup in the non-tokenized `source`. Returns the fixed string.

> 