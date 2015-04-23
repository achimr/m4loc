_This page was generated from POD using [pod2gcw](http://code.google.com/p/pod2gcw) and is not intended for editing._

## NAME ##
recase\_preprocess.pm: Remove Moses traces from translated text

## DESCRIPTION ##
Script to remove Moses traces (phrase alignment info) from translated text in preparation for correcting upper-/lowercase with the recaser. Moses traces - phrase alignment information enclosed in vertical bars `|start-end|` - are required to reinsert XLIFF inline element markup back into the text. However, when applying a recaser model, the traces negatively impact the upper- and lowercasing. To avoid this, the traces can be temporarily removed before recasing and then reinserted with `recase_postprocess.pm`.

## USAGE ##
```
    perl recase_preprocess.pm < target_with_traces > target_tokenized
```
Input is expected to be UTF-8 encoded (without a leading byte-order  mark U+FEFF) and output will be UTF-8 encoded as well.

### EXPORT ###
remove\_trace(traced\_target)


> Remove trace (phrase alignment) information from a sentence decoded with the Moses `-t` option. Returns string with traces removed.

> 