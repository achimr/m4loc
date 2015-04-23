_This page was generated from POD using [pod2gcw](http://code.google.com/p/pod2gcw) and is not intended for editing._

## NAME ##
pseudo\_translate.pm: Pseudo-translation of text with trace output

## DESCRIPTION ##
This script pseudo-translates text to <http://en.wikipedia.org/wiki/Pig_latin>.  First it selects phrases up to length max\_phrase\_length (default: 1) from the source text.  It then rearranges the phrases in random order and translates their content into pig latin. The phrase selection and reordering information is output as traces which indicate the token  indices in the original text: |start-end|. This is equivalent to the output of the Moses SMT engine with the -t option specified. The pseudo translation script can therefore be used as a standin for the engine for testing purposes.

The script does not handle upper- and lowercasing.

## USAGE ##
```
    perl pseudo_translate.pm [-n max_phrase_length] < tokenized_lowercased_source_file > pseudo_translated_output_file
```
Input is expected to be UTF-8 encoded (without a leading byte-order mark U+FEFF) and  output will be UTF-8 encoded as well.

### OPTIONS ###
-n


> Indicates the maximum phrase length for phrase selection from the source. Default is 1.

> 
### EXPORT ###
translate(max\_phrase\_len,token\_array)


> Pseudo-translates tokens in `token_array` into pig Latin with a longest phrase length of `max_phrase_len`. Rearrages the phrases at random and includes the Moses trace information for the phrase reordering. Returns string.

> 