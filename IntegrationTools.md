#summary Integration Tools Reference
# Translation of different document formats using the Okapi Framework #
## Main script ##
  * [m4loc.pm](Pod_m4loc.md): Translation of Okapi Moses InlineText format
## Tokenization/Detokenization ##
  * [wrap\_tokenizer.pm](Pod_wrap_tokenizer.md): Wrapper for tokenizer preserving markup
  * [wrap\_detokenizer.pm](Pod_wrap_detokenizer.md): Wrapper for detokenizer preserving markup
  * [fix\_markup\_ws.pm](Pod_fix_markup_ws.md): Fix whitespace around markup in target according to whitespace in source
## Tag preservation using phrase alignment information from decoder ##
  * [remove\_markup.pm](Pod_remove_markup.md): Removal of bracketed markup from text file
  * [recase\_preprocess.pm](Pod_recase_preprocess.md): Remove Moses traces from translated text
  * [recase\_postprocess.pm](Pod_recase_postprocess.md): Reinsert Moses traces into recased Moses output
  * [reinsert.pm](Pod_reinsert.md): Reinsert markup from source InlineText into translation based on phrase-alignment information
  * reinsert\_greedy.pm: Reinsert markup from source InlineText into translation based on phrase-alignment information with alternative greedy algorithm
  * [pseudo\_translate.pm](Pod_pseudo_translate.md): Pseudo-translation of text with trace output
  * m4loc.pl: Script to translate file formats supported by Okapi (outdated - use tikal and m4loc.pm instead)
## Tag preservation using word alignment information from decoder ##
  * [reinsert\_wordalign.pm](Pod_reinsert_wordalign.md): Reinsert markup from source InlineText into translation - using word alignment information
## Translation with tag-oriented tag placement ##
  * [wrap\_markup.pm](Pod_wrap_markup.md): Script to wrap markup present in tokenized source to funnel it unaffected through the Moses decoder
  * [decode\_markup.pm](Pod_decode_markup.md): Decode markup that was escaped for funneling it through the decoder

