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
 * $Id: parse.c,v 1.3 2007/03/25 11:02:53 kazuma-t Exp $
 */

#include "chalib.h"
#include "literal.h"
#include "tokenizer.h"
#include "dartsdic.h"

#define is_spc(c)    ((c)==' '||(c)=='\t')

cha_block_t *Cha_mrph_block;
path_t *Cha_path = NULL;
int Cha_path_num;

#define new_mrph() cha_block_new_item(Cha_mrph_block)
#define nth_mrph(n) ((mrph_t*)cha_block_get_item(Cha_mrph_block,(n)))
#define mrph_last_idx() (cha_block_num(Cha_mrph_block)-1)

/*
 * malloc_chars
 */
#define CHUNK_SIZE 512
#define CHA_MALLOC_SIZE (1024 * 64)
#define malloc_char(n)     malloc_chars(1, n)
#define malloc_short(n)    malloc_chars(2, n)
#define malloc_int(n)      malloc_chars(4, n)
#define free_chars()       malloc_chars(0, 0)
static void *
malloc_chars(int size, int nitems)
{
    static char *buffer_ptr[CHUNK_SIZE];
    static int buffer_ptr_num = 0;
    static int buffer_idx = CHA_MALLOC_SIZE;

    if (nitems == 0) {
	/*
	 * free 
	 */
	if (buffer_ptr_num > 0) {
	    while (buffer_ptr_num > 1)
		free(buffer_ptr[--buffer_ptr_num]);
	    buffer_idx = 0;
	}
	return NULL;
    } else {
	if (size > 1) {
	    /*
	     * size で割りきれる値に補正する 
	     */
	    buffer_idx += size - (buffer_idx & (size - 1));
	    nitems *= size;
	}

	if (buffer_idx + nitems >= CHA_MALLOC_SIZE) {
	    if (buffer_ptr_num == CHUNK_SIZE)
		cha_exit(1, "Can't allocate memory");
	    buffer_ptr[buffer_ptr_num++] = cha_malloc(CHA_MALLOC_SIZE);
	    buffer_idx = 0;
	}

	buffer_idx += nitems;
	return buffer_ptr[buffer_ptr_num - 1] + buffer_idx - nitems;
    }
}

static void *
malloc_free_block(void *ptr, int *nblockp, int size, int do_free)
{
    if (do_free) {
	/*
	 * free and malloc one block 
	 */
	if (*nblockp > 1) {
	    free(ptr);
	    *nblockp = 0;
	}
	if (*nblockp == 0)
	    ptr = malloc_free_block(ptr, nblockp, size, 0);
    } else {
	/*
	 * realloc one block larger 
	 */
	if (*nblockp == 0)
	    ptr = malloc(size * ++*nblockp);
	else {
	    ptr = realloc(ptr, size * ++*nblockp);
	}
    }

    return ptr;
}

#define malloc_path()  malloc_free_path(0)
#define free_path()    malloc_free_path(1)
static int
malloc_free_path(int do_free)
{
    static int nblock = 0;

    Cha_path = malloc_free_block((void *) Cha_path, &nblock,
				 sizeof(path_t) * CHA_PATH_NUM, do_free);

    return Cha_path == NULL;
}

static int
collect_mrphs_for_pos(cha_lat_t *lat)
{
    int i, j;

    j = 0;
    if (lat->cursor == 0) { /* new sentence */
	lat->path_idx[j++] = 0;
    } else {
	for (i = lat->head_path; i < Cha_path_num; i++) {
	    if (Cha_path[i].end <= lat->cursor) {
		if (i == lat->head_path)
		    lat->head_path++;
		if (Cha_path[i].end == lat->cursor)
		    lat->path_idx[j++] = i;
	    }
	}
    }
    lat->path_idx[j] = -1;

    return j;
}

typedef struct _path_cost_t {
    int min_cost;
    short min_cost_no;
    short state;
    short num;
    int cost[PATH1_NUM];
    int pno[PATH1_NUM];
} path_cost_t;

