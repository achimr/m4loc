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
 * $Id: chalib.c,v 1.3 2007/03/25 11:57:27 kazuma-t Exp $
 */

#include "chalib.h"
#include "dartsdic.h"
#include "literal.h"
#include "tokenizer.h"

#define CHA_NAME       "ChaSen"

#define STR_UNSPECIFIED "UNSPEC"
#define STR_ANNOTATION "ANNO"

darts_t *Da_dicfile[DIC_NUM];
int Da_ndicfile = 0;

int Cha_cost_width = -1;
enum cha_lang Cha_lang = CHASEN_LANG_JA;
#if defined _WIN32
enum cha_encode Cha_encode = CHASEN_ENCODE_SJIS;
#else
enum cha_encode Cha_encode = CHASEN_ENCODE_EUCJP;
#endif

static int cost_width0;

static char dadic_filename[DIC_NUM][PATH_MAX];

static int opt_show = 'b', opt_form = 'f', opt_ja, opt_cmd;
static char *opt_form_string;

/*
 *  cha_version()
 */
void
cha_version(FILE * fp)
{
    if (!fp)
	return;

    fprintf(fp,
	    "%s version %s (c) 1996-2007 Nara Institute of Science and Technology\n",
	    CHA_NAME, VERSION);
    fprintf(fp, "Grammar files are in ChaSen's new v-gram format.\n");
}

/*
 * cha_set_opt_form()
 */
void
cha_set_opt_form(char *format)
{
    char *f;

    /*
     * -[fecdv] 
     */
    if (format &&
	format[0] == '-' && strchr("fecdv", format[1])
	&& format[2] == '\0') {
	opt_form = format[1];
	format = NULL;
    }

    if (format == NULL) {
	if (opt_form == 'd' || opt_form == 'v')
	    opt_show = 'm';
	switch (opt_form) {
	case 'd':
	    opt_form_string =
		"morph(%pi,%ps,%pe,%pc,'%m','%U(%y)','%M',%U(%P'),NIL,%T0,%F0,'%I0',%c,[%ppc,],[%ppi,])";
	    break;
	case 'v':
	    opt_form_string =
		"%pb%3pi %3ps %3pe %5pc %m\t%U(%y)\t%U(%a)\t%M\t%U(%P-) NIL %T0 %F0 %I0 %c %ppi, %ppc,\n";
	    break;
	case 'f':
	    opt_form_string = "%m\t%y\t%M\t%U(%P-)\t%T \t%F \n";
	    break;
	case 'e':
	    opt_form_string = "%m\t%U(%y)\t%M\t%P- %h %T* %t %F* %f\n";
	    break;
	case 'c':
	    opt_form_string = "%m\t%y\t%M\t%h %t %f\n";
	    break;
	}
	return;
    }

    /*
     * format string 
     */
    opt_form_string = format;
    /*
     * opt_form_string = cha_convert_escape(cha_strdup(format), 1); 
     */

    f = opt_form_string + strlen(opt_form_string);
    if (f[-1] == '\n')
	opt_form = 'F';
    else
	opt_form = 'W';
}

/*
 * cha_set_language()
 */
void
cha_set_language(char *langstr)
{
    Cha_lang = CHASEN_LANG_JA;

    if (langstr[0] == 'j') {
	Cha_lang = CHASEN_LANG_JA;
    } else if (langstr[0] == 'e') {
	Cha_lang = CHASEN_LANG_EN;
    }
}

/*
 * cha_set_cost_width()
 */
void
cha_set_cost_width(int cw)
{
    cost_width0 = cw * MRPH_DEFAULT_WEIGHT;

    /*
     * 最適解以外も表示するときは Cha_cost_width を生かす 
     */
    Cha_cost_width = opt_show == 'b' ? -1 : cost_width0;
}

/*
 * chasen_getopt_argv - initialize and read options
 *
 * return value:
 *   0 - ok
 *   1 - error
 */
int
chasen_getopt_argv(char **argv, FILE * fp)
{
    int c;

    /*
     * read -r option 
     */
    Cha_optind = 0;
    while ((c = cha_getopt_chasen(argv, fp)) != EOF) {
	switch (c) {
	case 'i':
	    cha_set_encode(Cha_optarg);
	    break;
	case 'r':
	    /*
	     * chasenrc file 
	     */
	    cha_set_rcpath(Cha_optarg);
	    break;
	case '?':
	    return 1;
	}
    }

    /*
     * initialize if not done 
     */
    if (!Cha_undef_info_num)
	cha_init();

    /*
     * read options 
     */
    Cha_optind = 0;
    while ((c = cha_getopt_chasen(argv, fp)) != EOF) {
	switch (c) {
	case 'b':
	case 'm':
	case 'p':
	    opt_show = c;
	    break;
	case 'd':
	case 'v':
	case 'f':
	case 'e':
	case 'c':
	    opt_form = c;
	    cha_set_opt_form(NULL);
	    break;
	case 'F':
	    cha_set_opt_form(cha_convert_escape
			     (cha_strdup(Cha_optarg), 0));
	    break;
	case 'L':
	    cha_set_language(Cha_optarg);
	    break;
	case 'w':		/* コスト幅の指定 */
	    cha_set_cost_width(atoi(Cha_optarg));
	    break;
	case 'O':
	    Cha_output_iscompound = *Cha_optarg == 'c';
	    break;
	case 'l':
	    cha_set_output(stdout);
	    switch (*Cha_optarg) {
	    case 'p':
		/*
		 * display the list of Cha_hinsi table 
		 */
		cha_print_hinsi_table();
		exit(0);
		break;
	    case 't':
		cha_print_ctype_table();
		exit(0);
		break;
	    case 'f':
		cha_print_cform_table();
		exit(0);
		break;
	    default:
		break;
	    }
	    break;
	case 'j':
	    opt_ja = 1;
	    break;
	case 'C':
	    opt_cmd = 1;
	    break;
#if 0				/* not necessary */
	case '?':
	    return 1;
#endif
	}
    }

    /*
     * 最適解以外も表示するときは Cha_cost_width を生かす 
     */
    Cha_cost_width = opt_show == 'b' ? -1 : cost_width0;

    return 0;
}

