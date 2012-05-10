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
 * $Id: getid.c,v 1.1.1.1 2007/03/13 07:40:10 masayu-a Exp $
 */

#include "chadic.h"

/*
 * get POS str id
 *
 */
int
cha_get_nhinsi_str_id(char **hinsi)
{
    int id, i, d;

    if (!*hinsi)
	cha_exit_file(1, "an empty string for POS");

    for (id = 0; *hinsi; hinsi++) {
	if (!**hinsi)
	    cha_exit_file(1, "an empty string for POS");
	for (i = 0; (d = Cha_hinsi[id].daughter[i]) != 0; i++) {
	    if (!strcmp(Cha_hinsi[d].name, *hinsi))
		break;
	}
	if (!d) {
	    cha_exit_file(1, "POS `%s' is undefined", *hinsi);
	}
	id = d;
    }

    return id;
}

/*
 * get POS id 
 */
int
cha_get_nhinsi_id(chasen_cell_t * cell)
{
    char *hinsi_str[256];
    char **hinsi = hinsi_str;

    for (; !nullp(cell); cell = cha_cdr(cell))
	*hinsi++ = cha_s_atom(cha_car(cell));

    *hinsi = NULL;

    return cha_get_nhinsi_str_id(hinsi_str);
}

/*
 * get ctype id 
 */
int
cha_get_type_id(char *x)
{
    int i;

    if (x == NULL) {
	cha_exit_file(1, "null string for type");
	return 0;
    }

    if (x[0] == '*' && x[1] == '\0')
	return 0;

    for (i = 1; strcmp(Cha_type[i].name, x);) {
	if (!Cha_type[++i].name) {
	    cha_exit_file(1, "type `%s' is undefined", x);
	}
    }

    return i;
}

/*
 * get cform id 
 */
int
cha_get_form_id(char *x, int type)
{
    int i;

    if (x == NULL) {
	cha_exit_file(1, "null string for form");
	return 0;
    }

    if (x[0] == '*' && x[1] == '\0')
	return 0;

    if (type == 0) {
	cha_exit_file(1, "Invalid type number for type `%s'", x);
	return 0;
    }

    for (i = 1; strcmp(Cha_form[type][i].name, x);) {
	if (!Cha_form[type][++i].name) {
	    cha_exit_file(1, "type `%s' has no conjugation `%s'",
			  Cha_type[type].name, x);
	    return 0;
	}
    }

    return i;
}
