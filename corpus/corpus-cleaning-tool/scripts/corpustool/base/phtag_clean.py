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

import re
import shutil

from corpustool.lib.logger import log_start
from corpustool.lib.logger import log_done

def filter(pcconfig, lang):
    log_start("phtag_clean " + lang)
    ext = ".tagclean"
    config = pcconfig.config
    filename = config.getCorpusFile(config.src, pcconfig.target, lang)
    infile = open(filename, "r")
    outfile = open(filename + ext, "w")

    pattern = re.compile("<ph(?:\s+[\w=\"]*)*>(\{\d+\})<\/ph>")

    for line in infile:
        line = re.sub(pattern, r'\1', line)
        outfile.write(line)

    infile.close()
    outfile.close()
    shutil.copyfile(filename + ext, filename)
#    shutil.move(filename + ext, filename)
    log_done("phtag_clean " + lang)

if __name__ == "__main__":
    # put unit test here.
    pass