/*
 * parse a string and output to fp or str
 *
 * return value:
 *     0 - ok / no result / too many morphs
 *     1 - quit
 */
static int
chasen_sparse_main(char *input, FILE *output)
{
    char *crlf;
    cha_lat_t lat;
    cha_seg_t seg;
    /*
     * initialize if not done 
     */
    if (!Cha_undef_info_num)
	cha_init();
    if (!opt_form_string)
	cha_set_opt_form(NULL);

    cha_set_output(output);

    if (input[0] == '\0') {
	cha_print_bos_eos(opt_form);
	return 0;
    }

    /*
     * parse a sentence and print 
     */
    while (*input) {
	int c = 0, len, cursor;
	if ((crlf = strpbrk(input, "\r\n")) == NULL)
	    len = strlen(input);
	else {
	    len = crlf - input;
	    c = *crlf;
	    *crlf = '\0';
	}
	cha_print_reset();

	cursor = 0;
	cha_parse_bos(&lat);
	while (cursor < len) {
	    seg.text = input + cursor;
	    seg.anno_no = -1;
	    seg.len = cha_tok_parse(Cha_tokenizer, seg.text, seg.char_type,
				    len - cursor, &seg.anno_no);
	    if (seg.anno_no >= 0)
		seg.type = SEGTYPE_ANNOTATION;
	    else
		seg.type = SEGTYPE_NORMAL;
	    cha_parse_segment(&lat, &seg);
	    cursor += seg.len;
	}
	cha_parse_eos(&lat);
	cha_print_path(&lat, opt_show, opt_form, opt_form_string);

	if (crlf == NULL)
	    break;
	if (c == '\r' && crlf[1] == '\n')
	    input = crlf + 2;
	else
	    input = crlf + 1;
    }

    return 0;
}

/*
 * read from file/str, parse, and write to file
 * 
 * return value:
 *     0 - ok / no result / too many morphs
 *     1 - quit / eof
 */
/*
 * file -> file
 */
int
chasen_fparse(FILE * fp_in, FILE * fp_out)
{
    char line[CHA_INPUT_SIZE];

    if (cha_fgets(line, sizeof(line), fp_in) == NULL)
	return 1;

    return chasen_sparse_main(line, fp_out);
}
/*
 * string -> file
 */
int
chasen_sparse(char *str_in, FILE * fp_out)
{
    int rc;
    char *euc_str;

    euc_str = cha_malloc(strlen(str_in) + 1);
    cha_jistoeuc(str_in, euc_str);
    rc = chasen_sparse_main(euc_str, fp_out);
    free(euc_str);

    return rc;
}

static int
set_normal(cha_seg_t *seg)
{
    seg->type = SEGTYPE_NORMAL;
    cha_tok_parse(Cha_tokenizer, seg->text, seg->char_type,
		  seg->len, NULL);

    return seg->len;
}

static int
seg_tokenize(unsigned char *line, cha_seg_t *seg)
{
    int len;
    int i;

    len = 0;
    seg->text = line;
    while (line[len] != '\t' && line[len] != '\0')
	len++;
    seg->len = len;
    seg->posid = seg->inf_type = seg->inf_form = 0;

    if (line[len] == '\0')
	return set_normal(seg);

    /* skip reading and base form */
    for (i = 0; i < 2; i++) {
	len++;
	while (line[len] != '\t' && line[len] != '\0')
	    len++;
	if (line[len] == '\0')
	    return set_normal(seg);
    }

    line += len + 1;
    if (strcmp(line, STR_UNSPECIFIED) == 0) {
	seg->type = SEGTYPE_UNSPECIFIED;
	seg->char_type[0] = seg->len;
    } else if (strcmp(line, STR_ANNOTATION) == 0) {
	seg->type = SEGTYPE_ANNOTATION;
	cha_tok_parse(Cha_tokenizer, seg->text, seg->char_type,
		      seg->len, &seg->anno_no);
	seg->char_type[0] = seg->len;
    } else { /* read POS */
	char *pos[256], *itype;
	char *l = line;

	seg->type = SEGTYPE_MORPH;
	seg->char_type[0] = seg->len;
	if ((l = strchr(l, '\t')) != NULL) {
	    *l++ = '\0';
	    itype = l;
	    if ((l = strchr(l, '\t')) != NULL) {
		*l++ = '\0';
		seg->inf_type = cha_get_type_id(itype);
		seg->inf_form = cha_get_form_id(l, seg->inf_type);
	    } else {
		fprintf(stderr, "invalid format: %s\n", line);
		return -1;
	    }
	}
	i = 0;
	pos[i++] = l = line;
	while ((l = strchr(l, '-')) != NULL) {
	    *l++ = '\0';
	    pos[i++] = l;
	}
	pos[i] = NULL;
	if (cha_litmatch(pos[0], 3, STR_UNKNOWN_WORD,
			 STR_UNKNOWN_WORD1, STR_UNKNOWN_WORD2))
	    seg->is_undef = 1;
	else {
	    seg->is_undef = 0;
	    seg->posid = cha_get_nhinsi_str_id(pos);
	}
    }
    
    return seg->len;
}

