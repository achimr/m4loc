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
 * NOTE: An idea of these procedures are taken from youhcan's jutils.c
 *       for wais-japanese
 * 
 * $Id: jfgets.c,v 1.1.1.1 2007/03/13 07:40:10 masayu-a Exp $
 */


#include <stdio.h>
#include <string.h>

#define INNER_BUFSIZE   8192

/*
 * delimiter for cha_jfgets() 
 */
static char jfgets_delimiter[256] = "．。！？";

void
cha_set_jfgets_delimiter(char *delimiter)
{
    strncpy(jfgets_delimiter, delimiter, sizeof(jfgets_delimiter));
}

int
cha_jistoeuc(unsigned char *ibuffer, unsigned char *obuffer)
{
    unsigned char *p, *o;
    int level, flag;

    level = 0;
    flag = 0;
    o = obuffer;

    for (p = ibuffer; *p; p++) {
	if (*p == 0x1b) {
	    level = 1;
	} else if (level == 1) {
	    if (*p == '$')
		level = 2;	/* ESC $ */
	    else if (*p == '(')
		level = 12;	/* ESC ( */
	    else
		level = 0;
	} else if (level) {
	    /*
	     * Translation 
	     */
	    if (level == 2 && *p == '@')
		flag = 1;	/* ESC $ @ */
	    if (level == 2 && *p == 'B')
		flag = 1;	/* ESC $ B */
	    if (level == 12 && *p == 'B')
		flag = 0;	/* ESC ( B */
	    if (level == 12 && *p == 'J')
		flag = 0;	/* ESC ( J */

	    /*
	     * Give up to parse escape sequence 
	     */
	    level = 0;
	} else if (flag && *p >= 0x20) {
	    /*
	     * KANJI mode without control characters 
	     */
	    *o++ = *p++ | 0x80;
	    *o++ = *p | 0x80;
	}
	/*
	 * ASCII mode or control character in KANJI mode 
	 */
	/*
	 * plural space characters -> single space 
	 */
	else if (*p == ' ' || *p == '\t') {
	    if (o == obuffer || o[-1] != ' ')
		*o++ = ' ';
	} else {
	    *o++ = *p;
	}
    }
    *o = '\0';

    return 0;
}

/*
 * isterminator - check it is terminator or not
 *
 * return
 *               1: terminator
 *               0: not terminator
 *              -1:     error
 */

static int
isterminator(unsigned char *target, unsigned char *termlist)
{
    if (termlist == NULL || target == NULL) {
	return -1;
    }

    while (*termlist) {
	if (*termlist & 0x80) {
	    if (*termlist == *target && *(termlist + 1) == *(target + 1))
		return 1;
	    termlist += 2;
	} else {
	    if (*termlist == *target)
		return 1;
	    termlist++;
	}
    }
    return 0;
}

/*
 * inner buffer and inner position.
 *      if stream is empty. 'pos' point NULL.
 *
 */
static int
iskanji1(unsigned char *str, int idx)
{
    int n;

    for (n = 0; idx >= 0 && str[idx] >= 0x80; n++, idx--);

    return n & 1;
}

/*
 * cha_fget_line - get line via fgets(). So it is really reading function :-)
 */
char *
cha_fget_line(char *buffer, int bufsize, FILE * stream)
{
    static unsigned char tmp_buf[INNER_BUFSIZE];
    int last;

    if (fgets(tmp_buf, bufsize, stream) == NULL)
	return NULL;

    /*
     * remove the last extra character 
     */
    last = strlen(tmp_buf) - 1;
    if (iskanji1(tmp_buf, last)) {
	ungetc(tmp_buf[last], stream);
	tmp_buf[last] = 0;
    }

    /*
     * call convertor
     * NOTE: EUC string is short than JIS string.
     *       if you want to other conversion,
     *       you must care about string length.
     */

    cha_jistoeuc(tmp_buf, buffer);

    return buffer;
}

/*
 * cha_jfgets - fgets() for Japanese Text.
 *
 */
char *
cha_jfgets(char *buffer, int bufsize, FILE * stream)
{
    static unsigned char ibuf[INNER_BUFSIZE];
    /* set to the end of line */
    static unsigned char *pos = (unsigned char *) "";
    unsigned char *q;
    int count;
    int kflag;	/* kanji flag(0=not found, 1=found) */

    if (pos == NULL &&
	(pos = cha_fget_line(ibuf, sizeof(ibuf), stream)) == NULL)
	return NULL;

    kflag = 0;
    q = (unsigned char *) buffer;
    bufsize--;

    for (count = bufsize; count > 0; count--) {
	/*
	 * line is end without '\n', long string read more 
	 */
	if (*pos == '\0')
	    if ((pos = cha_fget_line(ibuf, sizeof(ibuf), stream)) == NULL)
		break;

	/*
	 * KANJI 
	 */
	if (*pos >= 0x80 && *(pos + 1)) {
	    if (count < 2)
		break;
	    kflag = 1;
	    count--;
	    *q++ = *pos++;
	    *q++ = *pos++;

	    /*
	     * hit delimiter 
	     */
	    if (isterminator(pos - 2, jfgets_delimiter)) {
		if (*pos == '\n')
		    pos++;
		break;
	    }
	}
	/*
	 * not KANJI 
	 */
	else {
	    /*
	     * line is end 
	     */
	    if (*pos == '\n') {
		/*
		 * eliminate space characters at the end of line 
		 */
		while (q > (unsigned char *) buffer
		       && (q[-1] == ' ' || q[-1] == '\t'))
		    q--;

		if ((pos =
		     cha_fget_line(ibuf, sizeof(ibuf), stream)) == NULL)
		    break;

		while (*pos == ' ' || *pos == '\t')
		    pos++;

		/*
		 * not have kanji or no space, return with this line 
		 */
		if (count <= 0)
		    break;

		/*
		 * have kanji, connect next line 
		 */
		/*
		 * double '\n' is paragraph end. so it is delimiter 
		 */
		if (*pos == '\n')
		    break;

		/*
		 * "ASCII\nASCII" -> "ASCII ASCII" 
		 */
		if (!kflag && !(*pos & 0x80))
		    *q++ = ' ';
	    } else {
		if (*pos != ' ' && *pos != '\t')
		    kflag = 0;
		*q++ = *pos++;

		/*
		 * hit delimiter 
		 */
		if (isterminator(pos - 1, jfgets_delimiter)) {
		    if (*pos == '\n')
			pos++;
		    break;
		}
	    }
	}

    }

    *q = '\0';

    return buffer;
}
