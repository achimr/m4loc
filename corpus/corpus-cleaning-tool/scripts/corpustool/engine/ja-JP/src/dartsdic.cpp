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
 * $Id: dartsdic.cpp,v 1.4 2008/05/16 04:59:21 masayu-a Exp $
 */

#include <string>
#include <vector>
#include <map>
#include <iostream>
#include <darts.h>
extern "C" {
#include <stdlib.h>
#include <stdio.h>
#include "dartsdic.h"
#include "chalib.h"
}

typedef Darts::DoubleArrayImpl<char, unsigned char, long, unsigned long>
DoubleArrayL;

struct _darts_t {
    DoubleArrayL *da;
    cha_mmap_t *da_mmap;
    cha_mmap_t *lex_mmap;
    cha_mmap_t *dat_mmap;
};

typedef std::multimap<std::string, long> Hash;
typedef Hash::value_type HashVal;

struct _da_build_t {
    Hash *entries;
    std::string* path;
};

darts_t *
da_open(char *daname, char *lexname, char *datname)
{
    darts_t *da;
    DoubleArrayL *darts = new DoubleArrayL;

    da = (darts_t*)cha_malloc(sizeof(darts_t));
    da->da_mmap = cha_mmap_file(daname);
    darts->set_array(cha_mmap_map(da->da_mmap));
    da->da = darts;
    da->lex_mmap = cha_mmap_file(lexname);
    da->dat_mmap = cha_mmap_file(datname);

    return da;
}

int
da_lookup(darts_t *da, char *key, int key_len, long *indecies, int num)
{
    return da->da
	->commonPrefixSearch(key, indecies, num, key_len);
}

long
da_exact_lookup(darts_t *da, char *key, int key_len)
{
	     return da->da	
				 ->exactMatchSearch<long>(key,  key_len);	

}

#define lex_map(d) cha_mmap_map((d)->lex_mmap)
#define dat_map(d) cha_mmap_map((d)->dat_mmap)

int
da_get_lex(darts_t *da, long index, da_lex_t *lex_data, int *key_len)
{
    int num, i;
    char *base = (char *)lex_map(da) + index;

    *key_len = ((short *)base)[0];
    num = ((short *)base)[1];
    base += sizeof(short) * 2;

    for (i = 0; i < num; i++) {
	memcpy((void*)(lex_data + i),
	       (void*)base, sizeof(da_lex_t));
	base += sizeof(da_lex_t);
    }

    return num;
}

void *
da_get_lex_base(darts_t *da)
{
    return lex_map(da);
}

void *
da_get_dat_base(darts_t *da)
{
    return dat_map(da);
}

da_build_t *
da_build_new(char *path)
{
    da_build_t *builder;

    builder = (da_build_t*)cha_malloc(sizeof(da_build_t));
    builder->entries = new Hash;
    builder->path = new std::string(path);

    return builder;
}

void
da_build_add(da_build_t *builder, char *key, long val)
{
    builder->entries->insert(HashVal(key, val));
}

static int
redump_lex(size_t key_len, std::vector<long>& indices,
	   char* tmpfile, FILE* lexfile)
{
    long index = ftell(lexfile);
    short buf;
    
    buf = (short)key_len;
    fwrite(&buf, sizeof(short), 1, lexfile);
    buf = (short)indices.size();
    fwrite(&buf, sizeof(short), 1, lexfile);
    for (std::vector<long>::iterator i = indices.begin();
	 i != indices.end(); i++) {
	da_lex_t* lex = (da_lex_t*)(tmpfile + *i);
	fwrite(lex, sizeof(da_lex_t), 1, lexfile);
    }

    return index;
}

int
da_build_dump(da_build_t* builder, char* tmpfile, FILE* lexfile)
{
    Hash::iterator i, last;
    Hash* entries = builder->entries;
    char** keys = new char*[entries->size()];
    size_t* lens = new size_t[entries->size()];
    long* vals = new long[entries->size()];
    int size = 0;
    std::vector<long> lex_indices;

    std::cerr << entries->size() << " entries" << std::endl;

    i = entries->begin();
    while (i != entries->end()) {
	const std::string& key = i->first;
	last = entries->upper_bound(key);
	lex_indices.clear();
	for (; i != last; i++) {
	    lex_indices.push_back(i->second);
	}
	lens[size] = key.size();
	keys[size] = (char*) key.data();
	vals[size] = redump_lex(lens[size], lex_indices, tmpfile, lexfile);
	if (vals[size] < 0) {
	    std::cerr << "Unexpected error at " << key << std::endl;
	    cha_exit_perror((char*)"build darts file");
	}
	size++;
    }
    std::cerr << size << " keys" << std::endl;

    DoubleArrayL da;
    da.build(size, (const char**) keys, lens, vals);
    da.save(builder->path->c_str(), "wb");

    return builder->entries->size();
}