static int
classify_path(path_cost_t *pcost, int *p_idx, int con_tbl)
{
    int i, pno;
    int pcost_num = 0;

    pcost[0].state = -1;

    /*
     * 次状態の値でパスを分類する 
     */
    for (i = 0; (pno = p_idx[i]) >= 0; i++) {
	int con_cost, cost;
	int next_state;
	int pcostno;

	next_state = cha_check_automaton
	    (Cha_path[pno].state, con_tbl, Cha_con_cost_undef, &con_cost);
	if (con_cost == -1)
	    continue;

	cost = Cha_path[pno].cost + con_cost * Cha_con_cost_weight;

	/*
	 * どの pcost に属するか調べる 
	 */
	for (pcostno = 0; pcostno < pcost_num; pcostno++)
	    if (next_state == pcost[pcostno].state)
		break;
	if (pcostno < pcost_num) {
	    /*
	     * tricky: when Cha_cost_width is -1, ">-1" means ">=0" 
	     */
	    if (cost - pcost[pcostno].min_cost > Cha_cost_width)
		continue;
	} else {
	    /*
	     * 新しい pcost を作る 
	     */
	    pcost_num++;
	    pcost[pcostno].num = 0;
	    pcost[pcostno].state = next_state;
	    pcost[pcostno].min_cost = INT_MAX;
	}

	/*
	 * pcost に登録 
	 */
	if (Cha_cost_width < 0) {
	    pcost[pcostno].min_cost = cost;
	    pcost[pcostno].pno[0] = pno;
	} else {
	    pcost[pcostno].cost[pcost[pcostno].num] = cost;
	    pcost[pcostno].pno[pcost[pcostno].num] = pno;
	    if (cost < pcost[pcostno].min_cost) {
		pcost[pcostno].min_cost = cost;
		pcost[pcostno].min_cost_no = pcost[pcostno].num;
	    }
	    pcost[pcostno].num++;
	}
    }
    return pcost_num;
}

static int
check_connect(cha_lat_t *lat, int m_num)
{
    path_cost_t pcost[PATH1_NUM];
    int pcost_num, pcostno;
    int mrph_cost;
    mrph_t *new_mrph;

    new_mrph = nth_mrph(m_num);

    pcost_num = classify_path(pcost, lat->path_idx, new_mrph->con_tbl);
    if (pcost_num == 0)
	return TRUE;

    /*
     * 形態素コスト 
     */
    if (new_mrph->is_undef) {
	mrph_cost = Cha_undef_info[new_mrph->is_undef - 1].cost
	    + Cha_undef_info[new_mrph->is_undef - 1].cost_step
	    * new_mrph->headword_len / 2;
    } else {
	mrph_cost = Cha_hinsi[new_mrph->posid].cost;
    }
    mrph_cost *= new_mrph->weight * Cha_mrph_cost_weight;

    for (pcostno = 0; pcostno < pcost_num; pcostno++) {
	if (Cha_cost_width < 0) {
	    Cha_path[Cha_path_num].best_path = pcost[pcostno].pno[0];
	} else {  /* コスト幅におさまっているパスを抜き出す */
	    int i;
	    int npath = 0;
	    int path[PATH1_NUM];
	    int cost_ceil = pcost[pcostno].min_cost + Cha_cost_width;

	    Cha_path[Cha_path_num].best_path = 
		pcost[pcostno].pno[pcost[pcostno].min_cost_no];
	    for (i = 0; i < pcost[pcostno].num; i++)
		if (pcost[pcostno].cost[i] <= cost_ceil)
		    path[npath++] = pcost[pcostno].pno[i];
	    path[npath++] = -1;
	    memcpy(Cha_path[Cha_path_num].path = malloc_int(npath),
		   path, sizeof(int) * npath);
	}

	Cha_path[Cha_path_num].cost = pcost[pcostno].min_cost + mrph_cost;
	Cha_path[Cha_path_num].mrph_p = m_num;
	Cha_path[Cha_path_num].state = pcost[pcostno].state;
	Cha_path[Cha_path_num].start = lat->offset;
	Cha_path[Cha_path_num].end = lat->offset + new_mrph->headword_len;

	if (++Cha_path_num % CHA_PATH_NUM == 0 && malloc_path())
	    return FALSE;
    }

    return TRUE;
}

#define DIC_BUFSIZ 256

static int
register_mrphs(cha_lat_t *lat, darts_t* da, char *strings, long index)
{
    mrph_t *new_mrph;
    da_lex_t lex_data[DIC_BUFSIZ]; /* XXX */
    int nlex, i, len;

    nlex = da_get_lex(da, index, lex_data, &len);
    for (i = 0; i < nlex; i++) {
	new_mrph = new_mrph();
	new_mrph->headword = strings;
	new_mrph->headword_len = len;
	new_mrph->is_undef = 0;
	new_mrph->darts = da;
	memcpy(new_mrph, lex_data + i, sizeof(da_lex_t));
	check_connect(lat, mrph_last_idx());
    }

    return mrph_last_idx();
}

