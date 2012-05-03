/*
 * makemat.c - make table file and matrix file
 *
 * $Id: makemat.c,v 1.2 2007/03/13 07:51:47 masayu-a Exp $
 */

#include "chadic.h"
#include "literal.h"

#define CTYPE_MAX        500
#define REN_TBL_MAX      10000
#define RENSETU_CELL_MAX (8192*4)

#define HINSI_ID_MAX USHRT_MAX

typedef struct _kankei_t {
    unsigned short hinsi;
    unsigned char type;
} kankei_t;

typedef struct _rensetu_pair2_t {
    short i_pos;     /* the POS index in the current state (= preceding morpheme) */
    short j_pos;     /* the POS index in the input (= current morpheme) */
    chasen_cell_t *hinsi; /* POS */
    unsigned char type;   /* CTYPE */
    char *form;           /* CFORM */
    char *goi;            /* Lexicalized POS */
} rensetu_pair2_t;

typedef struct _rensetu_chasen_cell_t {
    short tbl;
    short prev;
    short has_rule;
} rensetu_chasen_cell_t;

static kankei_t kankei_tbl[CTYPE_MAX];
static int tbl_num;
static rensetu_pair_t rensetu_tbl[RENSETU_CELL_MAX];
static int i_num;
static int j_num;

static connect_rule_t **connect_mtr;
typedef unsigned char rensetu_mtr_t;

/*
 * read_kankei - read chasen's kankei file
 */
static void
read_kankei(void)
{
    FILE *fp;
    chasen_cell_t *cell1, *cell2;
    int j = 0;
    int hinsi, type;

    /*
     * read only from current directory 
     */
    fp = cha_fopen(CTYPE_FILE, "r", 1);

    fprintf(stderr, "parsing %s\n", CTYPE_FILE);

    while (!cha_s_feof(fp)) {
	cell1 = cha_s_read(fp);

	hinsi = cha_get_nhinsi_id(cha_car(cell1));
	cell1 = cha_car(cha_cdr(cell1));

	while (!nullp(cell2 = cha_car(cell1))) {
	    type = cha_get_type_id(cha_s_atom(cell2));
	    kankei_tbl[j].hinsi = hinsi;
	    kankei_tbl[j].type = type;

	    if (++j >= CTYPE_MAX)
		cha_exit(1, "not enough size for CTYPE_MAX");
	    cell1 = cha_cdr(cell1);
	}
	kankei_tbl[j].hinsi = HINSI_ID_MAX;
    }
}

/*
 * get_pair1
 */
static void
get_pair1(chasen_cell_t * cell, rensetu_pair_t * pair)
{
    chasen_cell_t *cell_p;

    pair->hinsi = 0;
    pair->type = 0;
    pair->form = 0;
    pair->goi = NULL;

    if (nullp(cell_p = cha_car(cell)))
	return;
    pair->hinsi = cha_get_nhinsi_id(cell_p);

    if (nullp(cell_p = cha_car(cell = cha_cdr(cell))))
	return;
    pair->type = cha_get_type_id(cha_s_atom(cell_p));

    if (nullp(cell_p = cha_car(cell = cha_cdr(cell))))
	return;
    pair->form = cha_get_form_id(cha_s_atom(cell_p), pair->type);

    if (nullp(cell_p = cha_car(cell = cha_cdr(cell))))
	return;
    pair->goi = cha_strdup(cha_s_atom(cell_p));
}

/*
 * get_pair2
 */
static void
get_pair2(chasen_cell_t * cell, rensetu_pair2_t * pair)
{
    chasen_cell_t *cell_p;
    char *s;

    pair->hinsi = NULL;
    pair->type = 0;
    pair->form = NULL;
    pair->goi = NULL;

    if (nullp(cell_p = cha_car(cell)))
	return;

    s = cha_s_atom(cha_car(cell_p));
    if (cha_litmatch(s, 2, STR_BOS, STR_EOS)) {
	pair->hinsi = NULL;
	return;
    }
    pair->hinsi = cell_p;

    if (nullp(cell_p = cha_car(cell = cha_cdr(cell))))
	return;
    pair->type = cha_get_type_id(cha_s_atom(cell_p));

    if (nullp(cell_p = cha_car(cell = cha_cdr(cell))))
	return;

    if (strcmp(s = cha_s_atom(cell_p), "*"))
	pair->form = cha_strdup(s);

    if (nullp(cell_p = cha_car(cell = cha_cdr(cell))))
	return;
    pair->goi = cha_strdup(cha_s_atom(cell_p));
}

