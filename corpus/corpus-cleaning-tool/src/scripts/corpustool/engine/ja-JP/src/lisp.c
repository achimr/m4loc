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
 * $Id: lisp.c,v 1.2 2007/03/30 00:40:36 masayu-a Exp $
 */

#include "chadic.h"
#include "literal.h"

#define COMMENTCHAR	';'
#define COMMENTCHAR2	'#'
#define BPARENTHESIS	'('
#define EPARENTHESIS	')'
#define NILSYMBOL	"NIL"
#define CELLALLOCSTEP	1024
#define LISPBUFSIZ	8192

#define new_cell()	(cha_cons(NIL, NIL))
#define eq(x, y)	(x == y)

static int c_skip = 0;

/*
 * error_in_lisp
 */
static chasen_cell_t *
error_in_lisp(void)
{
    cha_exit_file(1, "premature end of file or string\n");
    return NIL;
}

void
cha_set_skip_char(int c)
{
    c_skip = c;
}

/*
 * ifnextchar - if next char is <c> return 1, otherwise return 0
 */
#define ifnextchar(fp, ch)  ifnextchar2(fp, ch, 0)
static int
ifnextchar2(FILE * fp, int ch1, int ch2)
{
    int c;

    do {
	c = fgetc(fp);
	if (c == '\n')
	    Cha_lineno++;
    } while (c == ' ' || c == '\t' || c == '\n');

    if (c == EOF)
	return EOF;
    if (c == ch1 || (ch2 && c == ch2))
	return TRUE;
    ungetc(c, fp);
    return FALSE;
}

/*
 * skip comment lines
 */
static int
skip_comment(FILE * fp)
{
    int n, c;

    while ((n = ifnextchar2(fp, (int) COMMENTCHAR, c_skip)) == TRUE) {
	while ((c = fgetc(fp)) != '\n')
	    if (c == EOF)
		return c;
	Cha_lineno++;
    }

    return n;
}

int
cha_s_feof(FILE * fp)
{
    int c;

    if (Cha_lineno == 0)
	Cha_lineno = 1;
    Cha_lineno_error = Cha_lineno;

    for (;;) {
	if (skip_comment(fp) == EOF)
	    return TRUE;
	if ((c = fgetc(fp)) == '\n')
	    Cha_lineno++;
	else if (c == ' ' || c == '\t');
	else {
	    ungetc(c, fp);
	    return FALSE;
	}
    }
}

/*
 * malloc_free_cell()
 *
 */
#define malloc_cell()  malloc_free_cell(0)
#define free_cell()    malloc_free_cell(1)
static chasen_cell_t *
malloc_free_cell(int isfree)
{
    static chasen_cell_t *ptr[1024 * 16];
    static int ptr_num = 0;
    static int idx = CELLALLOCSTEP;

    if (isfree) {
	/*
	 * free 
	 */
	if (ptr_num > 0) {
	    while (ptr_num > 1)
		free(ptr[--ptr_num]);
	    idx = 0;
	}
	return NULL;
    } else {
	if (idx == CELLALLOCSTEP) {
	    if (ptr_num == 1024 * 16)
		cha_exit(1, "Can't allocate memory");
	    ptr[ptr_num++] = cha_malloc(sizeof(chasen_cell_t) * idx);
	    idx = 0;
	}
	return ptr[ptr_num - 1] + idx++;
    }
}

#define CHUNK_SIZE 512
#define CHA_MALLOC_SIZE (1024 * 64)
#define free_char()  malloc_char(-1)
static void *
malloc_char(int size)
{
    static char *ptr[CHUNK_SIZE];
    static int ptr_num = 0;
    static int idx = CHA_MALLOC_SIZE;

    if (size < 0) {
	/*
	 * free 
	 */
	if (ptr_num > 0) {
	    while (ptr_num > 1)
		free(ptr[--ptr_num]);
	    idx = 0;
	}
	return NULL;
    } else {
	if (idx + size >= CHA_MALLOC_SIZE) {
	    if (ptr_num == CHUNK_SIZE)
		cha_exit(1, "Can't allocate memory");
	    ptr[ptr_num++] = cha_malloc(CHA_MALLOC_SIZE);
	    idx = 0;
	}
	idx += size;
	return ptr[ptr_num - 1] + idx - size;
    }
}

