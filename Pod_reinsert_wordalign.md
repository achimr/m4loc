_This page was generated from POD using [pod2gcw](http://code.google.com/p/pod2gcw) and is not intended for editing._

## NAME ##
reinsert\_wordalign.pm: Reinsert markup from source InlineText into translation - using word alignment information

## USAGE ##
```
    perl reinsert_wordalign.pm source_tokenized_InlineText_file traced_wordalignment < target > target_tokenized_InlineText_file
```
Script to reinsert markup from source InlineText into plain text Moses output with traces (traces are phrase alignment information).

`source_tokenized_InlineText_file` is expected to be a tokenized version of the  InlineText file format output by the Moses Text Filter of  <http://okapi.opentag.com>.

`traced_wordalignment` is an additional output output file from the Moses decoder invoked with the `-alignment-output-file` option. It contains the word alignment for the decoded translation, one segment per line, aligned with source and target output. `reinsert.pm` uses this information to insert XLIFF inline elements roughly at the  correct positions in the target text.

`target` is the output of the Moses decoder invoked with the `-t`  option.

The output `target_tokenized_InlineText_file` is a tokenized version of the target text with XLIFF inline elements inserted. Detokenization still needs to be applied where appropriate.

The script follows these principles when reinserting inline elements:

Input is expected to be UTF-8 encoded (without a leading byte-order  mark U+FEFF) and output will be UTF-8 encoded as well.
