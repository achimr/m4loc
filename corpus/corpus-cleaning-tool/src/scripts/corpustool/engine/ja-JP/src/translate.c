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
 * $Id: translate.c,v 1.1.1.1 2007/03/13 07:40:10 masayu-a Exp $
 */

#include "config.h"

#include <stdlib.h>
#include <stdio.h>
#include <limits.h>

#ifdef HAVE_IO_H
#include <io.h>
#endif

#include "chadic.h"
#include "chalib.h"
#include "literal.h"
#include "dartsdic.h"

#define MRPH_WEIGHT_MAX USHRT_MAX

int dump_dic(lexicon_t *lexies, FILE *output[], da_build_t *builder);

/*
static void
dump_lex(lexicon_t *lex, char *indent)
{
    fprintf(stderr, "%sheadw:\t '%s'\n", indent, lex->headword);
    fprintf(stderr, "%sread:\t '%s'\n", indent, lex->reading);
    fprintf(stderr, "%spron:\t '%s'\n", indent, lex->pron);
    fprintf(stderr, "%sbase:\t '%s'\n", indent, lex->base);
    fprintf(stderr, "%sPOS:\t %d\n", indent, lex->pos);
    fprintf(stderr, "%sitype:\t %d\n", indent, lex->inf_type);
    fprintf(stderr, "%siform:\t %d\n", indent, lex->inf_form);
    fprintf(stderr, "%sweight:\t %d\n", indent, lex->weight);
    fprintf(stderr, "%scon_t:\t %d\n", indent, lex->con_tbl);
    fprintf(stderr, "%sinfo:\t '%s'\n\n", indent, lex->info);
    lex++;

    if (lex->pos > 0)
	dump_lex(lex, "\t");
}
*/

static int
err_msg(char *msg, chasen_cell_t *cell)
{
    if (Cha_lineno == 0)
        ;       /* do nothing */
    else if (Cha_lineno == Cha_lineno_error)
        fprintf(stderr, "%d: ", Cha_lineno);
    else
        fprintf(stderr, "%d-%d: ", Cha_lineno_error, Cha_lineno);

    fprintf(stderr, "`%s' %s\n", cha_s_tostr(cell), msg);
    return -1;
}

static int
get_string(chasen_cell_t *cell, char *dist, int length)
{
    char *string = NULL;
    int len;

    string = s_atom_val(cell);
    len = strlen(string);
    if (len > length) {
	return err_msg("is too long", cell);
    }
    memcpy(dist, string, len + 1);

    return len;
}

static int
parse_headword(chasen_cell_t *cell, int default_weight, lexicon_t *lex)
{
    chasen_cell_t *headword;

    if (atomp(cell)) {
	headword = cell;
	lex->weight = (unsigned short)default_weight;
    } else if (atomp(cha_car(cell))) {
	headword = cha_car(cell);
	if (nullp(cha_cdr(cell)))
	    lex->weight = (unsigned short)default_weight;
	else if (!atomp(cha_car(cha_cdr(cell))))
	    return err_msg("has invalid form", cell);
	else {
	    int weight;
	    weight = (int)(atof(s_atom_val(cha_car(cha_cdr(cell))))
			   * MRPH_DEFAULT_WEIGHT);
	    if (weight < 0) {
		weight = 0;
		return err_msg(": weight must be between 0 and 6553.5", cell);
	    } else if (weight > MRPH_WEIGHT_MAX) {
		weight = MRPH_WEIGHT_MAX;
		return err_msg(": weight must be between 0 and 6553.5", cell);
	    }
	    lex->weight = (unsigned short)weight;
	}
    } else {
	return err_msg("has invalid form", cell);
    }
    if (get_string(headword, lex->headword, MIDASI_LEN) < 0)
	return -1;

    return lex->weight;
}

static int
stem(char *string, char *ending)
{
    int string_len, ending_len;

    if (!string[0])
	return 0;

    string_len = strlen(string);
    ending_len = strlen(ending);

    if (string_len < ending_len || 
	strcmp(string + string_len - ending_len, ending))
	return err_msg(":ending conflicts headword", cha_tmp_atom(ending));

    string[string_len - ending_len] = '\0';

    return string_len - ending_len;
}