/*
 * match_pair1
 */
static int
match_pair1(rensetu_pair_t * pair1, rensetu_pair_t * pair2)
{
    if (pair1->hinsi == pair2->hinsi &&
	pair1->type == pair2->type &&
	(!pair2->form || pair1->form == pair2->form) &&
	!strcmp(pair1->goi, pair2->goi))
	return 1;

    return 0;
}

/*
 * match_pair2
 */
static int
match_pair2(rensetu_pair2_t * pair, rensetu_pair_t * tbl)
{
    if (pair->hinsi == NULL)       /* BOS/EOS */
	return tbl->hinsi == 0;

    if (cha_match_nhinsi(pair->hinsi, (int) tbl->hinsi) &&
	(!pair->type || pair->type == tbl->type) &&
	(!pair->form ||
	 (tbl->form
	  && !strcmp(pair->form, Cha_form[tbl->type][tbl->form].name)))
	&& (!pair->goi || (tbl->goi && !strcmp(pair->goi, tbl->goi))))
	return 1;

    return 0;
}

/*
 * make_rensetu_tbl1 - register hinsi with goi(Lexicalized POS)
 */
void
make_rensetu_tbl1(chasen_cell_t * cell1, int *cnt)
{
    int i;
    rensetu_pair_t r_pair;
    chasen_cell_t *cell11;

    for (; !nullp(cell11 = cha_car(cell1)); cell1 = cha_cdr(cell1)) {
	if (nullp(cha_car(cha_cdr(cha_cdr(cha_cdr(cell11))))))
	    continue;

	get_pair1(cell11, &r_pair);

	for (i = 1; i < *cnt; i++)
	    if (match_pair1(&rensetu_tbl[i], &r_pair))
		break;
	if (i < *cnt)
	    continue;

	if (r_pair.type) {
	    for (i = 1; Cha_form[r_pair.type][i].name != NULL; i++) {
		rensetu_tbl[*cnt].hinsi = r_pair.hinsi;
		rensetu_tbl[*cnt].type = r_pair.type;
		rensetu_tbl[*cnt].form = i;
		rensetu_tbl[*cnt].goi = r_pair.goi;
		if (++*cnt >= REN_TBL_MAX)
		    cha_exit(1, "not enough size for table");
	    }
	} else {
	    rensetu_tbl[*cnt].hinsi = r_pair.hinsi;
	    rensetu_tbl[*cnt].type = r_pair.type;
	    rensetu_tbl[*cnt].form = r_pair.form;
	    rensetu_tbl[*cnt].goi = r_pair.goi;
	    if (++*cnt >= REN_TBL_MAX)
		cha_exit(1, "not enough size for table");
	}
    }
}

/*
 * make_rensetu_tbl2 - register hinsi
 */
static void
make_rensetu_tbl2(int hinsi, int bunrui, int *cnt)
{
    int i, j;

    if (Cha_hinsi[hinsi].kt == 1) { /* with conjugation */
	for (i = 0; kankei_tbl[i].hinsi != HINSI_ID_MAX; i++) {
	    if (kankei_tbl[i].hinsi == hinsi) {
		for (j = 1; Cha_form[kankei_tbl[i].type][j].name != NULL;
		     j++) {
		    rensetu_tbl[*cnt].hinsi = hinsi;
		    rensetu_tbl[*cnt].type = kankei_tbl[i].type;
		    rensetu_tbl[*cnt].form = j;
		    rensetu_tbl[*cnt].goi = NULL;
		    if (++*cnt >= REN_TBL_MAX)
			cha_exit(1, "not enough size for table");
		}
	    }
	}
    } else {  /* without conjugation */
        rensetu_tbl[*cnt].hinsi = hinsi;   
	rensetu_tbl[*cnt].type = 0;        
	rensetu_tbl[*cnt].form = 0;        
	rensetu_tbl[*cnt].goi = NULL;      

	if (++*cnt >= REN_TBL_MAX)
	    cha_exit(1, "not enough size for table");
    }
}

