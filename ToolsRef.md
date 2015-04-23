#summary Tools Reference
# Translation of XLIFF files #
  * [mod\_tokenizer.pl](Pod_mod_tokenizer.md) Modified Moses tokenizer for Okapi InlineText format
  * [remove\_markup.pl](Pod_remove_markup.md) Removal of markup from tokenized file for Moses decoding

  * [pseudo\_translate.pl](Pod_pseudo_translate.md) Pseudo-translation into pig latin with random phrase rearrangement

  * [recase\_preprocess.pl](Pod_recase_preprocess.md) Pre-processing of Moses output with phrase alignment info for recasing
  * [recase\_postprocess.pl](Pod_recase_postprocess.md) Post-processing of recased output for inline element reinsertion

  * [reinsert.pl](Pod_reinsert.md) Reinsertion of XLIFF inline elements into Moses output
  * [mod\_detokenizer.pl](Pod_mod_detokenizer.md) Modified Moses detokenizer for Okapi InlineText format

  * [xml\_entity.pl](Pod_xml_entity.md) Unescaping of XML entities in Okapi InlineText format

# Conversion of TMX files #
  * [tmx2txt.pl](Pod_tmx2txt.md) Extraction of a bilingual corpus from a TMX file
  * [txt2tmx.pl](Pod_txt2tmx.md) Parallel Corpus to TMX converter

# Parallel Corpus Processing #
  * [epRemoveMarkup.pl](Pod_epRemoveMarkup.md) Europarl corpus preparation

  * [removeEmpty.pl](Pod_removeEmpty.md) Removal of empty lines from a sentence aligned corpus

  * [testset.pl](Pod_testset.md) Random line selection from a text file
  * [lineextract.pl](Pod_lineextract.md) Extract lines from a text file based on line numbers file
  * [heldextract.pl](Pod_heldextract.md) Extract complement lines from a text file based on line numbers file

# MT System Evaluation #
  * [genEvalTemplate.pl](Pod_genEvalTemplate.md) Generate template XML file for NIST BLEU scorer