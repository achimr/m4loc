/*
 * $Id: dartsdic.h,v 1.1.1.1 2007/03/13 07:40:10 masayu-a Exp $
 */

#ifndef _DARTSDIC_H_
#define _DARTSDIC_H_

typedef struct _darts_t darts_t;
typedef struct _da_build_t da_build_t;

extern darts_t *Da_dicfile[];
extern int Da_ndicfile;

typedef struct {
    unsigned short posid;
    unsigned char inf_type;
    unsigned char inf_form;
    unsigned short weight;
    short con_tbl;
    long dat_index;
} da_lex_t;

typedef struct {
    short stem_len;
    short reading_len;
    short pron_len;
    short base_len;
    short info_len;
    long compound;
} da_dat_t;

darts_t *da_open(char*, char*, char*);
int da_lookup(darts_t*, char*, int, long*, int);
long da_exact_lookup(darts_t*, char*, int);
int da_get_lex(darts_t*, long, da_lex_t*, int*);
void *da_get_lex_base(darts_t*);
void *da_get_dat_base(darts_t*);

da_build_t *da_build_new(char*);
void da_build_add(da_build_t*, char*, long);
int da_build_dump(da_build_t*,char*,FILE*);

#endif /* _DARTSDIC_H_ */
