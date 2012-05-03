#! /usr/bin/env python
# -*- coding: utf-8 -*-

# Copyright 2012 Adobe Systems Incorporated
#
# This file is part of TMX to Moses Corpus Tool.
#
# TMX to Moses Corpus Tool is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# TMX to Moses Corpus Tool is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with TMX to Moses Corpus Tool  If not, see <http://www.gnu.org/licenses/>.

import shutil
import sys
from xml.dom.minidom import parse, parseString

from corpustool.lib.logger import log_start
from corpustool.lib.logger import log_done

def filter(pcconfig):
    log_start("dup_clean")
    ext = ".dupclean"
    config = pcconfig.config
    src_filename = config.getCorpusFile(config.src, pcconfig.target, config.src)
    target_filename = config.getCorpusFile(config.src, pcconfig.target, pcconfig.target)
    xml = pcconfig.xml_frag
    doc = parseString(xml)
    elems = doc.getElementsByTagName("restricted")
    isRestricted = True if (elems[0].firstChild.data) == "yes" else False
    cleanDup(src_filename, target_filename, isRestricted)

    # cleaner = ExtraLongCleaner(src_filename, target_filename, source_threshold, target_threshold)
    # cleaner.clean()
    log_done("dup_clean")

def cleanDup(src_filename, target_filename, isRestricted):
    align_pool = set()
    srcfile = open(src_filename, 'r')
    targetfile = open(target_filename, 'r')

    ext = ".dupcleaned"
    srcfile_dupcleaned = open(src_filename + ext, 'w')
    targetfile_dupcleaned = open(target_filename + ext, 'w')

    for srcline in srcfile:
        targetline = targetfile.readline()
        if targetline == None :
            break
        if isRestricted:
            elem = (srcline, targetline)
        else:
            elem = (srcline)
        if elem not in align_pool:
            align_pool.add(elem)
            srcfile_dupcleaned.write(srcline)
            targetfile_dupcleaned.write(targetline)

    srcfile_dupcleaned.close()
    targetfile_dupcleaned.close()
    srcfile.close()
    targetfile.close()
    shutil.copyfile(src_filename + ext, src_filename)
    shutil.copyfile(target_filename + ext, target_filename)

if __name__ == "__main__":
    # put unit test here.
    pass
