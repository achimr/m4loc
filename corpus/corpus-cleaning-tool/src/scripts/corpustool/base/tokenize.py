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

import os
import shutil
import re

from corpustool.lib.lang import langName
from corpustool.lib.logger import log_start
from corpustool.lib.logger import log_done

def filter(pcconfig, lang):
    log_start("tokenize " + lang)
    ext = ".tok"
    config = pcconfig.config
    filename = config.getCorpusFile(config.src, pcconfig.target, lang)

    # normalize the lines.
    infile = open(filename, "r")
    outfile = open(filename + ".tmp", "w")

    normalize(infile, outfile)
    infile.close()
    outfile.close()
    shutil.copyfile(filename + ".tmp", filename)

    scriptpath = "./corpustool/third-party/scripts/"
    scriptname = "tokenizer.perl"
    scriptparams = " -l " + langName(lang) + " < " + '"'+ filename +'"' + " > " + '"'+ filename+ext +'"' + " 2> /dev/null"
    scriptcmd = scriptpath + scriptname + scriptparams
    print scriptcmd
    os.system(scriptcmd)

    infile = open(filename + ext , "r")
    outfile = open(filename + ext + ".detok", "w")

    detoken(infile, outfile)
    infile.close()
    outfile.close()
    shutil.copyfile(filename + ext + ".detok", filename)
#    shutil.move(filename + ext, filename)
    log_done("tokenize " + lang)

def detoken(infile, outfile):
    for line in infile:
        line = re.sub(r'{ (\d+) }', r'{\1}', line)
        line = line.replace('( )', '()')
        outfile.write(line)

def normalize(infile, outfile):
    for line in infile:
        line = re.sub(r'[ \t\r\v\f]', r' ', line)
        line = line.replace('|', 'vl')
        outfile.write(line)

if __name__ == "__main__":
    # put unit test here.
    pass
