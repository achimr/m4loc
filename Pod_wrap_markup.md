_This page was generated from POD using [pod2gcw](http://code.google.com/p/pod2gcw) and is not intended for editing._

## NAME ##
wrap\_markup.pm: Script to wrap markup present in tokenized source to funnel it unaffected through the Moses decoder

## DESCRIPTION ##
InlineText markup is a subset of XLIFF inline markup for segments. One method to preserve InlineText markup present in source segments in Moses is to protect it from "_translation_" by the decoder. This script wraps markup in XML that when used with the Moses option `-xml-input exclusive` protects the markup from translation. It also introduces `<wall/>` tags between the markup and surrounding text to keep tags in the exact order as in the source during decoding. This prevents phrase reordering across walls and can negatively impact translation quality.

## USAGE ##
```
    perl wrap_markup.pm < tokenized_source > wrapped_source
```
### EXPORT ###
wrap\_markup(tokenized\_source)


> Wraps InlineText markup in XML markup compliant with the Moses XML input feature and inserts `<wall/>` markup between formatting markup and translatable text. Returns wrapped text ready for decoding.

> 
## PREREQUISITES ##
HTML::Entities
