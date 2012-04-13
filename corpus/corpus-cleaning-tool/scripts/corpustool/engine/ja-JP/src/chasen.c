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
 * $Id: chasen.c,v 1.1.1.1 2007/03/13 07:40:10 masayu-a Exp $
 */

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#else
#if defined _WIN32
#include <io.h>
#define isatty(handle) _isatty(handle)
#endif /* _WIN32 */
#endif /* HAVE_UNISTD_H */

#include "chalib.h"

static char *output_file = NULL;
static int is_partial = 0;

#define CHA_NAME       "ChaSen"
#define CHA_PROG       "chasen"

/*
 * opt_form_usage()
 */
static void
opt_form_usage(FILE * fp)
{
    static char *message[] = {
	"Conversion characters of -F option:\n",
	"  %m      surface form (inflected form)\n",
	"  %M      surface form (base form)\n",
	"  %y,%y1  first candidate of reading (inflected form)\n",
	"  %Y,%Y1  first candidate of reading (base form)\n",
	"  %y0     reading (inflected form)\n",
	"  %Y0     reading (base form)\n",
	"  %a,%a1  first candidate of pronounciation (inflected form)\n",
	"  %A,%A1  first candidate of pronounciation (base form)\n",
	"  %a0     pronounciation (inflected form)\n",
	"  %A0     pronounciation (base form)\n",
	"  %rABC   surface form with ruby (the format is \"AkanjiBkanaC\")\n",
	"  %i,%i1  first candidate of semantic information\n",
	"  %i0     semantic information\n",
	"  %Ic     semantic information (if NIL, print character 'c'.)\n",
	"  %Pc     part of speech separated by character 'c'\n",
	"  %Pnc    part of speech separated by character 'c'\n",
	"  %h      part of speech (code)\n",
	"  %H      part of speech (name)\n",
	"  %Hn     the part of speech (name) at the n-th layer\n",
	"          (if NIL, the part of speech at the most specific layer)\n",
	"  %b      sub-part of speech (code)\n",
	"  %BB     sub-part of speech (name)(if NIL, print part of speech)\n",
	"  %Bc     sub-part of speech (name)(if NIL, print character 'c')\n",
	"  %t      inflection type (code)\n",
	"  %Tc     inflection type (name)(if NIL, print character 'c')\n",
	"  %f      inflected form (code)\n",
	"  %Fc     inflected form (name)(if NIL, print character 'c')\n",
	"  %c      cost value of the morpheme\n",
	"  %S      the input sentence\n",
	"  %pb     if the best path, '*', otherwise, ' '\n",
	"  %pi     the index of the path of the output lattice\n",
	"  %ps     the starting position of the morpheme\n",
	"          at the path of the output lattice\n",
	"  %pe     the ending position of the morpheme\n",
	"          at the path of the output lattice\n",
	"  %pc     the cost of the path of the output lattice\n",
	"  %ppiC   the indices of the preceding paths,\n",
	"          concatenated with the character 'C'\n",
	"  %ppcC   the costs of the preceding paths,\n",
	"          concatenated with the character 'C'\n",
	"  %?B/STR1/STR2/\n",
	"          if sub-part of speech exists, STR1, otherwise, STR2\n",
	"  %?I/STR1/STR2/\n",
	"          unless the semantic information is NIL and \"\", STR1,\n",
	"          otherwise, STR2\n",
	"  %?T/STR1/STR2/\n",
	"          if conjugative, STR1, otherwise, STR2\n",
	"  %?F/STR1/STR2/\n",
	"          same as %?T/STR1/STR2/\n",
	"  %?U/STR1/STR2/\n",
	"          if unknown word, STR1, otherwise, STR2\n",
	"  %U/STR/\n",
	"          if unknown word, \"UNKNOWN\", otherwise, STR\n",
	"  %%      '%'\n",
	"  .       specify the field width\n",
	"  -       specify the field width\n",
	"  1-9     specify the field width\n",
	"  \\n      carriage return\n",
	"  \\t      tab\n",
	"  \\\\      back slash\n",
	"  \\'      single quotation mark\n",
	"  \\\"      double quotation mark\n",
	"\n",
	"Examples:\n",
	"  \"%m \"         split words by space (wakachi-gaki)\n",
	"  \"%y\"          Kanji to Kana conversion\n",
	"  \"%r ()\"       print surface form with ruby as \"kanji(kana)\"\n",
	"  \"%m\\t%y\\t%M\\t%U(%P-)\\t%T \\t%F \\n\"           same as -f option (default)\n",
	"  \"%m\\t%U(%y)\\t%M\\t%P- %h %T* %t %F* %f\\n\"    same as -e option\n",
	"\n",
	"Note:\n",
	"  If the format ends with `\\n' then outputs `EOS',\n",
	"  otherwise outputs newline every sentence.\n",
	NULL
    };
    char **mes;

    if (fp)
	for (mes = message; *mes; mes++)
	    fputs(*mes, fp);
}

