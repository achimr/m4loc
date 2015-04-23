_This page was generated from POD using [pod2gcw](http://code.google.com/p/pod2gcw) and is not intended for editing._

## NAME ##
decode\_markup.pm: Decode markup that was escaped for funneling it through the decoder

## DESCRIPTION ##
Using the script `wrap_markup.pm` tagging markup gets escaped, wrapped in XML and using the `-xml-input exclusive` Moses option funneled through the decoder. After decoding the tagging markup is still in its escaped form. The `decode_markup.pm` modulino brings the escaped markup back into its previous form.

## USAGE ##
```
    perl decode_markup.pm < encoded_target > decoded_target
```
### EXPORT ###
decode\_markup(tokenized\_target)


> Unescape markup contained in `tokenized_target`

> 
## KNOWN ISSUES ##
This could also decode entities that were already encoded before the application of wrap\_markup.pm.

## PREREQUISITES ##
HTML::Entities
