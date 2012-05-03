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
import re
import sys
import shutil

from corpustool.lib.logger import log_start
from corpustool.lib.logger import log_done

def filter(pcconfig, lang):
    log_start("num_clean " + lang)
    ext = ".numclean"
    config = pcconfig.config
    filename = config.getCorpusFile(config.src, pcconfig.target, lang)
    infile = open(filename, "r")
    outfile = open(filename + ext, "w")
    cleanNum(infile, outfile)
    infile.close()
    outfile.close()
    shutil.copyfile(filename + ext, filename)
    log_done("num_clean " + lang)
#    shutil.move(filename + ext, filename)

def main():
    # comment the import statement about logger when testing.
    progname = os.path.basename(sys.argv[0])
    if ( len(sys.argv) != 3) and (len(sys.argv) != 1 ):
        print "Clean the numbers from corpus file."
        print "Usage: " + progname + " [infile outfile]"
        print "       " + progname + " < infile > outfile "
        sys.exit(2)
    elif ( len(sys.argv) == 3 ):
        srcPath, destPath = sys.argv[1:]
        srcPath = os.path.abspath(srcPath)
        destPath = os.path.abspath(destPath)

        if not os.path.isfile(srcPath) :
            print progname + ": " + "cannot stat '" + os.path.basename(srcPath) + "': " + "No such file."
            sys.exit(2)

        try:
            infile = open(srcPath, 'r')
        except IOError:
            print "Cannot open the file '" + os.path.basename(srcPath) + "' for reading."
            sys.exit(2)

        try:
            outfile = open(destPath, 'w')
        except IOError:
            print "Cannot open the file '" + os.path.basename(destPath) + "' for writing."
            infile.close()
            sys.exit(2)

    else:
        infile = sys.stdin
        outfile = sys.stdout

    cleanNum(infile, outfile)
    infile.close()
    outfile.close()

def cleanNum(infile, outfile):
    pattern_float = re.compile("^[-+]?(\d+(\.\d*)?|\.\d+)([eE][-+]?\d+)?$")  # %e, %E, %f, %g
    pattern_hex = re.compile("^[-+]?(0[xX][\dA-Fa-f]+|0[0-7]*|\d+)$")        # %i
    pattern_expression = re.compile("^[0123456789,_+\-\*/]+$") # expression, date, 127,6 or 23-45
    pattern_us_currency = re.compile("^(\d{1,3})(\,\d{3})*$")
    for inline in infile:
        tokens = inline.split()
        tokens = [ token for token in tokens if not pattern_float.match(token) ]
        tokens = [ token for token in tokens if not pattern_us_currency.match(token) ]
        tokens = [ token for token in tokens if not pattern_hex.match(token) ]
        tokens = [ token for token in tokens if not pattern_expression.match(token) ]
        if tokens == [] :
            outfile.write('\n')
        else:
            outfile.write(inline)

if __name__ == "__main__":
    # put unit test here.
    main()
