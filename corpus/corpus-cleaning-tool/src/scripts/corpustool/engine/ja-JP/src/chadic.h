/*
 * chadic.h
 *     1990/12/06/Thu  Yutaka MYOKI(Nagao Lab., KUEE)
 *
 * $Id: chadic.h,v 1.1.1.1 2007/03/13 07:40:10 masayu-a Exp $
 */

#ifndef __CHADIC_H__
#define __CHADIC_H__

#include "config.h"

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <limits.h>

#ifdef HAVE_UNISTD_H
#include <sys/types.h>
#endif /* HAVE_UNISTD_H */

#ifndef FALSE
#define FALSE  ((int)0)
#endif
#ifndef TRUE
#define TRUE   (!FALSE)
#endif

#if defined _WIN32
#define PATH_DELIMITER  '\\'
#define PATHTYPE_MSDOS
#else
#define PATH_DELIMITER  '/'
#endif

#define MIDASI_LEN	129

#define HINSI_NUM	128

#define TYPE_NUM		256
#define FORM_NUM		128

#define VCHA_CONNECT_FILE "connect.cha"
#define VCHA_CONNTMP_FILE "_connect.cha"
#define VCHA_GRAMMAR_FILE "grammar.cha"
#define VCHA_CFORM_FILE   "cforms.cha"
#define VCHA_CTYPE_FILE   "ctypes.cha"
#define VCHA_TABLE_FILE   "table.cha"
#define VCHA_MATRIX_FILE  "matrix.cha"
#define CHA_CONNECT_FILE  "chasen.connect.c"
#define CHA_CONNTMP_FILE  "chasen.connect"
#define CHA_GRAMMAR_FILE  "chasen.grammar"
#define CHA_CFORM_FILE    "chasen.cforms"
#define CHA_CTYPE_FILE    "chasen.ctypes"
#define CHA_TABLE_FILE    "chasen.table"
#define CHA_MATRIX_FILE   "chasen.matrix"
#define CONNECT_FILE	  VCHA_CONNECT_FILE
#define CONNTMP_FILE	  VCHA_CONNTMP_FILE
#define GRAMMAR_FILE	  VCHA_GRAMMAR_FILE
#define CFORM_FILE	  VCHA_CFORM_FILE
#define CTYPE_FILE	  VCHA_CTYPE_FILE
#define TABLE_FILE	  VCHA_TABLE_FILE
#define MATRIX_FILE	  VCHA_MATRIX_FILE

#define CONS		0
#define ATOM		1
#define NIL		((chasen_cell_t *)(NULL))

#define s_tag(cell)	(((chasen_cell_t *)(cell))->tag)
#define consp(x)	(!nullp(x) && (s_tag(x) == CONS))
#define atomp(x)	(!nullp(x) && (s_tag(x) == ATOM))
#define nullp(cell)	((cell) == NIL)
#define car_val(cell)	(((chasen_cell_t *)(cell))->value.cha_cons.cha_car)
#define cdr_val(cell)	(((chasen_cell_t *)(cell))->value.cha_cons.cha_cdr)
#define s_atom_val(cell) (((chasen_cell_t *)(cell))->value.atom)

/* added by T.Utsuro for weight of rensetu matrix */
#define DEFAULT_C_WEIGHT  10

/* added by S.Kurohashi for mrph weight default values */
#define MRPH_DEFAULT_WEIGHT	1

/*
 * structures
 */

/* rensetu matrix */
typedef struct _connect_rule_t {
    unsigned short next;
    unsigned short cost;
} connect_rule_t;

/* <cha_car> 部と <cha_cdr> 部へのポインタで表現されたセル */
typedef struct _bin_t {
    void *cha_car;			/* address of <cha_car> */
    void *cha_cdr;			/* address of <cha_cdr> */
} bin_t;

/* <BIN> または 文字列 を表現する完全な構造 */
typedef struct _cell {
    int tag;			/* tag of <cell> 0:cha_cons 1:atom */
    union {
	bin_t	cha_cons;
	char	*atom;
    } value;
} chasen_cell_t;

/* this structure is used only in mkchadic */
/* morpheme */
typedef struct _lexicon_t {
    char headword[MIDASI_LEN];  /* surface form */
    short stem_len;
    char reading[MIDASI_LEN * 2];    /* Japanese reading *//* XXX ad hoc */
    short reading_len;
    char pron[MIDASI_LEN * 2];    /* Japanese pronunciation *//* XXX ad hoc */
    short pron_len;
    char *base;               /* base form */
    unsigned short pos;     /* POS number */
    unsigned char inf_type;      /* Conjugation type number */
    unsigned char inf_form;      /* Conjugation form number */

    char *info;               /* semantic information */

    short con_tbl;            /* connection table number */
    unsigned short weight;    /* cost for morpheme  */

} lexicon_t;

/* POS information -- see also the comments (the end of this file) */
typedef struct _hinsi_t {
    short *path;         /* the path to top node */
    short *daughter;     /* the daughter node */
    char  *name;         /* the name of POS (at the level) */
    short composit;      /* for the COMPOSIT_POS */ 
    char  depth;         /* the depth from top node */
    char  kt;            /* have conjugation or not */
    unsigned char cost;
} hinsi_t;

/* 活用型 conjugation type */
typedef struct _ktype {
    char   *name;    /* CTYPE name */
    short  basic;    /* base form */
} ktype_t;

/* 活用形 conjugation form */
typedef struct _kform {
    char  *name;     /* CFORM name */
    char  *gobi;     /* suffix of surface form */
    int   gobi_len;  /* the length of suffix */
    char  *ygobi;    /* suffix of Japanese reading */
    char  *pgobi;    /* suffix of Japanese pronunciation */
} kform_t;