static char *
lisp_strdup(char *str)
{
    char *newstr;

    newstr = malloc_char(strlen(str) + 1);
    strcpy(newstr, str);

    return newstr;
}

void
cha_s_free(chasen_cell_t * cell)
{
    free_cell();
    free_char();
}

/*
 * cha_tmp_atom
 */
chasen_cell_t *
cha_tmp_atom(char *atom)
{
    static chasen_cell_t _TmpCell;
    static chasen_cell_t *TmpCell = &_TmpCell;

    s_tag(TmpCell) = ATOM;
    s_atom_val(TmpCell) = atom;

    return TmpCell;
}

/*
 * cha_cons
 */
chasen_cell_t *
cha_cons(void *cha_car, void *cha_cdr)
{
    chasen_cell_t *cell;

    cell = malloc_cell();
    s_tag(cell) = CONS;
    car_val(cell) = cha_car;
    cdr_val(cell) = cha_cdr;

    return cell;
}

/*
 * cha_car
 */
chasen_cell_t *
cha_car(chasen_cell_t * cell)
{
    if (consp(cell))
	return car_val(cell);

    if (nullp(cell))
	return NIL;

    /*
     * error 
     */
    cha_exit_file(1, "%s is not list", cha_s_tostr(cell));
    Cha_errno = 1;
    return NIL;
}

/*
 * cha_cdr
 */
chasen_cell_t *
cha_cdr(chasen_cell_t * cell)
{
    if (consp(cell))
	return cdr_val(cell);

    if (nullp(cell))
	return NIL;

    /*
     * error 
     */
    cha_exit_file(1, "%s is not list\n", cha_s_tostr(cell));
    return NIL;
}

char *
cha_s_atom(chasen_cell_t * cell)
{
    if (atomp(cell))
	return s_atom_val(cell);

    /*
     * error 
     */
    cha_exit_file(1, "%s is not atom\n", cha_s_tostr(cell));
    return NILSYMBOL;
}

/*
 * cha_equal
 */
int
cha_equal(void *x, void *y)
{
    if (eq(x, y))
	return TRUE;
    if (nullp(x) || nullp(y))
	return FALSE;
    if (s_tag(x) != s_tag(y))
	return FALSE;
    if (s_tag(x) == ATOM)
	return !strcmp(s_atom_val(x), s_atom_val(y));
    if (s_tag(x) == CONS)
	return (cha_equal(car_val(x), car_val(y))
		&& cha_equal(cdr_val(x), cdr_val(y)));
    return FALSE;
}

int
cha_s_length(chasen_cell_t * list)
{
    int i;

    for (i = 0; consp(list); i++)
	list = cdr_val(list);

    return i;
}

static int
dividing_code_p(int code)
{
    switch (code) {
    case '\n':
    case '\t':
    case ';':
    case '(':
    case ')':
    case ' ':
	return 1;
    default:
	return 0;
    }
}

static int
myscanf(FILE * fp, char *str)
{
    int code;
    int in_quote = 0;
    char *s = str;

    code = fgetc(fp);
    if (code == '\"' || code == '\'') {
	in_quote = code;
	code = fgetc(fp);
    }

    for (;;) {
	if (in_quote) {
	    if (code == EOF)
		return 0;
	    if (code == in_quote)
		break;
	} else {
	    if (dividing_code_p(code) || code == EOF) {
		if (s == str)
		    return 0;
		ungetc(code, fp);
		break;
	    }
	}

	if (code != '\\' || in_quote == '\'') {
	    switch (Cha_encode) { /* XXX */
	    case CHASEN_ENCODE_SJIS:
		*s++ = code;
		if (code & 0x80)
		    *s++ = fgetc(fp);
		break;
	    default:
		*s++ = code;
		break;
	    }
	} else {
	    if ((code = fgetc(fp)) == EOF)
		return 0;
	    switch (code) {
	    case 't':
		*s++ = '\t';
		break;
	    case 'n':
		*s++ = '\n';
		break;
	    default:
		*s++ = code;
	    }
	}

	code = fgetc(fp);
    }

    *s = '\0';
    return 1;
}

/*
 * cha_s_read - read S-expression
 */
