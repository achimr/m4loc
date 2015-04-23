_This page was generated from POD using [pod2gcw](http://code.google.com/p/pod2gcw) and is not intended for editing._

## NAME ##
remove\_markup.pm: Removal of bracketed markup from text file

## DESCRIPTION ##
This tool removes markup from a sentence-split, optionally tokenized text  to allow the translation of the contained text with Moses. By default it only removes XLIFF `<x>`, `<bx>`, `<ex>`, `<lb>`, `<mrk>` and `<g>` tags,  while with the -a option the script removes all angle-bracketed tags.

Any unmatched brackets do not get removed as these can be valid text that needs to be translated (e.g. "The thermometer shows a temperature < 32 °F .").

As part of the markup removal the script also collapses consecutive whitespace  into one space character. It also terminates the output lines with the platform-specific line  termination character(s).

## USAGE ##
```
    perl remove_markup.pm [-a] < <text file with markup> > <plain text file>
```
Input is expected to be UTF-8 encoded (without a leading byte-order mark U+FEFF) and output will be UTF-8 encoded as well.

### OPTIONS ###
-a


> If this option is specified the tool will remove all markup between opening `<` and closing `>` brackets.

> 
### EXPORT ###
remove(all,markup\_string)


> Remove Moses InlineText markup from `markup_string`. If the boolean option `all` is set, will remove all markup between opening `<` and closing `>` brackets. Returns string.

> 