static int
strip(unsigned char *s)
{
    int len = strlen(s);

    if (s[len - 1] == '\n')
	s[len-- - 1] = '\0';

    while (len > 0 && s[len - 1] == '\t')
        s[len-- - 1] = '\0';

    return len;
}


int
chasen_parse_segments(FILE *input, FILE *output)
{
    cha_lat_t lat;
    unsigned char buf[CHA_INPUT_SIZE]; /* XXX */
    cha_seg_t seg;
    int is_eos = 1;

    if (!Cha_undef_info_num)
	cha_init();
    if (!opt_form_string)
	cha_set_opt_form(NULL);

    cha_set_output(output);

    while (fgets(buf, CHA_INPUT_SIZE, input) != NULL) {
	strip(buf);
	if (is_eos) {
	    cha_print_reset();
	    cha_parse_bos(&lat);
	    is_eos = 0;
	}
	if (!buf[0] || cha_litmatch(buf, 2, STR_EOS, STR_BOS_EOS)) {
	    /* EOS */
	    cha_parse_eos(&lat);
	    cha_print_path(&lat, opt_show, opt_form, opt_form_string);
	    is_eos = 1;
	    continue;
	}
	if (seg_tokenize(buf, &seg) < 0) {
	    fprintf(stderr, "invalid format: %s\n", buf);
	    continue;
	}
	cha_parse_segment(&lat, &seg);
    }
    if (!is_eos) {
        cha_parse_eos(&lat);
	cha_print_path(&lat, opt_show, opt_form, opt_form_string);
    }

    return lat.len;
}

/*
 * read from file/str, parse, and output to string
 * 
 * return value: string
 *     !NULL - ok / no result / too many morphs
 *     NULL - quit / eof
 */

/*
 * file -> string
 */
char *
chasen_fparse_tostr(FILE * fp_in)
{
    char line[CHA_INPUT_SIZE];

    if (cha_fgets(line, sizeof(line), fp_in) == NULL)
	return NULL;

    if (chasen_sparse_main(line, NULL))
	return NULL;

    return cha_get_output();
}

/*
 * string -> string
 */
char *
chasen_sparse_tostr(char *str_in)
{
    char *euc_str;

    euc_str = cha_malloc(strlen(str_in) + 1);
    cha_jistoeuc(str_in, euc_str);

    if (chasen_sparse_main(euc_str, NULL))
	return NULL;

    free(euc_str);

    return cha_get_output();
}

char *
cha_fgets(char *s, int n, FILE * fp)
{
    if (opt_ja)
	return cha_jfgets(s, n, fp);
    else
	return cha_fget_line(s, n, fp);
}

static void
set_dic_filename(char *filename, size_t len, char *s)
{
#ifdef PATHTYPE_MSDOS
    if (*s == PATH_DELIMITER || *s && s[1] == ':')
	strncpy(filename, s, len);
#else
    if (*s == PATH_DELIMITER)
	strncpy(filename, s, len);
#endif /* PATHTYPE_MSDOS */
    else
	snprintf(filename, len, "%s%s", cha_get_grammar_dir(), s);
}

void
cha_read_dadic(chasen_cell_t * cell)
{
    int num;
    char da_filename[PATH_MAX];
    char lex_filename[PATH_MAX];
    char dat_filename[PATH_MAX];

    if (dadic_filename[0][0])
	return;

    for (num = 0; !nullp(cell); num++, cell = cha_cdr(cell)) {
	if (num >= DIC_NUM)
	    cha_exit_file(1, "too many Darts dictionary files");
	set_dic_filename(dadic_filename[num], PATH_MAX,
			 cha_s_atom(cha_car(cell)));

	snprintf(da_filename, PATH_MAX, "%s.da", dadic_filename[num]);
	snprintf(lex_filename, PATH_MAX, "%s.lex", dadic_filename[num]);
	snprintf(dat_filename, PATH_MAX, "%s.dat", dadic_filename[num]);
	Da_dicfile[num] = da_open(da_filename,
				  lex_filename, dat_filename);
    }
    Da_ndicfile = num;
}