/*
 * make_rensetu_tbl - register hinsi into table
 */
static int
make_rensetu_tbl(FILE * fp)
{
    chasen_cell_t *cell;
    int i, lines;
    int tbl_count = 1;		/* 0 is for BOS/EOS */

    /* regist POS with lexicalization 
       語彙を指定しているものをテーブルに登録  */
    for (lines = 0; !cha_s_feof(fp); lines++) {
	for (cell = cha_car(cha_s_read(fp)); !nullp(cell);
	     cell = cha_cdr(cell))
	    make_rensetu_tbl1(cha_car(cell), &tbl_count);
    }

    /* regist POS with extracted conjugation 
       活用を展開してテーブルに登録 */
    for (i = 1; Cha_hinsi[i].name; i++)
	make_rensetu_tbl2(i, 0, &tbl_count); 	/* second argument is dummy for compatibility */
    tbl_num = tbl_count;

    /* print for check */
    fprintf(stderr, "table size: %d\n", tbl_num);

    return lines;
}

/*
 * variables and functions for rensetu_cell
 */
static rensetu_chasen_cell_t rensetu_cell[RENSETU_CELL_MAX];
static int cell_num;

static int new_cell1[RENSETU_CELL_MAX], new_cell2[RENSETU_CELL_MAX];
static int new_cell1_num, new_cell2_num;

static int
search_rensetu_cell(int tbl, int prev)
{
    int i;

    for (i = 0; i < cell_num; i++)
	if (rensetu_cell[i].tbl == tbl)
	    if (rensetu_cell[i].prev == prev)
		return i;

    return -1;
}

/*
 * c2 が c1 の suffix かどうか 
 */
static int
match_rensetu_cell_suffix(int c1, int c2)
{
    int n;

    for (n = 0; c2 >= 0; n++) {
	if (rensetu_cell[c1].tbl != rensetu_cell[c2].tbl)
	    return 0;
	c1 = rensetu_cell[c1].prev;
	c2 = rensetu_cell[c2].prev;
    }

    return n;
}

static void
match_rensetu_cell_tbl(int tbl, int *cells)
{
    int *c, i;

    c = cells;
    *c++ = tbl;
    for (i = tbl_num; i < cell_num; i++)
	if (tbl == rensetu_cell[i].tbl)
	    *c++ = i;
    *c = -1;
}

/*
 * add_connect_rule
 */
static void
add_connect_rule(int in, int prev, int cost, int is_last, int *in_cells,
		 int *cur_cells)
{
    int cur, next, *curp, *cellp;
    int suffix_len, suffix_len_max;

    next = 0;			/* to avoid warning */
    match_rensetu_cell_tbl(rensetu_cell[prev].tbl, cur_cells);

    /*
     * cell 中から cur(現状態)を検索 
     */
    for (curp = cur_cells; (cur = *curp) >= 0; curp++) {
	/*
	 * prev が cur の suffix になっていれば ok 
	 */
	if (!match_rensetu_cell_suffix(cur, prev))
	    continue;
	/*
	 * 最後の品詞でない場合は規則を上書きしない 
	 */
	if (!is_last && connect_mtr[cur][in].cost)
	    continue;
	suffix_len_max = 0;
	/*
	 * cell 中から next(次状態)を検索 
	 */
	for (cellp = in_cells; *cellp >= 0; cellp++) {
	    /*
	     * cur+in の suffix のうち最も長いものを探す 
	     */
	    suffix_len =
		match_rensetu_cell_suffix(cur,
					  rensetu_cell[*cellp].prev) + 1;
	    if (suffix_len_max < suffix_len) {
		suffix_len_max = suffix_len;
		next = *cellp;
	    }
	}
#ifdef DEBUG
	if (suffix_len_max > 1) {
	    printf("suffix_len:%d,prev:%d,cur:%d,in:%d,next:%d,cost:%d\n",
		   suffix_len_max, prev, cur, in, next, cost);
	}
#endif
	/*
	 * 規則を追加 
	 */
	if (suffix_len_max) {
	    connect_mtr[cur][in].next = next - in;
	    connect_mtr[cur][in].cost = cost < 0 ? 0 : cost + 1;
	}
    }
}

