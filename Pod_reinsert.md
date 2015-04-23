_This page was generated from POD using [pod2gcw](http://code.google.com/p/pod2gcw) and is not intended for editing._

## NAME ##
reinsert.pm: Reinsert markup from source InlineText into translation based on phrase-alignment information

## DESCRIPTION ##
Script to reinsert markup from source InlineText into plain text Moses output with traces (traces are phrase alignment information).

`source_tokenized_InlineText_file` is expected to be a tokenized version of the  InlineText file format output by the Moses Text Filter of  <http://okapi.opentag.com>.

`traced_target` is the output of the Moses decoder invoked with the `-t`  option. When invoked with the `-t` option, the Moses decoder outputs  phrase alignment information which indicates which source phrases where  translated with which target phrases. `reinsert.pm` uses this information  to insert XLIFF inline elements roughly at the correct positions in  the target text.

The output `target_tokenized_InlineText_file` is a tokenized version of the target text with XLIFF inline elements inserted. Detokenization still needs to be applied where appropriate.

The script follows these principles when reinserting inline elements:

## USAGE ##
```
    perl reinsert.pm source_tokenized_InlineText_file < traced_target > target_tokenized_InlineText_file
```
Input is expected to be UTF-8 encoded (without a leading byte-order  mark U+FEFF) and output will be UTF-8 encoded as well.

### EXPORT ###
extract\_inline(inline\_text)


> Extracts tag information in the form of an array from the `inline_text` parameter in Moses InlineText format. The array is used by the function `reinsert_elements` for the reinsertion of tags in the target text.

> 
reinsert\_elements(elements\_array,traced\_target)


> Reinserts tags represented in `elements_array` into `traced_target` (output with the Moses `-t` option) based on the phrase alignment information in the traces. Returns tagged, tokenized target string.

> 