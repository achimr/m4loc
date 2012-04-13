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
 * $Id: getopt.c,v 1.1.1.1 2007/03/13 07:40:10 masayu-a Exp $
 */

#include <stdio.h>
#include <string.h>

int Cha_optind = 0;
char *Cha_optarg;

int
cha_getopt(char **argv, char *optstring, FILE * fp)
{
    static char *nextchar;
    char *op, c;

    /*
     * initialization 
     */
    if (Cha_optind == 0) {
	Cha_optind = 1;
	nextchar = argv[1];
    }
    Cha_optarg = NULL;

    if (nextchar == argv[Cha_optind]) {
	/*
	 * no option 
	 */
	if (nextchar == NULL || nextchar[0] != '-' || nextchar[1] == '\0')
	    return EOF;
	/*
	 * '--' option 
	 */
	if (*++nextchar == '-') {
	    nextchar = argv[++Cha_optind];
	    return EOF;
	}
    }

    /*
     * find out an option letter 
     */
    c = *nextchar++;
    if ((op = strchr(optstring, c)) == NULL || c == ':') {
	if (fp != NULL)
	    fprintf(fp, "%s: invalid option -- %c\n", argv[0], c);
	c = '?';
    }
    /*
     * option with an argument 
     */
    else if (op[1] == ':') {
	/*
	 * next character 
	 */
	if (*nextchar)
	    Cha_optarg = nextchar;
	/*
	 * next argv 
	 */
	else if (argv[Cha_optind + 1] != NULL)
	    Cha_optarg = argv[++Cha_optind];
	/*
	 * no argument 
	 */
	else {
	    if (fp != NULL)
		fprintf(fp, "%s: option requires an argument -- %c\n",
			argv[0], c);
	    c = '?';
	}
	nextchar = argv[++Cha_optind];
    }

    if (nextchar != NULL && *nextchar == '\0')
	nextchar = argv[++Cha_optind];

    return c;
}

/*
 * chasen_getopt
 */
int
cha_getopt_chasen(char **argv, FILE * fp)
{
    return cha_getopt(argv, "i:sP:D:RabmpdvfecMo:F:L:l:jr:w:O:ChV", fp);
}



#ifdef TEST
int
main(int argc, char *argv[])
{
    int c;

    while (1) {
	c = cha_getopt(argv, "abc:d:", stderr);
	if (c == EOF)
	    break;
	switch (c) {
	case 'a':
	    printf("option a\n");
	    break;

	case 'b':
	    printf("option b\n");
	    break;

	case 'c':
	    printf("option c with value `%s'\n", Cha_optarg);
	    break;

	case '?':
	    break;

	default:
	    printf("?? getopt returned character code 0%o ??\n", c);
	}
    }

    if (Cha_optind < argc) {
	printf("non-option ARGV-elements: ");
	while (Cha_optind < argc)
	    printf("%s ", argv[Cha_optind++]);
	printf("\n");
    }

    exit(0);
}
#endif /* TEST */
