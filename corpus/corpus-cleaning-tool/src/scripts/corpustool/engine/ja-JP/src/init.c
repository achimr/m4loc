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
 * $Id: init.c,v 1.2 2007/03/25 13:24:39 kazuma-t Exp $
 */

#include "chalib.h"
#include "dartsdic.h"
#include "literal.h"
#include "tokenizer.h"

/*
 * .chasenrc default values 
 */
#define POS_COST_DEFAULT	1
#define RENSETSU_WEIGHT_DEFAULT	1
#define KEITAISO_WEIGHT_DEFAULT	1
#define COST_WIDTH_DEFAULT	0
#define UNDEF_WORD_DEFAULT	10000

int Cha_con_cost_weight = RENSETSU_WEIGHT_DEFAULT * MRPH_DEFAULT_WEIGHT;
int Cha_con_cost_undef = 0;
int Cha_mrph_cost_weight = KEITAISO_WEIGHT_DEFAULT;

anno_info Cha_anno_info[UNDEF_HINSI_MAX];
undef_info Cha_undef_info[UNDEF_HINSI_MAX];
int Cha_undef_info_num = 0;
int Cha_output_iscompound = 1;

char *Cha_bos_string = "";
char *Cha_eos_string = "EOS\n";

chasen_tok_t *Cha_tokenizer;

static void
read_class_cost(chasen_cell_t * cell)
{
    int hinsi, cost;

    for (; !nullp(cell); cell = cha_cdr(cell)) {
	chasen_cell_t *cell1 = cha_car(cha_car(cell));
	chasen_cell_t *cell2 = cha_cdr(cha_car(cell));
	char *s = cha_s_atom(cha_car(cell1));
	if (cha_litmatch(s, 3, STR_UNKNOWN_WORD,
			 STR_UNKNOWN_WORD1, STR_UNKNOWN_WORD2)) {
	    int i;
	    for (i = 0; i < UNDEF_HINSI_MAX && !nullp(cell2);
		 i++, cell2 = cha_cdr(cell2)) {
		chasen_cell_t *cell3 = cha_car(cell2);
		if (atomp(cell3)) {
		    Cha_undef_info[i].cost = atoi(cha_s_atom(cell3));
		    Cha_undef_info[i].cost_step = 0;
		} else {
		    Cha_undef_info[i].cost =
			atoi(cha_s_atom(cha_car(cell3)));
		    Cha_undef_info[i].cost_step =
			atoi(cha_s_atom(cha_car(cha_cdr(cell3))));
		}
	    }
	    if (Cha_undef_info_num == 0 || Cha_undef_info_num > i)
		Cha_undef_info_num = i;
	} else if (!strcmp(s, "*")) {
	    cost = atoi(cha_s_atom(cha_car(cell2)));
	    for (hinsi = 1; Cha_hinsi[hinsi].name; hinsi++)
		if (Cha_hinsi[hinsi].cost == 0)
		    Cha_hinsi[hinsi].cost = cost;
	} else {
	    int match = 0;
	    cost = atoi(cha_s_atom(cha_car(cell2)));
	    for (hinsi = 1; Cha_hinsi[hinsi].name; hinsi++) {
		if (cha_match_nhinsi(cell1, hinsi)) {
		    Cha_hinsi[hinsi].cost = cost;
		    match = 1;
		}
	    }
	    if (!match)
		cha_exit_file(1, "invalid hinsi name `%s'\n",
			      cha_s_tostr(cell1));
	}
    }

    /*
     * default 
     */
    for (hinsi = 1; Cha_hinsi[hinsi].name; hinsi++)
	if (Cha_hinsi[hinsi].cost == 0)
	    Cha_hinsi[hinsi].cost = POS_COST_DEFAULT;

    /*
     * 文頭 文末 
     */
    Cha_hinsi[0].cost = 0;
}

