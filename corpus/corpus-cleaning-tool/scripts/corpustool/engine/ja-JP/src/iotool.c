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
 * $Id: iotool.c,v 1.1.1.1 2007/03/13 07:40:10 masayu-a Exp $
 */

#include "config.h"

#include <stdio.h>
#include <stdarg.h>
#ifdef HAVE_WINDOWS_H
#include <windows.h>
#endif
#include "chadic.h"
#include "literal.h"

#ifdef PATHTYPE_MSDOS
#define RCFILE "\\chasenrc"
#define RC2FILE "\\chasen2rc"
#else
#define RCFILE "/.chasenrc"
#define RC2FILE "/.chasen2rc"
#endif

#if defined HAVE_WINDOWS_H && !defined __CYGWIN__
#define REG_PATH "Software\\NAIST\\ChaSen"
#define REG_RC "chasenrc"
#define REG_GRAMMAR "grammar"
#endif

int Cha_lineno, Cha_lineno_error;
int Cha_errno = 0;

static FILE *cha_stderr = NULL;
static char progpath[PATH_MAX] = "chasen";
static char filepath[PATH_MAX];
static char grammar_dir[PATH_MAX];
static char chasenrc_path[PATH_MAX];

/*
 * cha_convert_escape - convert escape characters
 */
/* XXX: not Shift-JIS safe */
char *
cha_convert_escape(char *str, int ctrl_only)
{
    char *s1, *s2;

    for (s1 = s2 = str; *s1; s1++, s2++) {
	if (*s1 != '\\')
	    *s2 = *s1;
	else {
	    switch (*++s1) {
	    case 't':
		*s2 = '\t';
		break;
	    case 'n':
		*s2 = '\n';
		break;
	    default:
		if (ctrl_only)
		    *s2++ = '\\';
		*s2 = *s1;
		break;
	    }
	}
    }
    *s2 = '\0';

    return str;
}

/*
 * cha_set_progpath - set program pathname
 *
 *	progpath is used in cha_exit() and cha_exit_file()
 */
void
cha_set_progpath(char *path)
{
#if defined _WIN32 && ! defined __CYGWIN__
    GetModuleFileName(GetModuleHandle(NULL), progpath, PATH_MAX);
#else /* not _WIN32 */
    strncpy(progpath, path, PATH_MAX);
#endif /* _WIN32 */
}

/*
 * cha_set_rcpath - set chasenrc file path
 *
 *	this function is called when -r option is used.
 */
void
cha_set_rcpath(char *filename)
{
    strncpy(chasenrc_path, filename, PATH_MAX);
}

/*
 * cha_get_rcpath
 *
 *	called only from chasen.c
 */
char *
cha_get_rcpath(void)
{
    return chasenrc_path;
}

/*
 * cha_get_grammar_dir
 *
 *	called only from chasen.c
 */
char *
cha_get_grammar_dir(void)
{
    return grammar_dir;
}

/*
 * cha_fopen - open file, or error end
 *
 * inputs:
 *	ret - exit code (don't exit if ret < 0)
 */
FILE *
cha_fopen(char *filename, char *mode, int ret)
{
    FILE *fp;

    if (filename[0] == '-' && filename[1] == '\0')
	return stdin;

    if ((fp = fopen(filename, mode)) != NULL) {
	/*
	 * filepath is used in cha_exit_file() 
	 */
	if (*mode == 'r') {
	    if (filename != filepath)
		strncpy(filepath, filename, PATH_MAX);
	    Cha_lineno = Cha_lineno_error = 0;
	}
    } else if (ret >= 0)
	cha_exit_perror(filename);

    return fp;
}

/*
 * cha_fopen_grammar - open file from current or grammar directory
 *
 * inputs:
 *	dir - 0: read from current directory
 *	      1: read from grammar directory
 *	      2: read from current directory or grammar directory
 *
 *	ret - return the code when fopen() fails
 *
 * outputs:
 *	filepathp - file path string
 */