static int
parse_lexicon(chasen_cell_t *entry, lexicon_t *lexies, int pos, int weight)
{
    chasen_cell_t *cell, *cdr;
    int stat = 0;

    memset(lexies, 0, sizeof(lexicon_t));
    lexies[1].pos = 0;
    lexies[0].pos = pos;
    lexies[0].weight = weight;
    lexies[0].base = lexies[0].info = "";
    lexies[0].reading_len = lexies[0].pron_len = -1;

    if (atomp(entry))
	return err_msg("is not list", entry);

    for (cell = cha_car(entry), cdr = cha_cdr(entry); !nullp(cell);
	 cell = cha_car(cdr), cdr = cha_cdr(cdr)) {
	char *pred;
	chasen_cell_t *val;

	if (atomp(cell))
	    return err_msg("is not list", entry);
	pred = s_atom_val(cha_car(cell));
	val = cha_car(cha_cdr(cell));
	if (cha_litmatch(pred, 1, STR_POS)) {
	    lexies[0].pos = cha_get_nhinsi_id(val);
	} else if (cha_litmatch(pred, 1, STR_WORD)) {
	    stat = parse_headword(val, weight, lexies);
	} else if (cha_litmatch(pred, 1, STR_READING)) {
	    stat = get_string(val, lexies[0].reading, MIDASI_LEN * 2);
	    lexies[0].reading_len = strlen(lexies[0].reading);
	} else if (cha_litmatch(pred, 1, STR_PRON)) {
	    stat = get_string(val, lexies[0].pron, MIDASI_LEN * 2);
	    lexies[0].pron_len = strlen(lexies[0].pron);
	} else if (cha_litmatch(pred, 1, STR_BASE)) {
	    lexies[0].base = s_atom_val(val);
	} else if (cha_litmatch(pred, 1, STR_CTYPE)) {
	    lexies[0].inf_type = cha_get_type_id(s_atom_val(val));
	} else if (cha_litmatch(pred, 1, STR_CFORM)) {
	    lexies[0].inf_form = cha_get_form_id(s_atom_val(val),
						 lexies[0].inf_type);
	} else if (cha_litmatch(pred, 2, STR_INFO1, STR_INFO2)) {
	    lexies[0].info = s_atom_val(val);
	} else if (cha_litmatch(pred, 1, STR_COMPOUND)) {
	    chasen_cell_t *head, *tail;
	    lexicon_t *lex = lexies + 1;
	    for (head = val, tail = cha_cdr(cha_cdr(cell));
		 !nullp(head);
		 head = cha_car(tail), tail = cha_cdr(tail))
		stat = parse_lexicon(head, lex++, pos, 0);
	    if (lexies[0].inf_type > 0 && lexies[0].inf_form == 0 &&
		lexies[0].inf_type != lex[-1].inf_type)
		stat = err_msg(": conjugation type is different from that of the compound word", entry);
	} else {
	    stat = err_msg("is not defined", cha_car(cell));
	}
	if (stat < 0)
	    return -1;
    }

    if (cha_check_table(lexies) <= 0)
	return err_msg("is invalid connection", cell);

    if (lexies[0].inf_type > 0) {
	if (lexies[0].inf_form == 0) {
	    kform_t *basic_form;
	    basic_form = &Cha_form[lexies[0].inf_type]
		[Cha_type[lexies[0].inf_type].basic];
	    stat = stem(lexies[0].headword, basic_form->gobi);
	    if (lexies[0].reading_len >= 0) {
		stat = stem(lexies[0].reading, basic_form->ygobi);
		lexies[0].reading_len = strlen(lexies[0].reading);
	    }
	    if (lexies[0].pron_len >= 0) {
		stat = stem(lexies[0].pron, basic_form->pgobi);
		lexies[0].pron_len = strlen(lexies[0].pron);
	    }
	    lexies[0].stem_len = strlen(lexies[0].headword);
	} else {
	    kform_t *form;
	    form = &Cha_form[lexies[0].inf_type][lexies[0].inf_form];
	    lexies[0].stem_len = -1;
	    if (!lexies[0].base[0])
		return err_msg("needs base form", 
			       cha_tmp_atom(lexies[0].headword));
	}

    } else {
	lexies[0].inf_type = 0;
	lexies[0].inf_form = 0;
	lexies[0].stem_len = strlen(lexies[0].headword);
    }

    return stat;
}
    