/*
 * read_rensetu
 */
static void
read_rensetu(FILE * fp, int lines)
{
    chasen_cell_t **rule;
    int *rule_len;
    rensetu_pair2_t pair;
    chasen_cell_t *cell, *cell1;
    int rule_len_max, rlen;
    int prev, in, c1, ln, linenum, linecnt;
    int cost, is_last;
    int *in_cells, *cur_cells;
    connect_rule_t *ptr;

    rule = (chasen_cell_t **) cha_malloc(sizeof(chasen_cell_t *) * lines);
    rule_len = (int *) cha_malloc(sizeof(int) * lines);

    fputs("lines: ", stderr);
    /*
     * rensetu_cell の初期化 
     */
    if (cell_num >= RENSETU_CELL_MAX)
	cha_exit(1, "not enough size for cell");
    for (cell_num = 0; cell_num < tbl_num; cell_num++) {
	rensetu_cell[cell_num].tbl = cell_num;
	rensetu_cell[cell_num].prev = -1;
    }

    rule_len_max = 0;
    for (ln = 0; !cha_s_feof(fp); ln++) {
	rule[ln] = cha_s_read(fp);
	if ((ln % 500) == 0) {
	    fputc('.', stderr);
	    fflush(stderr);
	}

	/*
	 * 最も長い規則を見つける 
	 */
	rule_len[ln] = cha_s_length(cha_car(rule[ln]));
	if (rule_len[ln] < 2)
	    cha_exit_file(1, "too few morphemes");
	if (rule_len_max < rule_len[ln])
	    rule_len_max = rule_len[ln];

	/*
	 * new_cell2: 各品詞で登録した rensetu_cell 
	 */
	new_cell2[0] = -1;	/* 文頭・文末 */
	new_cell2_num = 1;
	/*
	 * 規則のノードを作成 
	 */
	/*
	 * cell: 品詞群のリスト 
	 */
	for (cell = cha_car(rule[ln]); !nullp(cha_cdr(cell));
	     cell = cha_cdr(cell)) {
	    /*
	     * new_cell2 を new_cell1 にコピー 
	     */
	    memcpy(new_cell1, new_cell2, sizeof(int) * new_cell2_num);
	    new_cell1_num = new_cell2_num;
	    new_cell2_num = 0;
	    /*
	     * cell1: 品詞群 
	     */
	    for (cell1 = cha_car(cell); !nullp(cell1);
		 cell1 = cha_cdr(cell1)) {
		int tbl;
		/*
		 * pair: ワイルドカードつきの品詞 
		 */
		get_pair2(cha_car(cell1), &pair);
		/*
		 * pair から tbl(品詞1つ1つ)を取り出して処理 
		 */
		for (tbl = 0; tbl < tbl_num; tbl++) {
		    if (!match_pair2(&pair, &rensetu_tbl[tbl]))
			continue;
		    /*
		     * c1, prev: 1つ前の品詞で登録されたcell 
		     */
		    for (c1 = 0; c1 < new_cell1_num; c1++) {
			int prev = new_cell1[c1], cellno;
			if ((cellno = search_rensetu_cell(tbl, prev)) < 0) {
			    cellno = cell_num;
			    if (++cell_num >= RENSETU_CELL_MAX)
				cha_exit_file(1,
					      "not enough size for cell");
			    rensetu_cell[cellno].tbl = tbl;
			    rensetu_cell[cellno].prev = prev;
#ifdef DEBUG
			    printf("cellno:%d,tbl:%d,prev:%d\n", cellno,
				   tbl, prev);
#endif
			}
			new_cell2[new_cell2_num++] = cellno;
		    }
		}
	    }
	}
    }

    fprintf(stderr, " %d\n", ln);
    fprintf(stderr, "number of states: %d\n", cell_num);

    ptr =
	(connect_rule_t *) cha_malloc(sizeof(connect_rule_t) * cell_num *
				      tbl_num);
    memset(ptr, 0, sizeof(connect_rule_t) * cell_num * tbl_num);
    connect_mtr =
	(connect_rule_t **) cha_malloc(sizeof(connect_rule_t *) *
				       cell_num);
    for (c1 = 0; c1 < cell_num; c1++)
	connect_mtr[c1] = ptr + c1 * tbl_num;

    in_cells = cha_malloc(sizeof(int) * cell_num);
    cur_cells = cha_malloc(sizeof(int) * cell_num);

    linenum = ln;
    linecnt = 0;

    /*
     * 短い規則の順に処理 
     */
    for (rlen = 2; rlen <= rule_len_max; rlen++) {
		/*	fprintf(stderr, rlen == 2 ? "bi%s" : rlen == 3 ? "tri%s" : "%d%s",
			"-gram: ", rlen); */
		if (rlen <= 3)	
			fprintf(stderr, rlen == 2 ? "bi%s" : rlen == 3 ? "tri%s" : "%s",
					"-gram: ");	
		else	
			fprintf(stderr, "%d-gram: ", rlen);

	for (ln = 0; ln < linenum; ln++) {
	    if (rule_len[ln] != rlen)
		continue;
	    Cha_lineno_error = Cha_lineno = ln + 1;
#ifdef DEBUG
	    printf("Line: %d/%d\n", ln + 1, linenum);
#endif
	    if ((++linecnt % 500) == 0) {
		fputc('.', stderr);
		if ((linecnt % 20000) == 0)
		    fprintf(stderr, " %d\n", linecnt);
		fflush(stderr);
	    }

	    cell = cha_car(cha_cdr(rule[ln]));
	    cost = nullp(cell) ? DEFAULT_C_WEIGHT : atoi(cha_s_atom(cell));
	    is_last = 0;
	    /*
	     * new_cell2: 各品詞で登録した rensetu_cell 
	     */
	    new_cell2[0] = -1;	/* 文頭・文末 */
	    new_cell2_num = 1;
	    /*
	     * cell: 品詞群のリスト 
	     */
	    for (cell = cha_car(rule[ln]); !is_last; cell = cha_cdr(cell)) {
		is_last = nullp(cha_cdr(cell));
		/*
		 * new_cell2 を new_cell1 にコピー 
		 */
		memcpy(new_cell1, new_cell2, sizeof(int) * new_cell2_num);
		new_cell1_num = new_cell2_num;
		new_cell2_num = 0;
		/*
		 * cell1: 品詞群 
		 */
		for (cell1 = cha_car(cell); !nullp(cell1);
		     cell1 = cha_cdr(cell1)) {
		    /*
		     * pair: ワイルドカードつきの品詞 
		     */
		    get_pair2(cha_car(cell1), &pair);
		    /*
		     * pair から in(品詞1つ1つ)を取り出して処理 
		     */
		    for (in = 0; in < tbl_num; in++) {
			if (!match_pair2(&pair, &rensetu_tbl[in]))
			    continue;
			match_rensetu_cell_tbl(in, in_cells);
			/*
			 * c1, prev: 1つ前の品詞で登録されたcell 
			 */
			for (c1 = 0; c1 < new_cell1_num; c1++) {
			    prev = new_cell1[c1];
			    if (!is_last) {
				int cellno = search_rensetu_cell(in, prev);
				new_cell2[new_cell2_num++] = cellno;
			    }
			    /*
			     * 規則を追加 
			     */
			    add_connect_rule(in, prev, cost, is_last,
					     in_cells, cur_cells);
			}
		    }
		}
	    }
	}
	printf(" %d\n", linecnt);
    }
}