static int
lookup_dic(cha_lat_t *lat, char *string, int len)
{
    int dic_no;
    long index_buffer[DIC_BUFSIZ]; /* XXX */

    for (dic_no = 0; dic_no < Da_ndicfile; dic_no++) {
	int i;
	int num =
	    da_lookup(Da_dicfile[dic_no], string, len,
		      index_buffer, DIC_BUFSIZ);
	for (i = 0; i < num; i++)
	    register_mrphs(lat, Da_dicfile[dic_no], string, index_buffer[i]);
    }

    return mrph_last_idx();
}

static int
exact_lookup_dic(cha_lat_t *lat, char *string, int len)
{
    int dic_no;
    long index;

    for (dic_no = 0; dic_no < Da_ndicfile; dic_no++) {
	if ((index = da_exact_lookup(Da_dicfile[dic_no], string, len)) < 0)
	    continue;
	register_mrphs(lat, Da_dicfile[dic_no], string, index);
    }

    return mrph_last_idx();
}

static int
register_undef_mrph(cha_lat_t *lat, char *string, int len, int no)
{
    mrph_t *mrph = new_mrph();

    mrph->posid = Cha_undef_info[no].hinsi;
    mrph->inf_type = 0;
    mrph->inf_form = 0;
    mrph->weight = MRPH_DEFAULT_WEIGHT;
    mrph->con_tbl = Cha_undef_info[no].con_tbl;

    mrph->headword = string;
    mrph->headword_len = len;
    mrph->is_undef = no + 1;
    mrph->darts = NULL;

    check_connect(lat, mrph_last_idx());

    return mrph_last_idx();
}

static int
set_unknownword(cha_lat_t *lat, char *string, int len,
		int head_mrph_idx, int tail_mrph_idx)
{
    int i;

    for (i = head_mrph_idx; i <= tail_mrph_idx; i++) {
	/*
	 * 未定義語と同じ長さの単語が辞書にあれば未定義語を追加しない 
	 */
	if (Cha_con_cost_undef > 0 &&
	    nth_mrph(i)->headword_len == len) {
	    len = 0;
	    break;
	}
    }

    if (len > 0) {
	int no;
	for (no = 0; no < Cha_undef_info_num; no++)
	    register_undef_mrph(lat, string, len, no);
    }

    return mrph_last_idx();
}

static int
register_bos_eos(void)
{
    mrph_t *mrph = new_mrph();

    memset(mrph, 0, sizeof(mrph_t));
    mrph->weight = MRPH_DEFAULT_WEIGHT;
    mrph->headword = "";
    mrph->darts = NULL;

    return mrph_last_idx();
}

static int
register_specified_morph(cha_lat_t *lat, cha_seg_t *seg)
{
    mrph_t *mrph;
    da_lex_t lex_data[DIC_BUFSIZ]; /* XXX */
    int dic_no, i, nlex, len;
    long index;
    int is_found = 0;
    unsigned char *text = lat->text + lat->offset;

    for (dic_no = 0; dic_no < Da_ndicfile; dic_no++) {
	if ((index =
	     da_exact_lookup(Da_dicfile[dic_no], text, seg->len)) < 0)
	    continue;

	nlex = da_get_lex(Da_dicfile[dic_no], index, lex_data, &len);
	for (i = 0; i < nlex; i++) {
	    if (lex_data[i].posid == seg->posid &&
		lex_data[i].inf_type == seg->inf_type &&
		lex_data[i].inf_form == seg->inf_form) {
		mrph = new_mrph();
		mrph->headword = text;
		mrph->headword_len = seg->len;
		mrph->is_undef = 0;
		mrph->darts = Da_dicfile[dic_no];
		memcpy(mrph, lex_data + i, sizeof(da_lex_t));
		mrph->weight = 0; /* ??? */
		is_found = 1;
		check_connect(lat, mrph_last_idx());
	    }
	}
    }

    if (!is_found) {
	mrph = new_mrph();
	mrph->headword = text;
	mrph->headword_len = seg->len;
	mrph->posid = seg->posid;
	mrph->is_undef = 0;
	mrph->inf_type = seg->inf_type;
	mrph->inf_form = seg->inf_form;
	mrph->con_tbl = 
	    cha_check_table_for_undef(seg->posid); /* ??? */
	mrph->weight = 0;
	mrph->darts = NULL;
	check_connect(lat, mrph_last_idx());
    }

    return mrph_last_idx();
}