static int 
parse_dic(FILE *input, FILE *output[], da_build_t *builder)
{
    chasen_cell_t *cell;
    lexicon_t lexicons[256]; /* XXX */
    int pos = -1;
    int weight = MRPH_WEIGHT_MAX;
    int stat = 0;

    while (!cha_s_feof(input)) {
	cell = cha_s_read(input);
	if (atomp(cell))
	    return err_msg("is not list", cell);
	if (atomp(cha_car(cell))) {
	    char *s = s_atom_val(cha_car(cell));
	    if (cha_litmatch(s, 1, STR_POS))
		pos = cha_get_nhinsi_id(cha_car(cha_cdr(cell)));
	    else if (cha_litmatch(s, 1, STR_DEF_POS_COST))
		weight = atoi(s_atom_val(cha_car(cha_cdr(cell))));
	    else
		stat = err_msg("is not defined", cell);
	} else {
	    if (pos < 0)
		stat = err_msg("POS is not specified", NULL);
	    else if (parse_lexicon(cell, lexicons, pos, weight) < 0)
		stat = -1;
	    else {
		if (lexicons[0].inf_type > 0 &&
		    lexicons[0].inf_form > 0) {
		    lexicons[0].con_tbl += lexicons[0].inf_form - 1;
		}
		stat = dump_dic(lexicons, output, builder);
	    }
	}
	cha_s_free(cell);
    }

    return stat;
}

static int
translate(char *path, FILE *output[], da_build_t *builder)
{
    FILE *input;
    int stat;

    input = cha_fopen(path, "r", 1);
    fprintf(stderr, "%s\n", path);
    stat = parse_dic(input, output, builder);
    fclose(input);

    return stat;
}

static int
translate_files(char *pathes[], FILE *output[], da_build_t *builder)
{
#if defined HAVE_IO_H && !defined __CYGWIN__
    struct _finddata_t fileinfo;
    long handle;
#endif
    int num = 0;

    fputs("parsing dictionaries...\n", stderr);

    for (; *pathes != NULL; pathes++) {
#if defined HAVE_IO_H && !defined __CYGWIN__
	handle = _findfirst(*pathes, &fileinfo);
	if (handle < 0)
	    break;
	do {
	    if (translate(fileinfo.name, output, builder) < 0)
		return -1;
	    num++;
	} while (!_findnext(handle, &fileinfo));
	_findclose(handle);
#else
	if (translate(*pathes, output, builder) < 0)
	    return -1;
	num++;
#endif
    }

    return num;
}


static void
usage(void)
{
    fputs("usage: makeda [-i encode] output dicfile...\n", stderr);
    exit(1);
}

int
main(int argc, char *argv[])
{
    char *dic_base;
    int c;
    FILE *output[3];
    char path[PATH_MAX];
    da_build_t *builder;
    cha_mmap_t *tmpfile;

    cha_set_progpath(argv[0]);

    cha_set_encode("");
    while ((c = cha_getopt(argv, "i:", stderr)) != EOF) {
	switch (c) {
	case 'i':
	    cha_set_encode(Cha_optarg);
	    break;
	default:
	    usage();
	}
    }
    argv += Cha_optind;
    argc -= Cha_optind;

    if (argc < 2)
	usage();

    dic_base = argv[0];
    argv++;

    cha_read_grammar(stderr, 1, 2);
    cha_read_katuyou(stderr, 2);
    cha_read_table(stderr, 2);

    snprintf(path, PATH_MAX, "%s.da", dic_base);
    builder = da_build_new(path);
    snprintf(path, PATH_MAX, "%s.dat", dic_base);
    output[0] = cha_fopen(path, "wb", 1);
    snprintf(path, PATH_MAX, "%s.lex", dic_base);
    output[1] = cha_fopen(path, "wb", 1);
    snprintf(path, PATH_MAX, "%s.tmp", dic_base);
    output[2] = cha_fopen(path, "wb", 1);

    if (translate_files(argv, output, builder) < 0)
	exit(1);
    fclose(output[2]);

    tmpfile = cha_mmap_file(path);
    da_build_dump(builder, cha_mmap_map(tmpfile), output[1]);
    cha_munmap_file(tmpfile);

    remove(path);

    return EXIT_SUCCESS;
}