static int
compare_vector1(int k, int j, int num)
{
    int i;

    for (i = 0; i < num; i++)
	if (connect_mtr[i][k].next != connect_mtr[i][j].next ||
	    connect_mtr[i][k].cost != connect_mtr[i][j].cost)
	    return 0;

    return 1;
}

static void
copy_vector1(int j, int j_n, int num)
{
    int i;

    for (i = 0; i < num; i++) {
	connect_mtr[i][j_n].next = connect_mtr[i][j].next;
	connect_mtr[i][j_n].cost = connect_mtr[i][j].cost;
    }
}

static int
compare_vector2(int k, int i, int num)
{
    int j;

    for (j = 0; j < num; j++)
	if (connect_mtr[i][j].next != connect_mtr[k][j].next ||
	    connect_mtr[i][j].cost != connect_mtr[k][j].cost)
	    return 0;

    return 1;
}

static void
copy_vector2(int i, int i_n, int num)
{
    int j;

    for (j = 0; j < num; j++) {
	connect_mtr[i_n][j].next = connect_mtr[i][j].next;
	connect_mtr[i_n][j].cost = connect_mtr[i][j].cost;
    }
}

/*
 * condense_matrix
 */
static void
condense_matrix(void)
{
    int i, j, k;
    int i_n = 0;
    int j_n = 0;

    fprintf(stderr, "matrix size: %dx%d", cell_num, tbl_num);

    for (j = 0; j < tbl_num; j++) {
	int has_same = 0;

	for (k = 0; k < j_n; k++) {
	    if (compare_vector1(k, j, cell_num)) {
		rensetu_tbl[j].j_pos = k;
		has_same = 1;
		break;
	    }
	}
	if (!has_same) {
	    if (j != j_n)
		copy_vector1(j, j_n, cell_num);
	    rensetu_tbl[j].j_pos = j_n++;
	}
    }
    j_num = j_n;

    for (i = 0; i < cell_num; i++) {
	int has_same = 0;

	for (k = 0; k < i_n; k++) {
	    if (compare_vector2(k, i, j_num)) {
		rensetu_tbl[i].i_pos = k;
		has_same = 1;
		break;
	    }
	}
	if (!has_same) {
	    if (i != i_n)
		copy_vector2(i, i_n, j_num);
	    rensetu_tbl[i].i_pos = i_n++;
	}
    }
    i_num = i_n;

    /*
     * print for check 
     */
    fprintf(stderr, " -> %dx%d\n", i_num, j_num);
}

