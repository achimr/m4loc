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

from corpustool.lib.logger import log_start
from corpustool.lib.logger import log_done

def run(pcconfig):
    config = pcconfig.config
    src_filename = config.getCorpusFile(config.src, pcconfig.target, config.src)
    target_filename = config.getCorpusFile(config.src, pcconfig.target, pcconfig.target)
    clean_emptyline(src_filename, target_filename)

def clean_emptyline(src_path, target_path):
    srcfile = open(src_path, 'r')
    targetfile = open(target_path, 'r')

    srcfile_emptycleaned = open(src_path + ".emptyclean", 'w')
    targetfile_emptycleaned = open(target_path + ".emptyclean", 'w')

    for srcline in srcfile:
        targetline = targetfile.readline()
        if targetline == None :
            break
        num_src = len(srcline.split())
        num_target = len(targetline.split())
        if not ((num_src == 0) or (num_target == 0)):
            srcfile_emptycleaned.write(srcline)
            targetfile_emptycleaned.write(targetline)

    srcfile_emptycleaned.close()
    targetfile_emptycleaned.close()
    srcfile.close()
    targetfile.close()

    shutil.move(src_path+".emptyclean", src_path)
    shutil.move(target_path+".emptyclean", target_path)
    
if __name__ == "__main__":
    # put unit test here.
    None
