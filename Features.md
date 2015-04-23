# New in version 0.9.2 #

## Integration Tools ##
  * Word-alignment based tag reinsertion
  * Additional inline formatting handling option leaving tags in place
  * Addition of new "greedy" method for phrase-alignment based tag reinsertion
  * Recognizing and handling input without markup
  * Removal of outdated tokenizer.pm/detokenizer.pm
  * Pluggable tokenizers/detokenizers
  * Integration of m4loc.pm and m4loc\_tag.pm into one script
  * Conversion of all Perl scripts into modulinos for easier use as libraries
  * Generic CGI API
  * Bug fixes

## Other ##
  * [Adobe Moses Tool Set](TOCAMT.md) for corpus preparation, training and evaluation

# New in version 0.9.1 #
  * Translation of XLIFF files with the proper handling of inline formatting
  * Translation of any file type that the [Okapi Framework](http://okapi.opentag.com) supports

# New in version 0.9.0 #
  * Conversion of TMX translation memory files into parallel corpora for use as MT training data
  * Conversion of parallel corpora into TMX files
  * Splitting of parallel corpora into separate training, tuning and test sets for Moses MT system training
  * Miscellaneous corpus preparation tools

# Other Feature Suggestions #
  * Easier setup and use
  * Integration into different localization and Moses automation frameworks
  * Unit tests
  * Metric to measure quality of XLIFF inline element insertion
  * Windows support
## Suggested by MTM 2013 participants ##
  * Combine information from phrase alignment and word alignment as word     alignment does not produce all target words
  * Add larger quantities/more varied test data
  * Deal with semantic difference between placeholders vs. isolated formatting tags
  * HTML input support (without Okapi needed)
  * TMX tag set support (without Okapi needed)
  * Rules to generate test data
  * Test different source formats (e.g. DITA/HTML)
  * Compare with similar approaches from Matecat/EC