FILE *
cha_fopen_grammar(char *filename, char *mode, int ret, int dir,
		  char **filepathp)
{
    FILE *fp;

    *filepathp = filename;
    switch (dir) {
    case 0:
	/*
	 * カレントディレクトリから読み込む 
	 */
	return cha_fopen(filename, mode, ret);
    case 2:
	/*
	 * カレントディレクトリから読み込む 
	 */
	if ((fp = cha_fopen(filename, mode, -1)) != NULL)
	    return fp;
	/*
	 * FALLTHRU 
	 */
    default:			/* should be 1 */
	/*
	 * 文法ディレクトリから読み込む 
	 * 文法ディレクトリが設定されていなければ .chasenrc を読み込む 
	 */
	if (grammar_dir[0] == '\0')
	    cha_read_grammar_dir();
	snprintf(filepath, PATH_MAX, "%s%s", grammar_dir, filename);
	*filepathp = filepath;
	return cha_fopen(filepath, mode, ret);
    }
}

/*
 * cha_malloc()
 */
void *
cha_malloc(size_t n)
{
    void *p;

    if ((p = malloc(n)) == NULL)
	cha_exit_perror("malloc");

    return p;
}

void *
cha_realloc(void *ptr, size_t n)
{
    void *p;

    if ((p = realloc(ptr, n)) == NULL)
	cha_exit_perror("realloc");

    return p;
}

#define CHA_MALLOC_SIZE (1024 * 64)
static char *
cha_malloc_char(int size)
{
    static int idx = CHA_MALLOC_SIZE;
    static char *ptr;

    if (idx + size >= CHA_MALLOC_SIZE) {
	ptr = (char *) cha_malloc(CHA_MALLOC_SIZE);
	idx = 0;
    }

    idx += size;
    return ptr + idx - size;
}

char *
cha_strdup(char *str)
{
    char *newstr;

    newstr = cha_malloc_char(strlen(str) + 1);
    strcpy(newstr, str);

    return newstr;
}

/*
 * cha_exit() - print error messages on stderr and exit
 */
void
cha_set_stderr(FILE * fp)
{
    cha_stderr = fp;
}

void
cha_exit(int status, char *format, ...)
{
    va_list ap;

    if (Cha_errno)
	return;

    if (!cha_stderr)
	cha_stderr = stderr;
    else if (cha_stderr != stderr)
	fputs("500 ", cha_stderr);

    if (progpath)
	fprintf(cha_stderr, "%s: ", progpath);
    va_start(ap, format);
    vfprintf(cha_stderr, format, ap);
    va_end(ap);
    if (status >= 0) {
	fputc('\n', cha_stderr);
	if (cha_stderr == stderr)
	    exit(status);
	Cha_errno = 1;
    }
}

void
cha_exit_file(int status, char *format, ...)
{
    va_list ap;

    if (Cha_errno)
	return;

    if (!cha_stderr)
	cha_stderr = stderr;
    else if (cha_stderr != stderr)
	fputs("500 ", cha_stderr);

    if (progpath)
	fprintf(cha_stderr, "%s: ", progpath);

    if (Cha_lineno == 0)
	;	/* do nothing */
    else if (Cha_lineno == Cha_lineno_error)
	fprintf(cha_stderr, "%s:%d: ", filepath, Cha_lineno);
    else
	fprintf(cha_stderr, "%s:%d-%d: ", filepath, Cha_lineno_error,
		Cha_lineno);

    va_start(ap, format);
    vfprintf(cha_stderr, format, ap);
    va_end(ap);

    if (status >= 0) {
	fputc('\n', cha_stderr);
	if (cha_stderr == stderr)
	    exit(status);
	Cha_errno = 1;
    }
}

void
cha_perror(char *s)
{
    cha_exit(-1, "");
    perror(s);
}

void
cha_exit_perror(char *s)
{
    cha_perror(s);
    exit(1);
}