static void
set_anno(cha_lat_t *lat, cha_seg_t *seg)
{
    mrph_t *mrph;
    int index;

    mrph = new_mrph();
    index = mrph_last_idx();
    mrph->headword = lat->text + lat->offset;
    mrph->headword_len = seg->len;
    mrph->con_tbl = seg->anno_no; /* XXX */
    mrph->is_undef = 0;
    if (Cha_anno_info[seg->anno_no].format) {
	mrph->posid = Cha_undef_info[0].hinsi;
    } else {
	mrph->posid = Cha_anno_info[seg->anno_no].hinsi;
    }
    mrph->inf_type = mrph->inf_form = mrph->weight = 0;

    mrph->darts = NULL;
    mrph->dat_index = -1; /* XXX */
    
    if (lat->last_anno >= 0) {
	mrph_t *a = nth_mrph(lat->last_anno);
	a->dat_index = index; /* XXX */
    } else
	lat->anno = index;

    lat->last_anno = index;
}

int
cha_parse_bos(cha_lat_t *lat)
{
    static int path0 = -1;

    lat->offset = lat->cursor = 0;
    lat->anno = lat->last_anno = -1;
    lat->head_path = 1;

    cha_block_clear(Cha_mrph_block);

    free_chars();
    free_path();

    Cha_path[0].start = Cha_path[0].end = 0;
    Cha_path[0].path = &path0;
    Cha_path[0].cost = 0;
    Cha_path[0].mrph_p = 0;
    Cha_path[0].state = 0;

    Cha_path_num = 1;
    register_bos_eos();

    return 0;
}

int
cha_parse_eos(cha_lat_t *lat)
{
    int last_idx;

    collect_mrphs_for_pos(lat);
    last_idx = register_bos_eos();
    if (check_connect(lat, last_idx) == FALSE) {
	fprintf(stderr, "Error: Too many morphs\n");
	return -1;
    }
    lat->len = lat->offset;

    return lat->offset;
}

int
cha_parse_segment(cha_lat_t *lat, cha_seg_t *seg)
{
    int last_idx;
    int l, mblen = 0;
    char *text;
    int mrph_idx;

    text = lat->text + lat->offset;
    memcpy(text, seg->text, seg->len);

    switch (seg->type) {
    case SEGTYPE_UNSPECIFIED:
	mrph_idx = mrph_last_idx() + 1;
	if (collect_mrphs_for_pos(lat)) {
	    last_idx = exact_lookup_dic(lat, text, seg->len);
	    set_unknownword(lat, text, seg->len, mrph_idx, last_idx);
	}
	lat->cursor = (lat->offset += seg->len);
	break;
    case SEGTYPE_MORPH:
	if (collect_mrphs_for_pos(lat)) {
	    if (seg->is_undef) {
		int no;
		for (no = 0; no < Cha_undef_info_num; no++)
		    register_undef_mrph(lat, text, seg->len, no);
	    } else
		register_specified_morph(lat, seg);
	}
	lat->cursor = (lat->offset += seg->len);
	break;
    case SEGTYPE_NORMAL:
	for (l = 0; l < seg->len;
	     l += mblen, lat->cursor = (lat->offset += mblen)) {
	    unsigned char *t;

	    if (!collect_mrphs_for_pos(lat))
		continue;
	    t = text + l;
	    mrph_idx = mrph_last_idx() + 1;
	    last_idx = lookup_dic(lat, t, seg->len - l);
	    last_idx = set_unknownword(lat, t, seg->char_type[l],
				       mrph_idx, last_idx);
	    mblen = cha_tok_mblen(Cha_tokenizer, t, seg->len - l);
	}
	break;
    case SEGTYPE_ANNOTATION:
	set_anno(lat, seg);
	lat->offset += seg->len;
	break;
    default:
	last_idx = mrph_last_idx();
	lat->cursor += seg->len;
	break;
    }

    return lat->cursor;
}
