_This page was generated from POD using [pod2gcw](http://code.google.com/p/pod2gcw) and is not intended for editing._

## NAME ##
recase\_postprocess.pm: Reinsert Moses traces into recased Moses output

## DESCRIPTION ##
Script to reinsert Moses traces (phrase alignment info) into recased target language text. The traces are required to correctly reinsert formatting markup (e.g. XLIFF inline elements) with the script `reinsert.pm`. `lowercased_traced_target` is the output of Moses with the `-t` option. `recased_target` is the output of a recasing model created with Moses (refer to the Moses documentation for further information).

## USAGE ##
```
    perl recase_postprocess.pm lowercased_traced_target < recased_target > recased_traced_target
```
Input is expected to be UTF-8 encoded (without a leading byte-order  mark U+FEFF) and output will be UTF-8 encoded as well.

### EXPORT ###
retrace(traced\_target,recased\_target)


> Reinsert Moses traces (phrase alignment info) present in `traced_target` into recased target language text `recased_target`. Returns string.

> 