/*
 * write_table, write_matrix
 */
static void
write_table(void)
{
    FILE *fp;
    rensetu_pair_t *tbl;
    int i;

    fp = cha_fopen(TABLE_FILE, "w", 1);
    fprintf(fp, "%d\n", cell_num);
    for (i = 0, tbl = &rensetu_tbl[0]; i < tbl_num; i++, tbl++) {
	/*
	 * comment 
	 */
	fprintf(fp, "%s %s %s %s\n",
		Cha_hinsi[tbl->hinsi].name ?
		Cha_hinsi[tbl->hinsi].name : "(null)",
		tbl->type ? Cha_type[tbl->type].name : "",
		tbl->form ? Cha_form[tbl->type][tbl->form].name : "",
		tbl->goi ? tbl->goi : "");
	/*
	 * data 
	 */
	fprintf(fp, "%d %d %d %d %d %s\n",
		tbl->i_pos, tbl->j_pos, tbl->hinsi,
		tbl->type, tbl->form, tbl->goi ? tbl->goi : "*");
    }
    for (; i < cell_num; i++, tbl++)
	fprintf(fp, ";\n%d -1 0 0 0 *\n", tbl->i_pos);

    fclose(fp);
}

static void
write_matrix(void)
{
    FILE *fp;
    int i, j;

    fp = cha_fopen(MATRIX_FILE, "w", 1);
    fprintf(fp, "%d %d\n", i_num, j_num);

    for (i = 0; i < i_num; i++) {
	int nval = 0;
	int next0 = connect_mtr[i][0].next;
	int cost0 = connect_mtr[i][0].cost;
	for (j = 0; j < j_num; j++) {
	    if (connect_mtr[i][j].next == next0 &&
		connect_mtr[i][j].cost == cost0) {
		nval++;
	    } else {
		if (next0 == 0 && cost0 == 0)
		    fprintf(fp, "o%d ", nval);
		else if (nval == 1)
		    fprintf(fp, "%d,%d ", next0, cost0);
		else
		    fprintf(fp, "%d,%dx%d ", next0, cost0, nval);
		nval = 1;
		next0 = connect_mtr[i][j].next;
		cost0 = connect_mtr[i][j].cost;
	    }
	}
	if (nval > 0) {
	    if (next0 == 0 && cost0 == 0)
		fprintf(fp, "o%d ", nval);
	    else if (nval == 1)
		fprintf(fp, "%d,%d ", next0, cost0);
	    else
		fprintf(fp, "%d,%dx%d ", next0, cost0, nval);
	}
	fprintf(fp, "\n");
    }
    fclose(fp);
}

