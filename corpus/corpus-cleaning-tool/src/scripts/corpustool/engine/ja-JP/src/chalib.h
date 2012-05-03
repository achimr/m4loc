/*
 * $Id: chalib.h,v 1.1.1.1 2007/03/13 07:40:10 masayu-a Exp $
 */

#ifndef __CHALIB_H__
#define __CHALIB_H__

#include "chadic.h"
#include "chasen.h"

#if defined _WIN32 && ! defined __CYGWIN__
#define	strcasecmp	stricmp
#define	strncasecmp	strnicmp
#endif /* _WIN32 */

#define CHA_PATH_NUM            1024
#define CHA_INPUT_SIZE      8192
#define UNDEF_HINSI_MAX     256
#define DIC_NUM 32 /* 同時に使える辞書の数の上限 (ChaSen) */

#define MRPH_NUM            1024
#define PATH1_NUM	    256

/*
 * structures
 */

typedef struct _mrph_t {
    /* don't move this order */
    unsigned short posid;
    unsigned char inf_type;
    unsigned char inf_form;
    unsigned short weight;
    short con_tbl;
    long dat_index;

    char *headword;
    short headword_len;
    char is_undef;
    void *darts;
} mrph_t;

typedef struct _mrph_data_t {
    mrph_t *mrph;
    short stem_len;
    char *reading;
    char *pron;
    short reading_len;
    short pron_len;
    char *base;
    char *info;
    long compound;
} mrph_data_t;

typedef struct _path_t {
    int   mrph_p;
    short state;
    short start;
    short end;
    short do_print;
    int   cost;
    int   *path;
    int   best_path;
} path_t;

typedef struct _cha_lat_t {
    unsigned char text[CHA_INPUT_SIZE]; /* XXX */
    int len;
//    path_t *lattice;
//    int path_num;
    int anno;
    int last_anno;
    /* for parse */
    int offset;
    int cursor;
    int head_path;
    int path_idx[PATH1_NUM];
} cha_lat_t;

enum cha_segtype {
    SEGTYPE_NORMAL,
    SEGTYPE_UNSPECIFIED,
    SEGTYPE_MORPH,
    SEGTYPE_ANNOTATION
};

typedef struct _cha_seg_t cha_seg_t;
struct _cha_seg_t {
    unsigned char *text;
    int len;
    char char_type[CHA_INPUT_SIZE]; /* XXX */
    enum cha_segtype type;
    char is_undef;
    unsigned short posid;
    unsigned char inf_type;
    unsigned char inf_form;
    int anno_no;
};

/* information for annotation */
typedef struct _anno_info {
    int  hinsi;
    char *str1, *str2;
    int  len1, len2;
    char *format;
} anno_info;

/* information for unseen word */
typedef struct _undef_info {
    int  cost, cost_step;
    int  con_tbl;
    int  hinsi;
} undef_info;

typedef struct _cha_mmap_t cha_mmap_t;
typedef struct _cha_block_t cha_block_t;

/*
 * global variables
 */
extern cha_block_t *Cha_mrph_block;
extern path_t *Cha_path;
extern int Cha_path_num;
extern int Cha_con_cost_weight, Cha_con_cost_undef;
extern int Cha_mrph_cost_weight, Cha_cost_width;
extern int Space_pos_hinsi;
extern anno_info Cha_anno_info[UNDEF_HINSI_MAX];
extern undef_info Cha_undef_info[UNDEF_HINSI_MAX];
extern int Cha_undef_info_num;
extern char *Cha_bos_string;
extern char *Cha_eos_string;
extern int Cha_output_iscompound;

/*
 * functions
 */

/* init.c */
void cha_read_rcfile_fp(FILE*);
void cha_init(void);

/* print.c */
char *cha_get_output(void);
void cha_set_output(FILE*);
void cha_print_reset(void);
void cha_printf_mrph(cha_lat_t*, int, mrph_data_t*, char*);
void cha_print_path(cha_lat_t*, int, int, char*);
void cha_print_bos_eos(int);
void cha_print_hinsi_table(void);
void cha_print_ctype_table(void);
void cha_print_cform_table(void);

/* parse.c */
int cha_parse_bos(cha_lat_t*);
int cha_parse_eos(cha_lat_t*);
int cha_parse_segment(cha_lat_t*, cha_seg_t*);


/* chalib.c */
void cha_version(FILE*);
void cha_set_opt_form(char*);
void cha_set_cost_width(int);
void cha_set_language(char*);
char *cha_fgets(char*, int, FILE*);
void cha_read_dadic(chasen_cell_t*);

/* cha_jfgets.c */
void cha_set_jfgets_delimiter(char*);
char *cha_fget_line(char*, int, FILE*);
char *cha_jfgets(char*, int, FILE*);
int cha_jistoeuc(unsigned char*, unsigned char*);

/* mmap.c */
cha_mmap_t *cha_mmap_file(char*);
cha_mmap_t *cha_mmap_file_w(char*);
void cha_munmap_file(cha_mmap_t*);
void *cha_mmap_map(cha_mmap_t*);
off_t cha_mmap_size(cha_mmap_t*);

/* block.c */
cha_block_t *cha_block_new(size_t, int);
void cha_block_delete(cha_block_t*);
void *cha_block_new_item(cha_block_t*);
void *cha_block_get_item(cha_block_t*, int);
void *cha_block_pop(cha_block_t*);
int cha_block_num(cha_block_t*);
void cha_block_clear(cha_block_t*);

#endif /* __CHALIB_H__ */