/*
 *  usage()
 */
static void
usage(FILE * fp)
{
    static char *message[] = {
	"Usage: ", CHA_PROG, " [options] [file...]\n",
	"    -s             partial analyzing mode\n",
	"  (how to print ambiguous results)\n",
	"    -b             show the best path (default)\n",
	"    -m             show all morphemes\n",
	"    -p             show all paths\n",
	"  (output format)\n",
	"    -f             show formatted morpheme data (default)\n",
	"    -e             show entire morpheme data\n",
	"    -c             show coded morpheme data\n",
	"    -d             show detailed morpheme data for Prolog\n",
	"    -v             show detailed morpheme data for VisualMorphs\n",
	"    -F format      show morpheme with formatted output\n",
	"    -Fh            print help of -F option\n",
	"  (miscellaneous)\n",
	"    -i encoding    character encoding.\n",
        "                   e: EUC-JP, s: Shift_JIS, ",
	"w: UTF-8, a: ISO-8859-1\n",
	"    -j             Japanese sentence mode\n",
	"    -o file        write output to `file'\n",
	"    -w width       specify the cost width\n",
	"    -C             use command mode\n",
	"    -r rc-file     use rc-file as a ", CHA_PROG,
	    "rc file other than the default\n",
	"    -R             with -D, do not read ", CHA_PROG,
	    "rc file, without -D, read the\n",
	"                   default chasenrc file `", RCPATH, "'\n",
	"    -L lang        specify languages\n",
	"    -O[c|s]        output with compound words or their segments\n",
	"    -lp            print the list of parts of speech\n",
	"    -lt            print the list of conjugation types\n",
	"    -lf            print the list of conjugation forms\n",
	"    -h             print this help\n",
	"    -V             print ", CHA_NAME, " version number\n",
	NULL
    };
    char **mes;

    cha_version(fp);
    if (fp)
	for (mes = message; *mes; mes++)
	    fputs(*mes, fp);
}

/*
 * getopt_argv()
 */
static void
getopt_argv(char **argv)
{
    int c;

    Cha_optind = 0;
    while ((c = cha_getopt_chasen(argv, stderr)) != EOF) {
	switch (c) {
	case 's':
	    is_partial = 1;
	    break;
	case 'r':		/* chasenrc file */
	    cha_set_rcpath(Cha_optarg);
	    break;
	case 'R':		/* don't read chasenrc file */
	    cha_set_rcpath("*");
	    break;
	case 'o':
	    output_file = Cha_optarg;
	    break;
	case 'F':
	    /*
	     * -Fh: print help of -F 
	     */
	    if (Cha_optarg[0] == 'h' && Cha_optarg[1] == '\0') {
		opt_form_usage(stdout);
		exit(0);
	    }
	    break;
	case 'V':
	    cha_version(stdout);
	    exit(0);
	case 'h':
	    usage(stdout);
	    exit(0);
	case '?':
	    fprintf(stderr, "Try `%s -h' for more information.\n",
		    CHA_PROG);
	    exit(1);
	}
    }
}

/*
 * do_chasen_standalone()
 */
static void
do_chasen_standalone(FILE * ifp, FILE * ofp)
{
    int istty;

    /*
     * output: whether `stdout' or not 
     */
    istty = ofp == stdout && isatty(fileno(stdout));

    if (is_partial) {
	chasen_parse_segments(ifp, ofp);
    } else {
	while (!chasen_fparse(ifp, ofp))
	    if (!istty)
		fflush(ofp);
    }
}

/*
 * chasen_standalone()
 *
 * return: exit code
 */
static int
chasen_standalone(char **argv, FILE * output)
{
    /*
     * standalone 
     */
    if (chasen_getopt_argv(argv, stderr))
	return 1;
    argv += Cha_optind;

    if (*argv == NULL)
	do_chasen_standalone(stdin, output);
    else
	for (; *argv; argv++)
	    do_chasen_standalone(cha_fopen(*argv, "r", 1), output);

    return 0;
}

/*
 * main()
 */
int
main(int argc, char *argv[])
{
    int rc;
    FILE *output;

    cha_set_progpath(argv[0]);

    getopt_argv(argv);

    output = output_file ? cha_fopen(output_file, "w", 1) : stdout;
    rc = chasen_standalone(argv, output);
    if (output != stdout)
	fclose(output);
    return rc;
}
