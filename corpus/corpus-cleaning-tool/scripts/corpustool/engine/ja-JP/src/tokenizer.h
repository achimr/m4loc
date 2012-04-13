/*
 * $Id: tokenizer.h,v 1.1.1.1 2007/03/13 07:40:10 masayu-a Exp $
 */

#ifndef __TOKENIZER_H__
#define __TOKENIZER_H__

#include "chalib.h"

/* for language */
enum cha_lang {
    CHASEN_LANG_JA,
    CHASEN_LANG_EN
};

typedef struct _chasen_tok_t chasen_tok_t;
struct _chasen_tok_t {
    enum cha_lang lang;
    enum cha_encode encode;
    anno_info *anno;
    int (*mblen)(unsigned char*, int);
    int (*get_char_type)(chasen_tok_t*,unsigned char*, int);
    int (*char_type_parse)(chasen_tok_t*,int,int*,int);
};

extern enum cha_lang Cha_lang;
extern chasen_tok_t *Cha_tokenizer;

chasen_tok_t *cha_tok_new(int, int);
void cha_tok_delete(chasen_tok_t*);
int cha_tok_parse(chasen_tok_t*, unsigned char*, char*, int, int*);
int cha_tok_mblen(chasen_tok_t*,unsigned char*,int);
void cha_tok_set_annotation(chasen_tok_t*, anno_info*);
int cha_tok_is_jisx0208_latin(chasen_tok_t*, int, int);

#endif /*__TOKENIZER_H__ */
