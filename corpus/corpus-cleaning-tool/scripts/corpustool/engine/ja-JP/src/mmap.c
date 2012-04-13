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
 * $Id: mmap.c,v 1.1.1.1 2007/03/13 07:40:10 masayu-a Exp $
 */

#include "config.h"

#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_FCNTL_H
#include <fcntl.h>
#endif
#ifdef HAVE_SYS_STAT_H
#include <sys/stat.h>
#endif
#ifdef HAVE_SYS_TYPES_H
#include <sys/types.h>
#endif
#ifdef HAVE_SYS_PARAM_H
#include <sys/param.h>
#endif

#ifdef __MINGW32__
#undef HAVE_MMAP
#endif
#ifdef HAVE_MMAP
#include <sys/mman.h>
#endif

#if !defined HAVE_MMAP && defined HAVE_WINDOWS_H
#include <windows.h>
#endif

#if ! defined _WIN32 && ! defined __CYGWIN__
#define O_BINARY 0
#endif

#ifndef HAVE_MMAP
#define PROT_WRITE  2
#define PROT_READ   1
#endif

#include "chalib.h"

struct _cha_mmap_t {
    void *map;
    off_t size;
#if !defined HAVE_MMAP && defined HAVE_WINDOWS_H
    HANDLE hfile;
    HANDLE hmap;
#endif
};

static cha_mmap_t *
mmap_file(char *filename, int prot)
{
    cha_mmap_t *mm;
#if !defined HAVE_MMAP && defined HAVE_WINDOWS_H
    unsigned long file_mode, map_mode, view_mode;
#else
    int fd;
    int flag = O_RDONLY;
    struct stat st;
#endif

    mm = cha_malloc(sizeof(cha_mmap_t));

#if !defined HAVE_MMAP && defined HAVE_WINDOWS_H
    if ((prot & PROT_WRITE) != 0) {
	file_mode = GENERIC_READ | GENERIC_WRITE;
	map_mode = PAGE_READWRITE;
	view_mode = FILE_MAP_WRITE;
    } else {
	file_mode = GENERIC_READ;
	map_mode = PAGE_READONLY;
	view_mode = FILE_MAP_READ;
    }

    mm->hfile = CreateFile(filename, file_mode, FILE_SHARE_READ, NULL,
			   OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
    if (mm->hfile == INVALID_HANDLE_VALUE)
        cha_exit_perror(filename);

    mm->size = GetFileSize(mm->hfile, NULL);

    mm->hmap = CreateFileMapping(mm->hfile, NULL, map_mode, 0, 0, NULL);
    if (mm->hmap == NULL) {
	CloseHandle(mm->hfile);
	cha_exit_perror(filename);
    }
				
    mm->map = MapViewOfFile(mm->hmap, view_mode, 0, 0, 0);
    if (mm->map == NULL) {
	CloseHandle(mm->hfile);
	CloseHandle(mm->hmap);
	cha_exit_perror(filename);
    }

#else /* !defined HAVE_MMAP && defined HAVE_WINDOWS_H */
    if ((prot & PROT_WRITE) != 0)
	flag = O_RDWR;
	
    if ((fd = open(filename, flag)) < 0)
	cha_exit_perror(filename);
    if (fstat(fd, &st) < 0)
	cha_exit_perror(filename);
    mm->size = st.st_size;
#ifdef HAVE_MMAP
    if ((mm->map = mmap((void *)0, mm->size, prot, MAP_SHARED, fd, 0))
	== MAP_FAILED) {
	cha_exit_perror(filename);
    }
#else /* HAVE_MMAP */
    mm->map = cha_malloc(mm->size);
    if (read(fd, mm->map, mm->size) < 0)
	cha_exit_perror(filename);
#endif /* HAVE_MMAP */
    close(fd);

#endif /* HAVE_MMAP && defined HAVE_WINDOWS_H */
    return mm;
}

cha_mmap_t *
cha_mmap_file(char *filename)
{
    return mmap_file(filename, PROT_READ);
}

cha_mmap_t *
cha_mmap_file_w(char *filename)
{
    return mmap_file(filename, PROT_READ | PROT_WRITE);
}

void
cha_munmap_file(cha_mmap_t *mm)
{
#if !defined HAVE_MMAP && defined HAVE_WINDOWS_H
    UnmapViewOfFile(mm->map);
    CloseHandle(mm->hmap);
    CloseHandle(mm->hfile);
#else /* !defined HAVE_MMAP && defined HAVE_WINDOWS_H */
#ifdef HAVE_MMAP
    munmap(mm->map, mm->size);
#else /* HAVE_MMAP */
    cha_free(mm->map);
#endif /* HAVE_MMAP */
#endif /* !defined HAVE_MMAP && defined HAVE_WINDOWS_H */
    cha_free(mm);
}

void *
cha_mmap_map(cha_mmap_t *mm)
{
    return mm->map;
}

off_t
cha_mmap_size(cha_mmap_t *mm)
{
    return mm->size;
}
