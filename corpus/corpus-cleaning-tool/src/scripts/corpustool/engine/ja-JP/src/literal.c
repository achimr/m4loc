/*
 * Copyright (c) 2003 Nara Institute of Science and Technology
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. The name Nara Institute of Science and Technology may not be used to
 *    endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY Nara Institute of Science and Technology 
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A 
 * PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE Nara Institute
 * of Science and Technology BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * $Id: literal.c,v 1.3 2007/03/25 13:24:39 kazuma-t Exp $
 */

#include <stdarg.h>
#include <stdlib.h>
#include <string.h>
#include <iconv.h>
#include "literal.h"
#include "chadic.h"

#define JSTR_BOS             "文頭"
#define ESTR_BOS             "BOS"
#define JSTR_EOS             "文末"
#define ESTR_EOS             "EOS"
#define ESTR_BOS_EOS         "BOS/EOS"

/* cforms.cha */
#define JSTR_BASE_FORM_STR   "基本形"
#define ESTR_BASE_FORM_STR1  "BASEFORM"
#define ESTR_BASE_FORM_STR2  "STEMFORM"
#define JSTR_BASE_FORM       "基本形"
#define ESTR_BASE_FORM1      "BASEFORM"
#define ESTR_BASE_FORM2      "STEMFORM"

/* *.dic */
#define JSTR_DEF_POS_COST  "デフォルト品詞コスト"
#define ESTR_DEF_POS_COST  "DEF_POS_COST"
#define JSTR_MRPH          "形態素"
#define ESTR_MRPH          "MORPH"
#define JSTR_POS           "品詞"
#define ESTR_POS           "POS"
#define JSTR_WORD          "見出し語"
#define ESTR_WORD          "LEX"
#define JSTR_READING       "読み"
#define ESTR_READING       "READING"
#define JSTR_BASE          "原形"
#define ESTR_BASE          "BASE"
#define JSTR_PRON          "発音"
#define ESTR_PRON          "PRON"
#define JSTR_CTYPE         "活用型"
#define ESTR_CTYPE         "CTYPE"
#define JSTR_CFORM         "活用形"
#define ESTR_CFORM         "CFORM"
#define JSTR_INFO1         "付加情報"
#define JSTR_INFO2         "意味情報"
#define ESTR_INFO          "INFO"
#define JSTR_COMPOUND      "複合語"
#define ESTR_COMPOUND      "COMPOUND"
#define JSTR_SEG           "構成語"
#define ESTR_SEG           "SEG"
#define JSTR_CONN_ATTR     "連接属性"

/* chasenrc */
#define ESTR_ENCODE         "ENCODE"
#define JSTR_GRAM_FILE      "文法ファイル"
#define ESTR_GRAM_FILE      "GRAMMAR"
#define JSTR_UNKNOWN_WORD1  "未知語"
#define JSTR_UNKNOWN_WORD2  "未定義語"
#define ESTR_UNKNOWN_WORD   "UNKNOWN"
#define JSTR_UNKNOWN_WORD   JSTR_UNKNOWN_WORD1
#define JSTR_UNKNOWN_POS1   "未知語品詞"
#define JSTR_UNKNOWN_POS2   "未定義語品詞"
#define ESTR_UNKNOWN_POS    "UNKNOWN_POS"
#define JSTR_SPACE_POS      "空白品詞"
#define ESTR_SPACE_POS      "SPACE_POS"
#define JSTR_ANNOTATION     "注釈"
#define ESTR_ANNOTATION     "ANNOTATION"
#define JSTR_POS_COST       "品詞コスト"
#define ESTR_POS_COST       "POS_COST"
#define JSTR_CONN_WEIGHT    "連接コスト重み"
#define ESTR_CONN_WEIGHT    "CONN_WEIGHT"
#define JSTR_MRPH_WEIGHT    "形態素コスト重み"
#define ESTR_MRPH_WEIGHT    "MORPH_WEIGHT"
#define JSTR_COST_WIDTH     "コスト幅"
#define ESTR_COST_WIDTH     "COST_WIDTH"
#define JSTR_DEF_CONN_COST  "未定義連接コスト"
#define ESTR_DEF_CONN_COST  "DEF_CONN_COST"
#define JSTR_COMPOSIT_POS      "連結品詞"
#define ESTR_COMPOSIT_POS      "COMPOSIT_POS"
#define JSTR_OUTPUT_COMPOUND   "複合語出力"
#define ESTR_OUTPUT_COMPOUND   "OUTPUT_COMPOUND"
#define ESTR_DA_FILE       "DADIC"
#define JSTR_OUTPUT_FORMAT  "出力フォーマット"
#define ESTR_OUTPUT_FORMAT  "OUTPUT_FORMAT"
#define JSTR_LANG           "言語"
#define ESTR_LANG           "LANG"
#define JSTR_DELIMITER      "区切り文字"
#define ESTR_DELIMITER      "DELIMITER"
#define JSTR_BOS_STR        "BOS文字列"
#define ESTR_BOS_STR        "BOS_STRING"
#define JSTR_EOS_STR        "EOS文字列"
#define ESTR_EOS_STR        "EOS_STRING"

#define LIT_MAX 512

