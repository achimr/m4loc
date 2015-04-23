_This page was generated from POD using [pod2gcw](http://code.google.com/p/pod2gcw) and is not intended for editing._

## NAME ##
m4loc.pm: Translation of Okapi Moses InlineText format

## DESCRIPTION ##
This modulino translates Moses InlineText extracted from different document formats with the Okapi Framework using a Moses engine specified in the parameters.

## USAGE ##
```
    perl m4loc.pm [-o p|w|t][-r recase_ini_file][-e][-n][-s source_language][-t target_language][-m moses_ini_file][-c truecase_ini_file][-k tokenizer_command][-d detokenizer_command] < source_file > target_file
```
### OPTIONS ###
-o


> Tag preservation method: `p`: based on phrase-alignment information from the decoder; `w`: based on word-alignment information from the decoder; `t`: keeps tags in place and translates text around them.

> 
-r recase\_ini\_file


> Recase model configuration `moses.ini` file. Cannot be used simultaneously with the `-c` option.

> 
-e


> Use greedy tag reinsertion method in phrase-alignment tag preservation method. Can only be used with `-o p` option.

> 
-n


> Do not detokenize output (useful for evaluation purposes).

> 
-s source\_language


> ISO639-1 two letter language code of source language.

> 
-t target\_language


> ISO639-1 two letter language code of target language.

> 
-m moses\_ini\_file


> Moses engine configuration `moses.ini` file.

> 
-c truecase\_ini\_file


> Truecase model file for truecasing of source input. Cannot be used simultaneously with the `-r` option.

> 
-k tokenizer\_command


> Tokenizer command if different from Moses `tokenizer.perl`.

> 
-d detokenizer\_command


> Detokenizer command if different from Moses `detokenizer.perl`.

> 
### EXPORT ###
new(source\_language,target\_language,moses\_ini\_file,truecase\_ini\_file,tokenizer\_command,tokenizer\_parameters,detokenizer\_command,detokenizer\_parameters,recase\_ini\_file,greedy\_reinsert,tag\_preservation\_method,no\_detokenization)


> Object constructor that also initializes all dependent programs like the tokenizer, detokenizer, Moses and casing programs. The parameters correspond to the command line options described above.

> 
translate(source\_string)


> Object method to translate `source_string` with the phrase-alignment based tag preservation method. Returns translated string.

> 
translate\_wordalign(source\_string)


> Object method to translate `source_string` with the word-alignment based tag preservation method. Returns translated string.

> 
translate\_tag(source\_string)


> Object method to translate `source_string` with the method tag preservation method keeping tags in place. Returns translated string.

> 