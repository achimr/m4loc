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
 * $Id: grammar.c,v 1.1.1.1 2007/03/13 07:40:10 masayu-a Exp $
 */

#include "chadic.h"
#include "literal.h"

hinsi_t Cha_hinsi[HINSI_MAX];

/*
 * make_hinsi
 */
static int
make_hinsi(chasen_cell_t * cell, int mother, int idx)
{
    char *name, *s;
    int depth, i, d;
    short *path;

    if (idx >= HINSI_MAX)
	cha_exit_file(1, "too many (over %d) parts of speech", HINSI_MAX);

    /*
     * path 
     */
    depth = Cha_hinsi[mother].depth + 1;
    path = cha_malloc(sizeof(short) * (depth + 1));
    memcpy(path, Cha_hinsi[mother].path, sizeof(short) * depth);
    path[depth - 1] = idx;
    path[depth] = 0;
    Cha_hinsi[idx].depth = depth;
    Cha_hinsi[idx].path = path;

    /*
     * hinsi name and katsuyou 
     */
    name = cha_s_atom(cha_car(cell));
#if 0
    printf("%2d:%*s%s\n", depth, depth * 2, "", name);
    fflush(stdout);
#endif
    /*
     * 品詞の二重登録のチェック あまりきれいな方法ではない 
     */
    for (i = 0; Cha_hinsi[mother].daughter[i + 1]; i++) {
	if (!strcmp(Cha_hinsi[Cha_hinsi[mother].daughter[i]].name, name))
	    cha_exit_file(1, "hinsi `%s' is already defined", name);
    }

    s = name + strlen(name) - 1;
    if (Cha_hinsi[mother].kt == 1 || *s == '%') {
	Cha_hinsi[idx].kt = 1;
	if (*s == '%')
	    *s = '\0';
    }

    if (*name == '\0')
	cha_exit_file(1, "an empty string for hinsi name");

    Cha_hinsi[idx].name = cha_strdup(name);
#if 0
    cha_s_print(stdout, cha_car(cell));
    printf("[%d,%d,%s]\n", mother, idx, name);
    fflush(stdout);
#endif

    cell = cha_cdr(cell);
    if (nullp(cell)) {
	static short daughter0 = 0;
	Cha_hinsi[idx++].daughter = &daughter0;
    } else {
	short daughter[256];
	int ndaughter = 0;
	d = idx + 1;
	/*
	 * 品詞の二重登録のチェックのため一時的に daughter を代入 
	 */
	Cha_hinsi[idx].daughter = daughter;
	for (; !nullp(cell); cell = cha_cdr(cell)) {
	    daughter[ndaughter++] = d;
	    daughter[ndaughter] = 0;
	    d = make_hinsi(cha_car(cell), idx, d);
	}
	daughter[ndaughter++] = 0;
	Cha_hinsi[idx].daughter = cha_malloc(sizeof(short) * ndaughter);
	memcpy(Cha_hinsi[idx].daughter, daughter,
	       sizeof(short) * ndaughter);
	idx = d;
    }

    return idx;
}

/*
 * cha_read_class
 */
void
cha_read_class(FILE * fp)
{
    static short path0 = 0;
    chasen_cell_t *cell1;
    short daughter[256];
    int idx, ndaughter;

    /*
     * root node 
     */
    Cha_hinsi[0].path = &path0;
    Cha_hinsi[0].depth = 0;
    Cha_hinsi[0].kt = 0;
    Cha_hinsi[0].name = CHA_LIT(STR_BOS_EOS);

    idx = 1;
    ndaughter = 0;
    /*
     * 品詞の二重登録のチェックのため一時的に daughter を代入 
     */
    Cha_hinsi[0].daughter = daughter;
    while (!cha_s_feof(fp)) {
	if (!nullp(cell1 = cha_s_read(fp))) {
	    daughter[ndaughter++] = idx;
	    daughter[ndaughter] = 0;
	    idx = make_hinsi(cell1, 0, idx);
	}
    }

    daughter[ndaughter++] = 0;
    Cha_hinsi[0].daughter = cha_malloc(sizeof(short) * ndaughter);
    memcpy(Cha_hinsi[0].daughter, daughter, sizeof(short) * ndaughter);

    /*
     * last node 
     */
    Cha_hinsi[idx].name = NULL;
}

/*
 * cha_match_nhinsi - cellのwildcard表現がhinsiとマッチしているかどうか
 */
int
cha_match_nhinsi(chasen_cell_t * cell, int hinsi)
{
    char *name;
    short *path;

    for (path = Cha_hinsi[hinsi].path; !nullp(cell);
	 path++, cell = cha_cdr(cell)) {
	name = cha_s_atom(cha_car(cell));
	if (!*path) {
	    /*
	     * cell の方が長いときは、最後の連続した "*" は無視する
	     * これにより cell:(副詞 *) と hinsi:副詞 がマッチする
	     * chasenrc の品詞コストの指定で (副詞 *) などが使われている
	     * connect.cha でも使われる可能性がある
	     */
	    if (strcmp(name, "*"))
		return 0;
	    /*
	     * これ以降は *path の値が 0 になるようにする 
	     */
	    path--;
	} else {
	    if (strcmp(name, "*") && strcmp(name, Cha_hinsi[*path].name))
		return 0;
	}
    }
    /*
     * cell が hinsi よりも粗い分類ならマッチ 
     */
    return 1;
}

/*
 * cha_read_grammar - read GRAMMAR_FILE and set Class[][]
 *
 * inputs:
 *	dir - 0: read from current directory
 *	      1: read from grammar directory
 *	      2: read from current directory or grammar directory
 */
void
cha_read_grammar(FILE * fp_out, int ret, int dir)
{
    FILE *fp;
    char *filepath;

    fp = cha_fopen_grammar(GRAMMAR_FILE, "r", ret, dir, &filepath);
    if (fp_out != NULL)
	fprintf(fp_out, "parsing %s\n", filepath);

    cha_read_class(fp);

    fclose(fp);
}
