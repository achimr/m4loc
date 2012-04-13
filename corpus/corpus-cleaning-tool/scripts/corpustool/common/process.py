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

import sys
import xml.dom.minidom
from xml.dom import Node

from corpustool.lib.config import ConfigException
from corpustool.lib.config import CEFormatBroken
from corpustool.lib.logger import log_stderr
import corpustool.common.commonstep

class ProcessConfig:
    def __init__(self):
        self.src = None
        self.target = None
        self.config = None            # ConvConfig
        self.xml_frag = None

class ProcessEngine:
    def __init__(self):
        self.pc = ProcessConfig()
        self.config = None

    def setConfig(self, config):
        self.pc.config = self.config = config
        self.pc.src = config.src

    def process(self, lang):
        log_stderr(lang + " processing ...")
        # read and verify the src and target.
        src    = self.pc.src = self.config.src
        target = self.pc.target = lang
        pcfile = self.config.getPCFilePath(src, lang)
        try:
            doc = xml.dom.minidom.parse(pcfile)
        except:
            raise CEFormatBroken(pcfile)

        root = doc.documentElement
        srcInXML = root.getAttribute("src")
        targetInXML = root.getAttribute("target")

        if (srcInXML != src) or (targetInXML != target):
            raise CEFormatBroken(pcfile)

        nodelist = root.childNodes
        nodelist = [ node for node in nodelist if node.nodeType == Node.ELEMENT_NODE ]
        nodelist = [ node for node in nodelist if node.getAttribute("enable") == "yes" ]
        for node in nodelist:
            self.pc.xml_frag = node.toxml()
            try:
                moduleName = "corpustool.common." + node.tagName
                module = __import__(moduleName, globals(), locals(), 'filter')
                module.filter(self.pc)
                corpustool.common.commonstep.run(self.pc)
                # sys.modules[moduleName].filter()
            except ImportError:
                if node.hasAttribute("include"):
                    if node.getAttribute("include") == "src":
                        module = self._execModule(node.tagName, src)
                    else:
                        module = self._execModule(node.tagName, target)
                else:
                    module = self._execModule(node.tagName, src)
                    module = self._execModule(node.tagName, target)
                    corpustool.common.commonstep.run(self.pc)

    def _execModule(self, name, lang):
        try:
            moduleName = "corpustool.engine." + lang + "." + name
            module = __import__(moduleName, globals(), locals(), 'filter')
            module.filter(self.pc, lang)
        except ImportError:
            try:
                moduleName = "corpustool.base." + name
                module = __import__(moduleName, globals(), locals(), 'filter')
                module.filter(self.pc, lang)
            except ImportError:
                sys.stderr.write("No such module: {0} for {1}\n".format(name, lang))

if __name__ == "__main__":
    # put unit test here.
    pass
