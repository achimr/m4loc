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

from xml.sax import make_parser
from xml.sax import SAXException
from xml.sax.handler import ContentHandler
from xml.sax.handler import ErrorHandler

from corpustool.lib.splitexception import SplitException

class TmxContentHandler(ContentHandler):
    def __init__(self):
        self.inSeg = False
        self.lang = ""
        self.text = ""
        self.align = {}
        self.fpool = None

    def startElement(self, name, attr):
        if (name == "tuv"):
            self.lang = attr.getValue("xml:lang")
        elif (name == "seg"):
            self.text = ""
            self.inSeg = True
        elif (self.inSeg):
            # construct the element begin tag in <seg> back.
            # maybe it's different to original text but only in attribute part and namespace.
            attrlist = [ attrname + "=" + '"'+ attr.getValue(attrname) +'"' for attrname in attr.getNames() ]
            attrstr = " ".join(attrlist)
            tagheader = "<" + name + " " + attrstr + ">"
            self.text += tagheader

    def endElement(self, name):
        if (name == "tu"):
            fplist = list(self.fpool.fps(tuple(self.align.keys())))
            if fplist != [None, None]:
                for i, v in enumerate(self.align.values()):
                    v = v.replace('\n', ' ')
                    fplist[i].write( (v + os.linesep).encode("UTF-8"))
            self.align = {}
        elif (name == "seg"):
            self.align[self.lang] = self.text
            self.text = ""
            self.inSeg = False
        elif (self.inSeg):
            tagtail = "</" + name + ">"
            self.text += tagtail

    def characters(self, content):
        if (self.inSeg):
            self.text += content

    def setFilepool(self, filepool):
        self.fpool = filepool

class TmxErrorHandler(ErrorHandler):
    """Raise the error and fatal error exception, and ignore the warning."""
    def error(self, exception):
        raise SplitException(exception.getMessage())

    def fatalError(self, exception):
        raise SplitException(exception.getMessage())

    def warning(self, exception):
        pass

class SAXSplit():
    def __init__(self):
        self.saxparser = make_parser()
        self.saxparser.setContentHandler(TmxContentHandler())
        self.saxparser.setErrorHandler(TmxErrorHandler())

    def setFilepool(self, filepool):
        self.saxparser.getContentHandler().setFilepool(filepool)

    def split(self, filename):
        self.saxparser.parse(open(filename))

if __name__ == "__main__":
    # put unit test here.
    pass