static void
read_composition(chasen_cell_t * cell)
{
    int composit, pos;
    chasen_cell_t *cell2, *cell3;

    for (; !nullp(cell); cell = cha_cdr(cell)) {
	cell2 = cha_car(cell);
	composit = cha_get_nhinsi_id(cha_car(cell2));
	if (!nullp(cha_cdr(cell2)))
	    cell2 = cha_cdr(cell2);
	for (; !nullp(cell2); cell2 = cha_cdr(cell2)) {
	    cell3 = cha_car(cell2);
	    for (pos = 1; Cha_hinsi[pos].name; pos++)
		if (cha_match_nhinsi(cell3, pos))
		    Cha_hinsi[pos].composit = composit;
	}
    }
}

static void
eval_chasenrc_sexp(chasen_cell_t * cell)
{
    char *cell1_str;
    chasen_cell_t *cell2;

    cell1_str = cha_s_atom(cha_car(cell));
    cell2 = cha_car(cha_cdr(cell));
    if (Cha_errno)
	return;

    if (!strcmp(cell1_str, CHA_LIT(STR_ENCODE)))
        cha_set_encode(cha_s_atom(cell2));

    /*
     * 辞書ファイル 
     */
    if (!strcmp(cell1_str, CHA_LIT(STR_DA_FILE)))
	cha_read_dadic(cha_cdr(cell));
    /*
     * 空白品詞(space pos) 
     */
    else if (cha_litmatch(cell1_str, 1, STR_SPACE_POS)) {
	Cha_anno_info[0].hinsi = cha_get_nhinsi_id(cell2);
    }
    /*
     * 注釈(annotation) 
     */
    else if (cha_litmatch(cell1_str, 1, STR_ANNOTATION)) {
	int i;
	for (i = 1, cell2 = cha_cdr(cell);
	     i < UNDEF_HINSI_MAX && !nullp(cell2);
	     i++, cell2 = cha_cdr(cell2)) {
	    chasen_cell_t *cell3 = cha_car(cell2);
	    chasen_cell_t *cell4;
	    /*
	     * str1, len1 
	     */
	    Cha_anno_info[i].str1 = cha_s_atom(cha_car(cha_car(cell3)));
	    Cha_anno_info[i].len1 = strlen(Cha_anno_info[i].str1);
	    cell4 = cha_car(cha_cdr(cha_car(cell3)));
	    /*
	     * str2, len2 
	     */
	    Cha_anno_info[i].str2 = nullp(cell4) ? "" : cha_s_atom(cell4);
	    Cha_anno_info[i].len2 = strlen(Cha_anno_info[i].str2);
	    /*
	     * hinsi 
	     */
	    cell4 = cha_car(cha_cdr(cell3));
	    if (!nullp(cell4)) {
		if (atomp(cell4)) {
		    /*
		     * format string 
		     */
		    Cha_anno_info[i].format = cha_s_atom(cell4);
		} else {
		    /*
		     * pos 
		     */
		    Cha_anno_info[i].hinsi = cha_get_nhinsi_id(cell4);
		}
	    }
	}
    }
    /*
     * 未知語品詞 
     */
    else if (cha_litmatch(cell1_str, 2,
			  STR_UNKNOWN_POS1, STR_UNKNOWN_POS2)) {
	int i;
	cell2 = cha_cdr(cell);
	for (i = 0; i < UNDEF_HINSI_MAX && !nullp(cell2);
	     i++, cell2 = cha_cdr(cell2)) {
	    Cha_undef_info[i].hinsi = cha_get_nhinsi_id(cha_car(cell2));
	}
	if (Cha_undef_info_num == 0 || Cha_undef_info_num > i)
	    Cha_undef_info_num = i;
    }
    /*
     * 連接コスト重み 
     */
    else if (cha_litmatch(cell1_str, 1, STR_CONN_WEIGHT))
	Cha_con_cost_weight =
	    atoi(cha_s_atom(cell2)) * MRPH_DEFAULT_WEIGHT;
    /*
     * 形態素コスト重み 
     */
    else if (cha_litmatch(cell1_str, 1, STR_MRPH_WEIGHT))
	Cha_mrph_cost_weight = atoi(cha_s_atom(cell2));
    /*
     * コスト幅 
     */
    else if (cha_litmatch(cell1_str, 1, STR_COST_WIDTH))
	cha_set_cost_width(atoi(cha_s_atom(cell2)));
    /*
     * 品詞コスト 
     */
    else if (cha_litmatch(cell1_str, 1, STR_POS_COST))
	read_class_cost(cha_cdr(cell));
    /*
     * 未定義連接コスト 
     */
    else if (cha_litmatch(cell1_str, 1, STR_DEF_CONN_COST))
	Cha_con_cost_undef = (int) atoi(cha_s_atom(cell2));
    /*
     * 連結品詞 
     */
    else if (cha_litmatch(cell1_str, 1, STR_COMPOSIT_POS))
	read_composition(cha_cdr(cell));
    /*
     * 複合語 
     */
    else if (cha_litmatch(cell1_str, 1, STR_OUTPUT_COMPOUND))
	Cha_output_iscompound =
	    cha_litmatch(cha_s_atom(cell2), 1, STR_SEG) ? 0 : 1;
    /*
     * 出力フォーマット 
     */
    else if (cha_litmatch(cell1_str, 1, STR_OUTPUT_FORMAT))
	cha_set_opt_form(cha_s_atom(cell2));
    /*
     * 言語 
     */
    else if (cha_litmatch(cell1_str, 1, STR_LANG))
	cha_set_language(cha_s_atom(cell2));
    /*
     * BOS文字列 
     */
    else if (cha_litmatch(cell1_str, 1, STR_BOS_STR))
	Cha_bos_string = cha_s_atom(cell2);
    /*
     * EOS文字列 
     */
    else if (cha_litmatch(cell1_str, 1, STR_EOS_STR))
	Cha_eos_string = cha_s_atom(cell2);
    /*
     * 区切り文字 
     */
    else if (cha_litmatch(cell1_str, 1, STR_DELIMITER))
	cha_set_jfgets_delimiter(cha_s_atom(cell2));
}