/*
 * main
 */
int
main(int argc, char *argv[])
{
    FILE *fpc;
    int lines;
    char *con_filename;
    int c;

    cha_set_progpath(argv[0]);

    cha_set_encode("");
    while ((c = cha_getopt(argv, "i:", stderr)) != EOF) {
	switch (c) {
	case 'i':
	    cha_set_encode(Cha_optarg);
	    break;
	}
    }
    argv += Cha_optind;

    if (argv[0] == NULL)
	con_filename = CONNECT_FILE;
    else
	con_filename = argv[0];

    /*
     * .chasenrc は読み込む必要ない 
     */

    /*
     * 文法・活用・関係ファイル 
     */
    cha_read_grammar(stderr, 0, 0);
    cha_read_katuyou(stderr, 0);
    read_kankei();

    /*
     * 連接規則ファイルのオープン 
     */
    fpc = cha_fopen(con_filename, "r", 1);

    /*
     * 連接規則ファイルの処理 
     */
    fprintf(stderr, "parsing %s\n", con_filename);
    cha_set_skip_char('#');
    lines = make_rensetu_tbl(fpc);
    rewind(fpc);
    Cha_lineno = 0;
    read_rensetu(fpc, lines);
    fclose(fpc);

    /*
     * 連接行列の圧縮 
     */
    condense_matrix();
    write_table();
    write_matrix();

    return 0;
}


/*---------------------------------------------------

 Memo for connection matrix.

 * chasen automaton:

    current state : the preceding morpheme state number
    input: the current morpheme state number
    output: the next state number & connection cost


                  +============+
           input  | cur state  |
+-----------+     +------------+
| the cur   |---->|  the prec  |
| mrph state|     | mrph state |  i_pos in rensetu_pair_t
+-----------+     +============+
j_pos                   | output
in rensetu_pair_t       v
                  +------------+
                  | the next   |   lib/chadic.h
                  |   state    |   typedef struct _connect_rule_t {
                  +------------+       unsigned short next;   
                  | connection |       unsigned short cost;   
                  |   cost     |   } connect_rule_t;
                  +------------+

  * table.cha
  ----
  接続助詞   ながら                 [POS name]   [lexicalized POS]
  3 3 64 0 0 ながら                 i_pos j_pos hinshi type form goi
  ----

  * matrix.cha
  -----
  0,394 0,8001 0,3430 0,8001 0,3766 0,8001x2 0,3094 ....
  -----
  Hcolumn: current state = preceding morpheme  (cell_num)
  Vcolumn: input         = current morpheme    (tbl_num)

  the entry X,Yx2 means as follows:

  X = next state number (nonzero for tri-gram context, zero for bi-gram context)
  Y = connection cost

  `x2' means two times of state(compressed expression)

*/
