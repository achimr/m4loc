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
 * $Id: dumpdic.c,v 1.1.1.1 2007/03/13 07:40:10 masayu-a Exp $
 */

#include <stdlib.h>
#include <stdio.h>
#include <limits.h>

#include "chadic.h"
#include "dartsdic.h"

#define NO_COMPOUND LONG_MAX

static long
dump_dat(lexicon_t *lex, FILE *datfile, long compound)
{
    long index;
    da_dat_t dat;

    index = ftell(datfile);
    dat.stem_len = lex->stem_len;
    dat.reading_len = lex->reading_len;
    dat.pron_len = lex->pron_len;
    dat.base_len = strlen(lex->base);
    dat.info_len = strlen(lex->info);
    dat.compound = compound;
    if (fwrite(&dat, sizeof(dat), 1, datfile) != 1)
	cha_exit_perror("datfile");

    if (fputs(lex->reading, datfile) < 0 || fputc('\0', datfile) < 0 ||
	fputs(lex->pron, datfile) < 0 || fputc('\0', datfile) < 0 ||
	fputs(lex->base, datfile) < 0 || fputc('\0', datfile) < 0 ||
	fputs(lex->info, datfile) < 0 || fputc('\0', datfile) < 0)
	cha_exit_perror("datfile");

    if (ftell(datfile) % 2)
	if (fputc('\0', datfile) < 0)
	    cha_exit_perror("datfile");

    if (index < 0)
	cha_exit_perror("datfile");

    return index;
}

static long
dump_lex(da_lex_t *lex, FILE *output)
{
    long index;

    index = ftell(output);
    if (fwrite(lex, sizeof(da_lex_t), 1, output) != 1)
	cha_exit_perror("lexfile");

    return index;
}

static da_lex_t *
assemble_lex(da_lex_t *lex, lexicon_t *entry, long dat_index)
{
    lex->posid = entry->pos;
    lex->inf_type = entry->inf_type;
    lex->inf_form = entry->inf_form;
    lex->weight = entry->weight;
    lex->con_tbl = entry->con_tbl;
    lex->dat_index = dat_index;

    return lex;
}

static long
dump_compound(lexicon_t *entries, FILE *lexfile, FILE *datfile)
{
    int i;
    short has_next;
    long compound_index = ftell(lexfile);
    long marker = 0L;

    for (i = 1; entries[i].pos; i++) {
	short hw_len = strlen(entries[i].headword);
	da_lex_t lex;
	long dat_index;

	has_next = 1;
	dat_index = dump_dat(entries + i, datfile, NO_COMPOUND);
	assemble_lex(&lex, entries + i, dat_index);
	fwrite(&hw_len, sizeof(short), 1, lexfile);
	marker = ftell(lexfile);
	if (fwrite(&has_next, sizeof(short), 1, lexfile) != 1)
	    cha_exit_perror("lexfile");
	dump_lex(&lex, lexfile);
    }
    has_next = 0;
    fseek(lexfile, marker, SEEK_SET);
    if (fwrite(&has_next, sizeof(short), 1, lexfile) != 1)
	cha_exit_perror("lexfile");
    fseek(lexfile, 0L, SEEK_END);

    return compound_index;
}

int
dump_dic(lexicon_t *entries, FILE *output[], da_build_t *builder)
{
    FILE *datfile = output[0];
    FILE *lexfile = output[1];
    FILE *tmpfile = output[2];
    long dat_index, lex_index;
    da_lex_t lex;
    long compound = NO_COMPOUND;

    if (entries[1].pos)
	compound = dump_compound(entries, lexfile, datfile);

    dat_index = dump_dat(entries, datfile, compound);

    assemble_lex(&lex, entries, dat_index);
    if (entries[0].inf_type == 0 || entries[0].inf_form > 0) {
	lex_index = dump_lex(&lex, tmpfile);
	da_build_add(builder, entries[0].headword, lex_index);
    } else {
	int stem_len = strlen(entries[0].headword);
	unsigned short con_tbl = lex.con_tbl;
	int i;

	for (i = 1; Cha_form[lex.inf_type][i].name; i++) {
	    lex.inf_form = i;
	    lex.con_tbl = con_tbl + i - 1;
	    strcpy(entries[0].headword + stem_len,
		   Cha_form[lex.inf_type][i].gobi);
	    if (!entries[0].headword[0])
		continue;
	    lex_index = dump_lex(&lex, tmpfile);
	    da_build_add(builder, entries[0].headword, lex_index);
	}
    }

    return 0;
}