/*
 * cha_read_rcfile_fp()
 */
void
cha_read_rcfile_fp(FILE * fp)
{
    chasen_cell_t *cell;

    while (!cha_s_feof(fp)) {
	cell = cha_s_read(fp);
	if (!Cha_errno)
	    eval_chasenrc_sexp(cell);
    }
}

static void
read_chasenrc(void)
{
    FILE *fp;
    char *rcpath;

    rcpath = cha_get_rcpath();

    fp = cha_fopen(rcpath, "r", 1);
    cha_read_rcfile_fp(fp);
    fclose(fp);

    /*
     * required options 
     */
    if (!Cha_undef_info[0].hinsi)
	cha_exit(1, "%s: UNKNOWN_POS/michigo-hinsi is not specified",
		 cha_get_rcpath());

    if (!Da_ndicfile)
	cha_exit(1, "%s: dictionary is not specified",
		 cha_get_rcpath());
}

/*
 * cha_init - ChaSen's initialization
 */
void
cha_init(void)
{
    int i;

    /*
     * cost width 
     */
    cha_set_cost_width(COST_WIDTH_DEFAULT);

    if (cha_literal[0][2] == NULL)
	cha_set_encode("");

    cha_read_grammar_dir();
    cha_read_grammar(NULL, 1, 1);

    read_chasenrc();

    cha_read_katuyou(NULL, 1);
    cha_read_table(NULL, 1);
    cha_read_matrix(NULL);

    for (i = 0; i < Cha_undef_info_num; i++)
	Cha_undef_info[i].con_tbl =
	    cha_check_table_for_undef(Cha_undef_info[i].hinsi);

    /*
     * initialize the tokenizer
     */
    Cha_tokenizer = cha_tok_new(Cha_lang, Cha_encode);
    cha_tok_set_annotation(Cha_tokenizer, Cha_anno_info);

    Cha_mrph_block = cha_block_new(sizeof(mrph_t), MRPH_NUM);
}
