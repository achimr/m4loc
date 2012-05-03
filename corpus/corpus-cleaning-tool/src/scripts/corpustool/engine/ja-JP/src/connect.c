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
 * $Id: connect.c,v 1.1.1.1 2007/03/13 07:40:10 masayu-a Exp $
 */

#include "chadic.h"

#define CHA_LINEMAX 8192

static int tbl_num;		/* 連接表のサイズ */
static int tbl_num_goi;		/* 連接表の語彙の数 */
static int i_num;		/* 連接行列の行 */
static int j_num;		/* 連接行列の列 */
static rensetu_pair_t *rensetu_tbl;
static connect_rule_t *connect_mtr;

/*
 * rensetu table
 */
static int
cmp_pair(rensetu_pair_t * pair1, rensetu_pair_t * pair2)
{
    int ret;

    /*
     * 見出し語 surface form 
     */
    if (pair1->goi == NULL && pair2->goi != NULL)
	return 1;
    if (pair1->goi != NULL && pair2->goi == NULL)
	return -1;

    /*
     * 品詞分類 POS 
     */
    if ((ret = pair1->hinsi - pair2->hinsi) != 0)
	return ret;

    /*
     * 活用型 Conjugation type 
     */
    if ((ret = pair1->type - pair2->type) != 0)
	return ret;

    /*
     * 見出し語 surface form 
     */
    if (pair1->goi != NULL && pair2->goi != NULL)
	if ((ret = strcmp(pair1->goi, pair2->goi)) != 0)
	    return ret;

    /*
     * 活用形 Conjugation form 
     */
    if ((ret = pair1->form - pair2->form) != 0)
	return ret;

    return pair1->index - pair2->index;
}

static char *
cha_numtok(char *s, int *valp)
{
    int minus = 0;

    while (*s == ' ')
	s++;
    if (*s == '-') {
	minus = 1;
	s++;
    }
    if (*s < '0' || *s > '9')
	cha_exit_file(1, "illegal format");
    for (*valp = 0; *s >= '0' && *s <= '9';
	 *valp = *valp * 10 + *s++ - '0');
    while (*s == ' ')
	s++;

    if (minus)
	*valp = -*valp;

    return s;
}

void
cha_read_table(FILE * fp_out, int dir)
{
    FILE *fp;
    char *filepath;
    char buf[CHA_LINEMAX], *s;
    int i, val, cell_num;

    fp = cha_fopen_grammar(TABLE_FILE, "r", 1, dir, &filepath);

    if (fp_out != NULL)
	fprintf(fp_out, "parsing %s\n", filepath);

    Cha_lineno_error = ++Cha_lineno;
    fscanf(fp, "%d\n", &cell_num);
    rensetu_tbl =
	(rensetu_pair_t *) cha_malloc(sizeof(rensetu_pair_t) * cell_num);

    tbl_num = 0;
    for (i = 0; i < cell_num; i++) {
	Cha_lineno_error = ++Cha_lineno;
	if (fgets(buf, sizeof(buf), fp) == NULL)
	    cha_exit_file(1, "illegal format");
	Cha_lineno_error = ++Cha_lineno;
	if (fgets(s = buf, sizeof(buf), fp) == NULL)
	    cha_exit_file(1, "illegal format");
	s = cha_numtok(s, &val);
	rensetu_tbl[i].i_pos = val;
	s = cha_numtok(s, &val);
	rensetu_tbl[i].j_pos = val;
	if (!tbl_num && val < 0)
	    tbl_num = i;
	buf[strlen(buf) - 1] = '\0';
	if (*s >= '0' && *s <= '9') {
	    s = cha_numtok(s, &val);
	    rensetu_tbl[i].index = i;
	    rensetu_tbl[i].hinsi = val;
	    s = cha_numtok(s, &val);
	    rensetu_tbl[i].type = val;
	    s = cha_numtok(s, &val);
	    rensetu_tbl[i].form = val;
	    if (*s == '*') {
		rensetu_tbl[i].goi = NULL;
	    } else {
		rensetu_tbl[i].goi = cha_strdup(s);
		tbl_num_goi++;
	    }
	}
    }

    if (!tbl_num)
	tbl_num = cell_num;

    fclose(fp);
}