FILE *
cha_fopen_rcfile(void)
{
    FILE *fp;
    char *home_dir, *rc_env, *getenv();

    /*
     * -R option (standard alone) 
     */
    if (!strcmp(chasenrc_path, "*")) {
#if defined HAVE_WINDOWS_H && !defined __CYGWIN__
	if ((cha_read_registry(REG_PATH, REG_RC, chasenrc_path) != NULL) &&
	    ((fp = cha_fopen(chasenrc_path, "r", -1)) != NULL)) {
	    return fp;
	}
#endif
	strncpy(chasenrc_path, RCPATH, PATH_MAX);
	if ((fp = cha_fopen(chasenrc_path, "r", -1)) != NULL)
	    return fp;
	cha_exit(1, "can't open %s", chasenrc_path);
    }

    /*
     * -r option 
     */
    if (chasenrc_path[0])
	return cha_fopen(chasenrc_path, "r", 1);

    /*
     * environment variable CHASENRC 
     */
    if ((rc_env = getenv("CHASENRC")) != NULL) {
	strncpy(chasenrc_path, rc_env, PATH_MAX);
	return cha_fopen(chasenrc_path, "r", 1);
    }

    /*
     * .chasenrc in the home directory 
     */
    if ((home_dir = getenv("HOME")) != NULL) {
	/*
	 * .chasenrc 
	 */
	snprintf(chasenrc_path, PATH_MAX, "%s%s", home_dir, RC2FILE);
	if ((fp = cha_fopen(chasenrc_path, "r", -1)) != NULL)
	    return fp;
	snprintf(chasenrc_path, PATH_MAX, "%s%s", home_dir, RCFILE);
	if ((fp = cha_fopen(chasenrc_path, "r", -1)) != NULL)
	    return fp;
    }
#ifdef PATHTYPE_MSDOS
    else if ((home_dir = getenv("HOMEDRIVE")) != NULL) {
	snprintf(chasenrc_path, PATH_MAX, 
		 "%s%s%s", home_dir, getenv("HOMEPATH"), RC2FILE);
	if ((fp = cha_fopen(chasenrc_path, "r", -1)) != NULL)
	    return fp;
	snprintf(chasenrc_path, PATH_MAX,
		 "%s%s%s", home_dir, getenv("HOMEPATH"), RCFILE);
	if ((fp = cha_fopen(chasenrc_path, "r", -1)) != NULL)
	    return fp;
    }
#endif /* PATHTYPE_MSDOS */

#if defined HAVE_WINDOWS_H && !defined __CYGWIN__
    if ((cha_read_registry(REG_PATH, REG_RC, chasenrc_path) != NULL) &&
	((fp = cha_fopen(chasenrc_path, "r", -1)) != NULL)) {
	return fp;
    }
#endif
    strncpy(chasenrc_path, RCPATH, PATH_MAX);

    if ((fp = cha_fopen(chasenrc_path, "r", -1)) != NULL)
	return fp;

    cha_exit(1, "can't open chasenrc or %s", chasenrc_path);

    /*
     * to avoid warning 
     */
    return NULL;
}

static void
add_delimiter(char *string)
{
    char *s = string + strlen(string);

    if (s[-1] != PATH_DELIMITER) {
	s[0] = PATH_DELIMITER;
	s[1] = '\0';
    }
}

/*
 * read .chasenrc and set grammar directory
 */
void
cha_read_grammar_dir(void)
{
    FILE *fp;
    chasen_cell_t *cell;

    fp = cha_fopen_rcfile();

    while (!cha_s_feof(fp)) {
	char *s;
	cell = cha_s_read(fp);
	s = cha_s_atom(cha_car(cell));
	if (cha_litmatch(s, 1, STR_GRAM_FILE)) {
	    strncpy(grammar_dir, cha_s_atom(cha_car(cha_cdr(cell))), PATH_MAX);
	    add_delimiter(grammar_dir);
	    break;
	}
    }

    if (grammar_dir[0] == '\0') {
	char *s;

#if defined HAVE_WINDOWS_H && !defined __CYGWIN__
	if (cha_read_registry(REG_PATH, REG_GRAMMAR,
			      grammar_dir) != NULL) {
	    if (grammar_dir[0] != '\0')
		add_delimiter(grammar_dir);
	} else {
#endif
	strncpy(grammar_dir, chasenrc_path, PATH_MAX);
	if ((s = strrchr(grammar_dir, PATH_DELIMITER)) != NULL)
	    s[1] = '\0';
	else
	    grammar_dir[0] = '\0';
#if defined HAVE_WINDOWS_H && !defined __CYGWIN__
	}
#endif
    }

    fclose(fp);
}

char *
cha_read_registry(char *path, char *name, char *val)
{
#if defined HAVE_WINDOWS_H && !defined __CYGWIN__
    HKEY hKey;
    DWORD size = PATH_MAX;

    if ((RegOpenKeyEx(HKEY_CURRENT_USER, path, 0, 
		      KEY_QUERY_VALUE, &hKey) == ERROR_SUCCESS) &&
	(RegQueryValueEx(hKey, name, NULL, NULL, (LPBYTE)val, &size) ==
	 ERROR_SUCCESS)) {
	RegCloseKey(hKey);
    } else
	val = NULL;

    return val;
#else
    return NULL;
#endif
}