char *cha_literal[][3] = {
    { JSTR_BOS, ESTR_BOS, NULL },
    { JSTR_EOS, ESTR_EOS, NULL },
    { ESTR_BOS_EOS, ESTR_BOS_EOS, NULL },
    { JSTR_BASE_FORM_STR, ESTR_BASE_FORM_STR1, NULL },
    { JSTR_BASE_FORM_STR, ESTR_BASE_FORM_STR2, NULL },
    { JSTR_BASE_FORM, ESTR_BASE_FORM1, NULL },
    { JSTR_BASE_FORM, ESTR_BASE_FORM2, NULL },
    { JSTR_DEF_POS_COST, ESTR_DEF_POS_COST, NULL },
    { JSTR_MRPH, ESTR_MRPH, NULL },
    { JSTR_POS, ESTR_POS, NULL },
    { JSTR_WORD, ESTR_WORD, NULL },
    { JSTR_READING, ESTR_READING, NULL },
    { JSTR_BASE, ESTR_BASE, NULL },
    { JSTR_PRON, ESTR_PRON, NULL },
    { JSTR_CTYPE, ESTR_CTYPE, NULL },
    { JSTR_CFORM, ESTR_CFORM, NULL },
    { JSTR_INFO1, ESTR_INFO, NULL },
    { JSTR_INFO2, ESTR_INFO, NULL },
    { JSTR_COMPOUND, ESTR_COMPOUND, NULL },
    { JSTR_SEG, ESTR_SEG, NULL },
    { JSTR_CONN_ATTR, "", NULL },
    { ESTR_ENCODE, ESTR_ENCODE, NULL },
    { JSTR_GRAM_FILE, ESTR_GRAM_FILE, NULL },
    { JSTR_UNKNOWN_WORD1, ESTR_UNKNOWN_WORD, NULL },
    { JSTR_UNKNOWN_WORD1, ESTR_UNKNOWN_WORD, NULL },
    { JSTR_UNKNOWN_WORD2, ESTR_UNKNOWN_WORD, NULL },
    { JSTR_UNKNOWN_POS1, ESTR_UNKNOWN_POS, NULL },
    { JSTR_UNKNOWN_POS2, ESTR_UNKNOWN_POS, NULL },
    { JSTR_SPACE_POS, ESTR_SPACE_POS, NULL },
    { JSTR_ANNOTATION, ESTR_ANNOTATION, NULL },
    { JSTR_POS_COST, ESTR_POS_COST, NULL },
    { JSTR_CONN_WEIGHT, ESTR_CONN_WEIGHT, NULL },
    { JSTR_MRPH_WEIGHT, ESTR_MRPH_WEIGHT, NULL },
    { JSTR_COST_WIDTH, ESTR_COST_WIDTH, NULL },
    { JSTR_DEF_CONN_COST, ESTR_DEF_CONN_COST, NULL },
    { JSTR_COMPOSIT_POS, ESTR_COMPOSIT_POS, NULL },
    { JSTR_OUTPUT_COMPOUND, ESTR_OUTPUT_COMPOUND, NULL },
    { ESTR_DA_FILE, ESTR_DA_FILE, NULL },
    { JSTR_OUTPUT_FORMAT, ESTR_OUTPUT_FORMAT, NULL },
    { JSTR_LANG, ESTR_LANG, NULL },
    { JSTR_DELIMITER, ESTR_DELIMITER, NULL },
    { JSTR_BOS_STR, ESTR_BOS_STR, NULL },
    { JSTR_EOS_STR, ESTR_EOS_STR, NULL },
    { NULL, NULL, NULL}
};

static char *encode_list[] = {
    ICONV_EUCJP, /* CHASEN_ENCODE_EUCJP */
    ICONV_SJIS,  /* CHASEN_ENCODE_SJIS */
    ICONV_88591, /* CHASEN_ENCODE_ISO8859 */
    "UTF-8",  /* CHASEN_ENCODE_UTF8 */
};

static void
copy_literal(void)
{
    int i = 0;
    do {
	cha_literal[i][2] = cha_literal[i][0];
    } while (cha_literal[++i][0] != NULL);
}

static void
jlit_init(const char *encode)
{
    iconv_t cd;
    int i;

    if (encode == NULL)
	encode = encode_list[Cha_encode];

    if (!strcmp(encode, ICONV_EUCJP)) {
	copy_literal();
	return;
    }

    cd = iconv_open(encode, ICONV_EUCJP);
    if (cd == (iconv_t)-1) {
	fprintf(stderr, "%s is invalid encoding scheme, ", encode);
	fprintf(stderr, "will use 'EUC-JP'\n");
	copy_literal();
	return;
    }

    i = 0;
    do {
	char *in_p = cha_literal[i][0];
	char buf[LIT_MAX];
	char *out_p = buf;
	size_t in_size = strlen(in_p) + 1;
	size_t out_size = sizeof(buf);
	size_t len;

	do {
	    if (iconv(cd, &in_p, &in_size, &out_p, &out_size)
		== (size_t)-1) {
		perror("iconv");
		exit(1);
	    }
	} while (in_size != 0);
	len = strlen(buf);
	/* XXX this memory will leak */
	cha_literal[i][2] = cha_malloc(len + 1);
	memcpy(cha_literal[i][2], buf, len + 1);
    } while (cha_literal[++i][0] != NULL);
    iconv_close(cd);
}

void
cha_set_encode(char *encodestr)
{
    switch (encodestr[0]) {
    case 'e':
	Cha_encode = CHASEN_ENCODE_EUCJP;
	break;
    case 's':
	Cha_encode = CHASEN_ENCODE_SJIS;
	break;
    case 'w':
    case 'u':
	Cha_encode = CHASEN_ENCODE_UTF8;
	break;
    case 'a':
	Cha_encode = CHASEN_ENCODE_ISO8859;
	break;
    }
    jlit_init(encode_list[Cha_encode]);
}

int
cha_litmatch(const char *string, int num, ...)
{
    va_list ap;
    enum cha_lit_str lit;

    va_start(ap, num);
    for (; num > 0; num--) {
	lit = va_arg(ap, enum cha_lit_str);
	if (!strcmp(string, cha_literal[lit][1]) ||
	    !strcmp(string, cha_literal[lit][2]))
	    return 1;
    }
    va_end(ap);

    return 0;
}