static int
find_table(lexicon_t * mrph, rensetu_pair_t * pair)
{
    int ret;

    /*
     * 品詞分類 POS 
     */
    if ((ret = mrph->pos - pair->hinsi) != 0)
	return ret;
    /*
     * 活用型 Conjugation type 
     */
    if ((ret = mrph->inf_type - pair->type) != 0)
	return ret;

    /*
     * 見出し語 surface form 
     */
    if (pair->goi && (ret = strcmp(mrph->headword, pair->goi)))
	return ret;

    /*
     * 活用語ならば、活用形の1番とマッチ
     */
    if (mrph->inf_type)
	return 1 - pair->form;
    return 0;
}

/* if an error occurs, this function returns 0, else returns 1 */
int
cha_check_table(lexicon_t * mrph)
{
    rensetu_pair_t *ret;

    if (rensetu_tbl[0].hinsi == 0)
	qsort(rensetu_tbl, tbl_num, sizeof(rensetu_pair_t),
	      (int (*)()) cmp_pair);

    ret = (rensetu_pair_t *)
	bsearch(mrph, rensetu_tbl, tbl_num_goi,
		sizeof(rensetu_pair_t), (int (*)()) find_table);
    if (ret) {
	mrph->con_tbl = ret->index;
	return 1;
    }

    ret = (rensetu_pair_t *)
	bsearch(mrph, rensetu_tbl + tbl_num_goi, tbl_num - tbl_num_goi,
		sizeof(rensetu_pair_t), (int (*)()) find_table);
    if (ret) {
	mrph->con_tbl = ret->index;
	return 1; /* if no error, return 1 */
    }

    /*
     * error
     */
    cha_exit_file(-1, "no morpheme in connection table\n");
    return 0;
}

int
cha_check_table_for_undef(int hinsi)
{
    int i;

    for (i = 0; i < tbl_num; i++)
	if (rensetu_tbl[i].hinsi == hinsi)
	    if (!rensetu_tbl[i].goi)
		return i;

    return -1;
}

/*
 * rensetu matrix
 */
void
cha_read_matrix(FILE * fp_out)
{
    FILE *fp;
    char *filepath;
    int i, j, cost, next;
    char buf[CHA_LINEMAX], *s;

    fp = cha_fopen_grammar(MATRIX_FILE, "r", 1, 1, &filepath);

    if (fp_out != NULL)
	fprintf(fp_out, "parsing %s", filepath);

    Cha_lineno_error = ++Cha_lineno;
    fscanf(fp, "%d %d\n", &i_num, &j_num);
    connect_mtr = (connect_rule_t *)
	cha_malloc(sizeof(connect_rule_t) * i_num * j_num);

    next = 0;
    for (i = 0; i < i_num; i++) {
	Cha_lineno_error = ++Cha_lineno;
	if (fgets(s = buf, sizeof(buf), fp) == NULL)
	    cha_exit_file(1, "illegal format");
	for (j = 0; j < j_num;) {
	    int nval;
	    if (*s == 'o') {
		s = cha_numtok(s + 1, &nval);
		next = cost = 0;
	    } else {
		s = cha_numtok(s, &next);
		if (*s++ != ',')
		    cha_exit_file(1, "illegal format");
		s = cha_numtok(s, &cost);
		if (*s == 'x')
		    s = cha_numtok(s + 1, &nval);
		else
		    nval = 1;
	    }
	    while (nval-- > 0) {
		connect_mtr[i * j_num + j].next = next;
		connect_mtr[i * j_num + j].cost = cost;
		j++;
	    }
	}
    }
    fclose(fp);
}

int
cha_check_automaton(int state, int con, int undef_con_cost, int *costp)
{
    connect_rule_t *cr;
#if 0
    printf("[%d:%d:%d]\n", state, con, rensetu_tbl[con].j_pos);
    fflush(stdout);
#endif
    cr = &connect_mtr[state * j_num + rensetu_tbl[con].j_pos];
    *costp = cr->cost;
    if (*costp == 0)
	*costp = undef_con_cost;
    else
	(*costp)--;

#ifdef DEBUG
    printf("[state:%d,con:%d,newcon:%d] ", state, con, cr->next + con);
#endif

    return rensetu_tbl[cr->next + con].i_pos;
}
