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
import sys

from optparse import OptionParser
from xml.dom.minidom import parse, parseString

from corpustool.lib.logger import log_start
from corpustool.lib.logger import log_done

def filter(pcconfig):
    log_start("extra_long")
    ext = ".extra_long"
    config = pcconfig.config
    src_filename = config.getCorpusFile(config.src, pcconfig.target, config.src)
    target_filename = config.getCorpusFile(config.src, pcconfig.target, pcconfig.target)
    xml = pcconfig.xml_frag
    doc = parseString(xml)
    elems = doc.getElementsByTagName("source")
    source_threshold = int(elems[0].firstChild.data)
    elems = doc.getElementsByTagName("target")
    target_threshold = int(elems[0].firstChild.data)
    print source_threshold, target_threshold

    cleaner = ExtraLongCleaner(src_filename, target_filename, source_threshold, target_threshold)
    cleaner.clean()
    log_done("extra_long")

class ExtraLongCleaner():
    def __init__(self, src_path=None, target_path=None, src_t=None, target_t=None):
        self._src_path    = src_path
        self._target_path = target_path
        self._src_t       = src_t
        self._target_t    = target_t

    def parseCmdline(self):
        progname = sys.argv[0]
        usage="""%prog [OPTION...] src-corpus target-corpus"""
        # print "Extra-long cleaner (0.2) ljiang@adobe.com"
        # print "Clean the extra-long sentences according to threshold for both/either of source and target."

        parser = OptionParser(usage, version="%prog 0.2")
        parser.add_option("-s", "--src-threshold", dest="src", metavar="SRC-THRESHOLD", type="int",
                          help="set the threshold of source corpus for cleaning extra-long sentences.")
        parser.add_option("-t", "--target-threshold", dest="target", metavar="TARGET-THRESHOLD", type="int",
                          help="set the threshold of target corpus for cleaning extra-long sentences.")
        (options, args) = parser.parse_args()
        if len(args) != 2 :
            sys.stderr.write("FAILED: Extra Long Cleaner.\n")
            sys.stderr.write("-" * 80 + os.linesep)
            parser.error("wrong arguments.")

        if (options.src == None) and (options.target == None) :
            sys.stderr.write("FAILED: Extra Long Cleaner.\n")
            sys.stddrr.write("-" * 80 + os.linesep)
            parser.error("require at least one threshold.")

        self._src_t    = options.src
        self._target_t = options.target

        src_path, target_path = args
        self._src_path = os.path.abspath(src_path)
        self._target_path = os.path.abspath(target_path)

        try:
            srcfile = open(src_path, 'r')
        except IOError, e:
            sys.stderr.write("FAILED: Extra Long Cleaner.\n")
            sys.stderr.write("-" * 80 + os.linesep)
            sys.stderr.write(str(e))
            sys.exit(e.errno)
        else:
           srcfile.close()

        try:
            targetfile = open(target_path, 'r')
        except IOError, e:
            sys.stderr.write("FAILED: Extra Long Cleaner.\n")
            sys.stderr.write("-" * 80 + os.linesep)
            sys.stderr.write(str(e))
            sys.exit(e.errno)
        else:
            targetfile.close()

    def _isExtraLong(self, src_num, target_num):
        if self._src_t == None:
            return True if (target_num > self._target_t) else False
        if self._target_t == None:
            return True if (src_num > self._src_t) else False

        return True if (src_num > self._src_t) and (target_num > self._target_t) else False

    def clean(self):
        srcfile = open(self._src_path, 'r')
        targetfile = open(self._target_path, 'r')

        srcfile_longcleaned = open(self._src_path + ".longcleaned", 'w')
        targetfile_longcleaned = open(self._target_path + ".longcleaned", 'w')

        for srcline in srcfile:
            targetline = targetfile.readline()
            if targetline == None :
                break
            num_src = len(srcline.split())
            num_target = len(targetline.split())
            if self._isExtraLong(num_src, num_target):
                pass
            else:
                srcfile_longcleaned.write(srcline)
                targetfile_longcleaned.write(targetline)

        srcfile_longcleaned.close()
        targetfile_longcleaned.close()
        srcfile.close()
        targetfile.close()

        shutil.copyfile(self._src_path+".longcleaned", self._src_path)
        shutil.copyfile(self._target_path+".longcleaned", self._target_path)

        # shutil.move(self._src_path+".longcleaned", self._src_path)
        # shutil.move(self._target_path+".longcleaned", self._target_path)

if __name__ == "__main__":
    cleaner = ExtraLongCleaner()
    cleaner.parseCmdline()
    cleaner.clean()