/* 連接表 connection matrix */
typedef struct _rensetu_pair {
    short  index;
    short  i_pos;  /* the POS index in the current state (= preceding morpheme) */  
    short  j_pos;  /* the POS index in the input (= current morpheme) */

    unsigned short hinsi;   /* POS */
    unsigned char type;     /* CTYPE */
    unsigned char form;     /* CFORM */
    char   *goi;   /* Lexicalized POS */
} rensetu_pair_t;

/*
 * global variables
 */

#define HINSI_MAX     4096
extern hinsi_t Cha_hinsi[HINSI_MAX];  /* see also the comments (the end of this file) */
extern ktype_t Cha_type[TYPE_NUM];
extern kform_t Cha_form[TYPE_NUM][FORM_NUM];
extern int Cha_lineno, Cha_lineno_error;

/* getopt.c */
extern int Cha_optind;
extern char *Cha_optarg;

extern int Cha_errno;
extern FILE *Cha_stderr;

/*
 * functions
 */

/* iotool.c */
char *cha_convert_escape(char*, int);
void cha_set_progpath(char*);
void cha_set_rcpath(char*);
char *cha_get_rcpath(void);
char *cha_get_grammar_dir(void);
FILE *cha_fopen(char*, char*, int);
FILE *cha_fopen_grammar(char*, char*, int, int, char**);
void *cha_malloc(size_t);
void *cha_realloc(void*, size_t);
#define cha_free(ptr) (free(ptr))
char *cha_strdup(char*);

void cha_exit(int, char*, ...);
void cha_exit_file(int, char*, ...);
void cha_perror(char*);
void cha_exit_perror(char*);
FILE *cha_fopen_rcfile(void);
void cha_read_grammar_dir(void);
char *cha_read_registry(char*, char*, char*);

/* lisp.c */
void cha_set_skip_char(int);
int cha_s_feof(FILE*);
void cha_s_free(chasen_cell_t*);
chasen_cell_t *cha_tmp_atom(char*);
chasen_cell_t *cha_cons(void*, void*);
chasen_cell_t *cha_car(chasen_cell_t*);
chasen_cell_t *cha_cdr(chasen_cell_t*);
char *cha_s_atom(chasen_cell_t*);
int cha_equal(void*, void*);
int cha_s_length(chasen_cell_t*);
chasen_cell_t *cha_s_read(FILE*);
chasen_cell_t *cha_assoc(chasen_cell_t*, chasen_cell_t*);
char *cha_s_tostr(chasen_cell_t*);
chasen_cell_t *cha_s_print(FILE*, chasen_cell_t*);

/* grammar.c */
void cha_read_class(FILE*);
int cha_match_nhinsi(chasen_cell_t*, int);
void cha_read_grammar(FILE*, int, int);

/* katuyou.c */
void cha_read_katuyou(FILE*, int);

/* connect.c */
void cha_read_table(FILE*, int);
int cha_check_table(lexicon_t*); /* 970301 tatuo: void -> int for 頑健化 */
int cha_check_table_for_undef(int);
void cha_read_matrix(FILE*);
int cha_check_automaton(int, int, int, int*);

/* getid.c */
int cha_get_nhinsi_str_id(char**);
int cha_get_nhinsi_id(chasen_cell_t*);
int cha_get_type_id(char*);
int cha_get_form_id(char*, int);

/* getopt.c */
int cha_getopt(char**, char*, FILE*);
int cha_getopt_chasen(char**, FILE*);

#endif /* __CHADIC_H__ */


/*
  the data format of the structure hinsi_t
  the POS informations are treated in global valuable Cha_hinsi[n]

=============                          ===================
"grammar.cha"                          "real POS tag list"
=============                          ===================
(A1                   ; Cha_hinsi[1]
    (B1)              ; Cha_hinsi[2]   A1-B1                 ; Cha_hinsi[2]
    (B2               ; Cha_hinsi[3]
	(C1)          ; Cha_hinsi[4]   A1-B2-C1              ; Cha_hinsi[4]
	(C2           ; Cha_hinsi[5]
	    (D1)      ; Cha_hinsi[6]   A1-B2-C2-D1           ; Cha_hinsi[6]
	    (D2)      ; Cha_hinsi[7]   A1-B2-C2-D2           ; Cha_hinsi[7]
	    (D3))     ; Cha_hinsi[8]   A1-B2-C2-D3           ; Cha_hinsi[8]
	(C3)          ; Cha_hinsi[9]   A1-B2-C3              ; Cha_hinsi[9]
	(C4           ; Cha_hinsi[10]
	    (D4)      ; Cha_hinsi[11]  A1-B2-C4-D4           ; Cha_hinsi[11]
	    (D5))))   ; Cha_hinsi[12]  A1-B2-C4-D5           ; Cha_hinsi[12]

=========================================
*hinsi_t Cha_hinsi[HINSI] for the example
=========================================
n (idx)                =  1  2  3  4  5  6  7  8  9  10 11 12
Cha_hinsi[n].name      =  A1 B1 B2 C1 C2 D1 D2 D3 C3 C4 D4 D5
Cha_hinsi[n].depth     =  1  2  2  3  3  4  4  4  3  3  4  4
*Cha_hinsi[n].daughter =  2  0  4  0  6  0  0  0  0  11 0  0
*Cha_hinsi[n].path     =  1  1  1  1  1  1  1  1  1  1  1  1

*/
