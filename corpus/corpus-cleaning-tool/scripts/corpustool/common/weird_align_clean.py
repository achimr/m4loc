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
    log_start("diff_align")
    ext = ".diff_align"
    config = pcconfig.config
    src_filename = config.getCorpusFile(config.src, pcconfig.target, config.src)
    target_filename = config.getCorpusFile(config.src, pcconfig.target, pcconfig.target)
    xml = pcconfig.xml_frag
    doc = parseString(xml)
    elems = doc.getElementsByTagName("diff")
    diff_threshold = int(elems[0].firstChild.data)
    clean_weird_diff_align(src_filename, target_filename, diff_threshold)
    log_done("diff_align")

def main():
    main_difference()
    # main_ratio()

def main_difference():
    progname = sys.argv[0]

    usage = """%prog src-corpus target-corpus threshold
Clean the wired-align sentences according to threshold for difference of token number between source and target."""

    parser = OptionParser(usage, version="%prog 0.2")

    (options, args) = parser.parse_args()
    if len(args) != 3 :
        parser.error("wrong arguments.")

    src_path, target_path, threshold_str = args

    if not threshold_str.isdigit() :
        parser.error("threshold must be an integer.")
    threshold = int(threshold_str)

    src_path = os.path.abspath(src_path)
    target_path = os.path.abspath(target_path)

    if not os.path.isfile(src_path) :
        print progname + ": " + "cannot stat '" + os.path.basename(src_path) + "': " + "No such file."
        sys.exit(2)

    if not os.path.isfile(target_path) :
        print progname + ": " + "cannot stat '" + os.path.basename(target_path) + "': " + "No such file."
        sys.exit(2)

    try:
        srcfile = open(src_path, 'r+')
    except IOError:
        print "Cannot open the file '" + os.path.basename(src_path) + "' for reading and writing."
        sys.exit(2)
    srcfile.close()

    try:
        targetfile = open(target_path, 'r+')
    except IOError:
        print "Cannot open the file '" + os.path.basename(target_path) + "' for reading and writing."
        sys.exit(2)
    targetfile.close()

    clean_weird_diff_align(src_path, target_path, threshold)

def clean_weird_diff_align(src_path, target_path, threshold):
    srcfile = open(src_path, 'r')
    targetfile = open(target_path, 'r')

    srcfile_weirdcleaned = open(src_path + ".weirdcleaned", 'w')
    targetfile_weirdcleaned = open(target_path + ".weirdcleaned", 'w')

    for srcline in srcfile:
        targetline = targetfile.readline()
        if targetline == None :
            break
        num_src = len(srcline.split())
        num_target = len(targetline.split())
        if not is_weird_diff_align(num_src, num_target, threshold) :
            srcfile_weirdcleaned.write(srcline)
            targetfile_weirdcleaned.write(targetline)

    srcfile_weirdcleaned.close()
    targetfile_weirdcleaned.close()
    srcfile.close()
    targetfile.close()

    shutil.copyfile(src_path+".weirdcleaned", src_path)
    shutil.copyfile(target_path+".weirdcleaned", target_path)

    # shutil.move(src_path+".weirdcleaned", src_path)
    # shutil.move(target_path+".weirdcleaned", target_path)

def is_weird_diff_align(num_src, num_target, threshold) :
    if ( num_src == 0 ) or (num_target == 0 ):
        return True
    diff = abs( num_src - num_target )
    return True if ( diff > threshold ) else False

def main_ratio():
    progname = sys.argv[0]

    usage = """%prog [options] src-corpus target-corpus
Clean the wired-align sentences according to threshold of token number src/target."""

    parser = OptionParser(usage, version="%prog 0.1")
    parser.add_option("-g", "--greater", dest="threshold_g", metavar="THRESHOLD", type="float",
                      help="set the threshold for greater predication.")
    parser.add_option("-l", "--less", dest="threshold_l", metavar="THRESHOLD", type="float",
                      help="set the threshold for less predication.")
    (options, args) = parser.parse_args()
    if len(args) != 2 :
        parser.error("wrong arguments.")

    if (options.threshold_g == None) and (options.threshold_l == None) :
        parser.error("please specify one threshold.")

    if (options.threshold_g != None ) and (options.threshold_l != None) :
        parser.error("only one threshold can be specified now.")

    src_path, target_path = args
    src_path = os.path.abspath(src_path)
    target_path = os.path.abspath(target_path)

    if not os.path.isfile(src_path) :
        print progname + ": " + "cannot stat '" + os.path.basename(src_path) + "': " + "No such file."
        sys.exit(2)

    if not os.path.isfile(target_path) :
        print progname + ": " + "cannot stat '" + os.path.basename(target_path) + "': " + "No such file."
        sys.exit(2)

    try:
        srcfile = open(src_path, 'r+')
    except IOError:
        print "Cannot open the file '" + os.path.basename(src_path) + "' for reading and writing."
        sys.exit(2)
    srcfile.close()

    try:
        targetfile = open(target_path, 'r+')
    except IOError:
        print "Cannot open the file '" + os.path.basename(target_path) + "' for reading and writing."
        sys.exit(2)
    targetfile.close()

    clean_weird_ratio_align(src_path, target_path, options.threshold_g, options.threshold_l)

def is_weird_ratio_align(num_src, num_target, th_g, th_l) :
    if ( num_src == 0 ) or (num_target == 0 ):
        return True
    ratio = float(num_src)/float(num_target)

    if th_g == None :
        return True if ( ratio < th_l ) else False
    else:
        return True if ( ratio > th_g ) else False

def clean_weird_ratio_align(src_path, target_path, th_g, th_l):
    srcfile = open(src_path, 'r')
    targetfile = open(target_path, 'r')

    srcfile_weirdcleaned = open(src_path + ".weirdcleaned", 'w')
    targetfile_weirdcleaned = open(target_path + ".weirdcleaned", 'w')

    for srcline in srcfile:
        targetline = targetfile.readline()
        if targetline == None :
            break
        num_src = len(srcline.split())
        num_target = len(targetline.split())
        if not is_weird_ratio_align(num_src, num_target, th_g, th_l) :
            srcfile_weirdcleaned.write(srcline)
            targetfile_weirdcleaned.write(targetline)

    srcfile_weirdcleaned.close()
    targetfile_weirdcleaned.close()
    srcfile.close()
    targetfile.close()

    shutil.move(src_path+".weirdcleaned", src_path)
    shutil.move(target_path+".weirdcleaned", target_path)

if __name__ == "__main__":
    # put unit test here.
    main()
