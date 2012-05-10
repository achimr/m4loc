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

def main():
    progname = os.path.basename(sys.argv[0])
    if ( len(sys.argv) != 3) and (len(sys.argv) != 1 ):
        print "De-token the wrong tokenized token sequence into correct token."
        print "usage: " + progname + " [infile outfile]"
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

    detoken(infile, outfile)
    infile.close()
    outfile.close()

def detoken(infile, outfile):
    for line in infile:
        line = re.sub(r'{ (\d+) }', r'{\1}', line)
        line = line.replace('( )', '()')
        outfile.write(line)

if __name__ == "__main__":
    # put unit test here.
    main()
