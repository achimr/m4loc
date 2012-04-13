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

# every import should be guaranteed work, else the module will throw the import exception.
from corpustool.lib.logger import log_start
from corpustool.lib.logger import log_done

def filter(pcconfig, lang):
    log_start("url_clean " + lang)
    ext = ".urlclean"
    config = pcconfig.config
    filename = config.getCorpusFile(config.src, pcconfig.target, lang)
    infile = open(filename, "r")
    outfile = open(filename + ext, "w")

    # [Protocol] [Username:Password] Subdomains TopLevelDomains [Port] [Directory] [Query] [Anchor]
    # please to read the re pattern carefully to understand it.
    # reference: http://flanders.co.nz/2009/11/08/a-good-url-regular-expression-repost/
    # A blog posted by Ivan Porto Carrero.

    # The last group ($|<|{) will be used as \1 again. Cannot use the [$<{] , since the $ is not special in [].
    #urlPattern = r'((?#Protocol)(?:(?:ht|f)tp(?:s?)\:\/\/|~\/|\/)?(?#Username:Password)(?:\w+:\w+@)?(?#Subdomains)(?:(?:[-\w]+\.)+(?#TopLevel Domains)(?:com|org|net|gov|mil|biz|info|mobi|name|aero|jobs|museum|travel|[a-z]{2}))(?#Port)(?::[\d]{1,5})?(?#Directories)(?:(?:(?:\/(?:[-\w~!$+|.,=]|%[a-f\d]{2})+)+|\/)+|\?|#)?(?#Query)(?:(?:\?(?:[-\w~!$+|.,*:]|%[a-f\d{2}])+=?(?:[-\w~!$+|.,*:=]|%[a-f\d]{2})*)(?:&(?:[-\w~!$+|.,*:]|%[a-f\d{2}])+=?(?:[-\w~!$+|.,*:=]|%[a-f\d]{2})*)*)*(?#Anchor)(?:#(?:[-\w~!$+|.,*:=]|%[a-f\d]{2})*)?)($|<|{)'

    # \1 <==> $|<|{
    # line = re.sub( urlPattern, r'\1', line)

    # Match the url when is followed by $, < , {. Mostly url should be ended with $, but is followed by < before
    # phtag_clean and by { after phtag_clean.
    urlPattern = r'((?#Protocol)(?:(?:ht|f)tp(?:s?)\:\/\/|~\/|\/)?(?#Username:Password)(?:\w+:\w+@)?(?#Subdomains)(?:(?:[-\w]+\.)+(?#TopLevel Domains)(?:com|org|net|gov|mil|biz|info|mobi|name|aero|jobs|museum|travel|[a-z]{2}))(?#Port)(?::[\d]{1,5})?(?#Directories)(?:(?:(?:\/(?:[-\w~!$+|.,=]|%[a-f\d]{2})+)+|\/)+|\?|#)?(?#Query)(?:(?:\?(?:[-\w~!$+|.,*:]|%[a-f\d{2}])+=?(?:[-\w~!$+|.,*:=]|%[a-f\d]{2})*)(?:&(?:[-\w~!$+|.,*:]|%[a-f\d{2}])+=?(?:[-\w~!$+|.,*:=]|%[a-f\d]{2})*)*)*(?#Anchor)(?:#(?:[-\w~!$+|.,*:=]|%[a-f\d]{2})*)?)(?=($|<|{))'

    line_count = 0
    for line in infile:
        line_count += 1
        list_matched = re.findall(urlPattern, line)
        # TODO: log, not print
        # for x, y in list_matched:
        #     print str(line_count) + " : " + x
        line = re.sub( urlPattern, r'', line)
        outfile.write(line)

    infile.close()
    outfile.close()
    shutil.copyfile(filename + ext, filename)
    log_done("url_clean " + lang)
#    shutil.move(filename + ext, filename)



if __name__ == "__main__":
    # put unit test here.
    pass
