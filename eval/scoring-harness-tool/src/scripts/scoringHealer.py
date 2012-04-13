######################################################################################
##
##    Copyright 2012 Adobe Systems Incorporated
##
##    This file is part of TMX to Moses Corpus Tool.
## 
##    TMX to Moses Corpus Tool is free software: you can redistribute it and/or modify
##    it under the terms of the GNU Lesser General Public License as published by the 
##    Free Software Foundation, either version 3 of the License, or (at your option) 
##    any later version.
## 
##    TMX to Moses Corpus Tool is distributed in the hope that it will be useful,
##    but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
##    or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for 
##    more details.
## 
##    You should have received a copy of the GNU Lesser General Public License along 
##    with TMX to Moses Corpus Tool.  If not, see <http://www.gnu.org/licenses/>.
##
######################################################################################


#! /usr/bin/env python
# -*- coding: utf-8 -*-

import os
import re
import sys
import shutil

def main():
    progname = os.path.basename(sys.argv[0])
    if len(sys.argv) != 7:
        print "Convert Moses corpus file to XML file"
        print "Usage: " + progname + " [Moses corpus file] -t [template file] [source language] [target language] [system name]"
        sys.exit(2)
    else:
        corpusPath = sys.argv[1]
        templatePath = sys.argv[3]
        srcLang = sys.argv[4]
        trgLang = sys.argv[5]
        sysName = sys.argv[6]
        corpusPath = os.path.abspath(corpusPath)
        templatePath = os.path.abspath(templatePath)
        recasedCorpusPath = corpusPath + '.recased'
        outputPath = recasedCorpusPath + '.xml'

        if not os.path.isfile(corpusPath) :
            print progname + ": " + "cannot stat '" + os.path.basename(corpusPath) + "': " + "No such file."
            sys.exit(2)

        elif not os.path.isfile(templatePath) :
            print progname + ": " + "cannot stat '" + os.path.basename(templatePath) + "': " + "No such file."
            sys.exit(2)
        
        try:
            corpusFile = open(corpusPath, 'r')
        except IOError:
            print "Cannot open the file '" + os.path.basename(corpusPath) + "' for reading."
            sys.exit(2)

        try:
            tmplFile = open(templatePath, 'r')
        except IOError:
            print "Cannot open the file '" + os.path.basename(templatePath) + "' for reading."
            sys.exit(2)

        try:
            recasedFile = open(recasedCorpusPath, 'w')
        except IOError:
            print "Cannot open the file '" + os.path.basename(recasedCorpusPath) + "' for reading/writing."
            sys.exit(2)
    
        try:
            sgmFile = open(outputPath, 'w')
        except IOError:
            print "Cannot open the file '" + os.path.basename(outputPath) + "' for writing."
            sys.exit(2)
    
    recase(corpusFile, recasedFile)
    
    recasedFile.close()
    recasedFile = open(recasedCorpusPath, 'r')

    convert(recasedFile, sgmFile, tmplFile, srcLang, trgLang, sysName)
    
    corpusFile.close()
    recasedFile.close()
    tmplFile.close()
    sgmFile.close()
    
def recase(inFile, outFile):
    outFile.writelines([line.strip().capitalize() + "\n" for line in inFile.readlines() if line[:-1].strip()])
    
def convert(inFile, outFile, tmplFile, srcLang, trgLang, sysName):
    pattern_doc = re.compile("^.*<doc .*>$")
    pattern_src = re.compile("^(.* srclang=\")\*(\".*)")
    pattern_trg = re.compile("^(.* trglang=\")\*(\".*)")
    pattern_sys = re.compile("(.* sysid=\")sample_system(\".*)")
    for tmplLine in tmplFile:
    	if pattern_src.match(tmplLine):
    		tmplLine = pattern_src.sub(r'\1%s\2' % srcLang, tmplLine)
    		
    	if pattern_trg.match(tmplLine):
    		tmplLine = pattern_trg.sub(r'\1%s\2' % trgLang, tmplLine)
    		
    	if pattern_sys.match(tmplLine):
    		tmplLine = pattern_sys.sub(r'\1%s\2' % sysName, tmplLine)
    		
    	outFile.write(tmplLine)
    	
    	if pattern_doc.match(tmplLine):
		    lineNum = 0
		    for inline in inFile:
				lineNum += 1
				outLine = '<p><seg id="' + str(lineNum) + '">' + inline.strip() + '</seg></p>\n'
				outFile.write(outLine)

if __name__ == "__main__":
    # put unit test here.
    main()
