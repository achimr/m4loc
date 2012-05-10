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
 * $Id: block.c,v 1.1.1.1 2007/03/13 07:40:10 masayu-a Exp $
 */

#include <stdlib.h>
#include <stdio.h>
#include "chalib.h"

struct _cha_block_t {
    void *blocks;
    size_t item_size;
    int allocated_num;
    int num;
};

cha_block_t *
cha_block_new(size_t size, int nitem)
{
    cha_block_t *block;

    block = cha_malloc(sizeof(cha_block_t));

    block->item_size = size;
    block->allocated_num = nitem;
    block->blocks = cha_malloc(size * nitem);
    block->num = 0;

    return block;
}

void cha_block_delete(cha_block_t *block)
{
    cha_free(block->blocks);
    cha_free(block);
}

void *
cha_block_new_item(cha_block_t *block)
{
    if (++block->num > block->allocated_num) {
	block->allocated_num *= 2;
	block->blocks = cha_realloc(block->blocks, 
				    block->item_size * block->allocated_num);
    }
    return block->blocks + block->item_size * (block->num - 1);
}

void *
cha_block_get_item(cha_block_t *block, int i)
{
    return block->blocks + block->item_size * i;
}

void *
cha_block_pop(cha_block_t *block)
{
    return block->blocks + block->item_size * --block->num;
}

int
cha_block_num(cha_block_t *block)
{
    return block->num;
}

void
cha_block_clear(cha_block_t *block)
{
    block->num = 0;
}