static chasen_cell_t *
s_read_atom(FILE * fp)
{
    chasen_cell_t *cell;
    char buffer[LISPBUFSIZ];

    skip_comment(fp);

    /*
     * changed by kurohashi. 
     */
    if (myscanf(fp, buffer) == 0)
	return error_in_lisp();

    if (!strcmp(buffer, NILSYMBOL))
	return NIL;

    cell = new_cell();
    s_tag(cell) = ATOM;
    s_atom_val(cell) = lisp_strdup(buffer);

    return cell;
}

static chasen_cell_t *s_read_cdr(FILE *);
static chasen_cell_t *s_read_main(FILE *);

static chasen_cell_t *
s_read_car(FILE * fp)
{
    chasen_cell_t *cell;

    skip_comment(fp);

    switch (ifnextchar(fp, (int) EPARENTHESIS)) {
    case TRUE:
	return NIL;
    case FALSE:
	cell = new_cell();
	car_val(cell) = s_read_main(fp);
	cdr_val(cell) = s_read_cdr(fp);
	return cell;
    default: /* EOF */
	return error_in_lisp();
    }
}

static chasen_cell_t *
s_read_cdr(FILE * fp)
{
    skip_comment(fp);

    switch (ifnextchar(fp, (int) EPARENTHESIS)) {
    case TRUE:
	return NIL;
    case FALSE:
	return s_read_car(fp);
    default: /* EOF */
	return error_in_lisp();
    }
}

static chasen_cell_t *
s_read_main(FILE * fp)
{
    /*
     * skip_comment(fp); 
     */
    switch (ifnextchar(fp, (int) BPARENTHESIS)) {
    case TRUE:
	return s_read_car(fp);
    case FALSE:
	return s_read_atom(fp);
    default: /* EOF */
	return error_in_lisp();
    }
}

chasen_cell_t *
cha_s_read(FILE * fp)
{
    if (Cha_lineno == 0)
	Cha_lineno = 1;
    Cha_lineno_error = Cha_lineno;

    return s_read_main(fp);
}

/*
 * cha_assoc
 */
chasen_cell_t *
cha_assoc(chasen_cell_t * item, chasen_cell_t * alist)
{
    while (!nullp(alist) && !cha_equal(item, (cha_car(cha_car(alist)))))
	alist = cha_cdr(alist);
    return cha_car(alist);
}

/*
 * cha_s_print - pretty print S-expression
 */
static char cell_buffer_for_print[8192];
static char *s_tostr_main(chasen_cell_t *);

static void
s_puts_to_buffer(char *str)
{
    static int idx = 0;
    int len;

    /*
     * initialization 
     */
    if (str == NULL) {
	idx = 0;
	return;
    }

    len = strlen(str);
    if (idx + len >= sizeof(cell_buffer_for_print)) {
	/*
	 * str is too long 
	 */
	idx = sizeof(cell_buffer_for_print);
    } else {
	strcpy(cell_buffer_for_print + idx, str);
	idx += len;
    }
}

static void
s_tostr_cdr(chasen_cell_t * cell)
{
    if (!nullp(cell)) {
	if (consp(cell)) {
	    s_puts_to_buffer(" ");
	    s_tostr_main(car_val(cell));
	    s_tostr_cdr(cdr_val(cell));
	} else {
	    s_puts_to_buffer(" ");
	    s_tostr_main(cell);
	}
    }
}

static char *
s_tostr_main(chasen_cell_t * cell)
{
    if (nullp(cell))
	s_puts_to_buffer(NILSYMBOL);
    else {
	switch (s_tag(cell)) {
	case CONS:
	    s_puts_to_buffer("(");
	    s_tostr_main(car_val(cell));
	    s_tostr_cdr(cdr_val(cell));
	    s_puts_to_buffer(")");
	    break;
	case ATOM:
	    s_puts_to_buffer(s_atom_val(cell));
	    break;
	default:
	    s_puts_to_buffer("INVALID_CELL");
	}
    }

    return cell_buffer_for_print;
}

char *
cha_s_tostr(chasen_cell_t * cell)
{
    /*
     * initialization 
     */
    s_puts_to_buffer(NULL);

    return s_tostr_main(cell);
}

chasen_cell_t *
cha_s_print(FILE * fp, chasen_cell_t * cell)
{
    fputs(cha_s_tostr(cell), fp);
    return cell;
}
