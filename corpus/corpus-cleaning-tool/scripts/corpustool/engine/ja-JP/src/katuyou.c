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
 * $Id: katuyou.c,v 1.1.1.1 2007/03/13 07:40:10 masayu-a Exp $
 */

#include "chadic.h"
#include "literal.h"

ktype_t Cha_type[TYPE_NUM];
kform_t Cha_form[TYPE_NUM][FORM_NUM];
char *Cha_base_form_str = NULL;

/*
 * read_type_form
 */
static void
read_type_form(FILE * fp)
{
    chasen_cell_t *cell1, *cell2;
    int i, j;
    char *s;

    for (i = 1; !cha_s_feof(fp); i++) {
	cell1 = cha_s_read(fp);
	Cha_type[i].name = cha_strdup(cha_s_atom(cha_car(cell1)));
	Cha_type[i].basic = 0;
	cell1 = cha_car(cha_cdr(cell1));

	/* base form string */
	if (cha_litmatch(Cha_type[i].name, 2,
			 STR_BASE_FORM_STR1, STR_BASE_FORM_STR2)) {
	    Cha_base_form_str = cha_strdup(cha_s_atom(cell1));
	    i--;
	    continue;
	}

	for (j = 1; !nullp(cell2 = cha_car(cell1));
	     cell1 = cha_cdr(cell1), j++) {
	    /*
	     * name 
	     */
	    Cha_form[i][j].name = cha_strdup(cha_s_atom(cha_car(cell2)));
	    if (!Cha_type[i].basic &&
		(Cha_base_form_str
		 ? !strcmp(Cha_form[i][j].name, Cha_base_form_str)
		 : cha_litmatch(Cha_form[i][j].name, 2,
				STR_BASE_FORM1, STR_BASE_FORM2)))
		Cha_type[i].basic = j;
	    /*
	     * gobi 
	     */
	    if (strcmp
		(s =
		 cha_s_atom(cha_car(cell2 = cha_cdr(cell2))), "*") == 0)
		Cha_form[i][j].gobi = "";
	    else {
		Cha_form[i][j].gobi = cha_strdup(s);
		Cha_form[i][j].gobi_len = strlen(s);
	    }
	    /*
	     * ygobi 
	     */
	    if (nullp(cha_car(cell2 = cha_cdr(cell2))))
		Cha_form[i][j].ygobi = Cha_form[i][j].gobi;
	    else if (strcmp(s = cha_s_atom(cha_car(cell2)), "*") == 0)
		Cha_form[i][j].ygobi = "";
	    else {
		Cha_form[i][j].ygobi = cha_strdup(s);
	    }
	    /*
	     * pgobi 
	     */
	    if (nullp(cha_car(cell2 = cha_cdr(cell2))))
		Cha_form[i][j].pgobi = Cha_form[i][j].ygobi;
	    else if (strcmp(s = cha_s_atom(cha_car(cell2)), "*") == 0)
		Cha_form[i][j].pgobi = "";
	    else {
		Cha_form[i][j].pgobi = cha_strdup(s);
	    }
	}
	if (!Cha_type[i].basic)
	    cha_exit_file(1, "no basic form");
    }
}

/*
 * cha_read_katuyou - read CFORM_FILE and set Cha_form[][]
 *
 * inputs:
 *	dir - 0: read from current directory
 *	      1: read from grammar directory
 *	      2: read from current directory or grammar directory
 */
void
cha_read_katuyou(FILE * fp_out, int dir)
{
    FILE *fp;
    char *filepath;

    fp = cha_fopen_grammar(CFORM_FILE, "r", 1, dir, &filepath);
    if (fp_out != NULL)
	fprintf(fp_out, "parsing %s\n", filepath);

    read_type_form(fp);

    fclose(fp);
}
