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

"""The config module for parsing the configuration file of conversion."""

import os.path
import sys

import xml.dom.minidom
from xml.dom import DOMException

#from corpustool.lib.lang import isSupportLang
from corpustool.lib.lang import langName
from corpustool.lib.lang import localePairForm

from corpustool.lib.logger import log_done
from corpustool.lib.logger import log_error
from corpustool.lib.logger import log_fail
from corpustool.lib.logger import log_start
from corpustool.lib.logger import log_stderr

class ConfigException(Exception):
    """Base class of CE series Exceptions."""
    def __init__(self, msg):
        self.args = (msg)
        self.message = "Config: " + msg

class CEValidateFailed(ConfigException):
    """Exception when content validation failed."""
    def __init__(self):
        ConfigException.__init__(self, "Validation failed.")

class CEFormatBroken(ConfigException):
    """Exception when xml file format broken."""
    def __init__(self, path):
        ConfigException.__init__(self, "File '{0}' format broken.".format(path))

class CEElemNotFound(ConfigException):
    """Exception when element not found."""
    def __init__(self, tag):
        ConfigException.__init__(self, "Element <{0}> not found.".format(tag))

class CEElemNotUniq(ConfigException):
    """Exception when element should be unique but not."""
    def __init__(self, tag):
        ConfigException.__init__(self, "Element <{0}> not unique.".format(tag))

class CEElemEmpty(ConfigException):
    """Exception when text of element is empty."""
    def __init__(self, tag):
        ConfigException.__init__(self, "Element <{0}> text empty.".format(tag))

def _getElem(parent, tag):
    """Get the element named with parameter tag, throw the appropriate exception when element not found or not unique."""
    elem = parent.getElementsByTagName(tag)
    if len(elem) == 0:
        raise CEElemNotFound(tag)
    elif len(elem) != 1:
        raise CEElemNotUniq(tag)
    return elem[0]

def _getElemText(elem):
    """Get the text of element."""
    if elem.firstChild == None:
        raise CEElemEmpty(elem.tagName)
    return elem.firstChild.data.encode("UTF-8")

class ConversionConfig:
    def __init__(self, path):
        """Construct the config object by parsing and validating the configuration file."""

        # the config data member
        self.project   = None           # project name     :string
        self.exportdir = None           # export directory :path
        self.username  = None           # user name        :string
        self.userpath  = None           # user directory   :path
        self.rawfiles  = None           # raw file list    :list of path
        self.src       = None           # source lang      :string
        self.targets   = None           # target langs     :list of string
        self.stanford_execpath = None        # Stanford Chinese Word Segmenter path :path
        self.stanford_standard = None        # Stanford Chinese Word Segmenter Standard : string

        try:
            log_start("Config")
            log_stderr("Config file: '{0}'".format(path))

            self._readConfig(path)
            self._validateConfig()

            log_done("Config")
        except ConfigException as e:
            log_error(e.message)
            log_fail("Config")
            raise

    def _readConfig(self, path):
        """parse the xml file."""

        log_stderr("Config Reading ...")
        try:
            doc = xml.dom.minidom.parse(path)
        except:
            raise CEFormatBroken(path)

        root = doc.documentElement
        self.project = _getElemText(_getElem(root, "project"))
        self.exportdir = _getElemText(_getElem(root, "exportdir"))

        extensions = _getElem(root, "extensions")
        stanford = _getElem(extensions, "StanfordChineseWordSegmenter")
        stanford_path = _getElem(stanford, "Path")
        if stanford_path.firstChild == None :
            self.stanford_execpath = None
        else:
            self.stanford_execpath = _getElemText(_getElem(stanford, "Path"))
        self.stanford_standard = _getElemText(_getElem(stanford, "Standard"))

        user = _getElem(root, "user")
        self.username = _getElemText(_getElem(user, "name"))
        self.userpath = _getElemText(_getElem(user, "configpath"))

        self.rawfiles = []
        rawfiles = _getElem(root, "rawfiles")
        filelist = rawfiles.getElementsByTagName("file")
        for afile in filelist:
            self.rawfiles.append(_getElemText(afile))

        language = _getElem(root, "language")
        self.src = _getElemText(_getElem(language, "src"))
        self.targets = []
        targetlist = _getElem(language, "targetlist")
        targets = targetlist.getElementsByTagName("target")
        for target in targets:
            self.targets.append(_getElemText(target))

    def _logValidateError(self, msg):
        log_stderr("Validate Error: " + msg)

    def _validateConfig(self):
        """validate the config."""

        log_stderr("Config Validating ...")

        isValidated = True

        self.project = self.project.strip()
        if (len(self.project) == 0):
            self._logValidateError("Empty project name.")
            isValidated = False

        self.exportdir = os.path.expanduser(self.exportdir)
        if (not os.path.isdir(self.exportdir)):
            self._logValidateError("Not existed export directory '{0}'".format(self.exportdir))
            isValidated = False

        self.username = self.username.strip()
        if (len(self.username) == 0):
            self._logValidateError("Empty user name.")
            isValidated = False

        self.userpath = os.path.expanduser(self.userpath)
        if (not os.path.isdir(self.userpath)):
            self._logValidateError("Not existed user directory '{0}'".format(self.userpath))
            isValidated = False

        tmplist = []
        for filepath in self.rawfiles:
            if (os.path.isfile(filepath)):
                tmplist.append(filepath)
            else:
                self._logValidateError("Ignored raw file '{0}'".format(filepath))

        self.rawfiles = []
        self.rawfiles.extend(tmplist)
        if len(self.rawfiles) == 0:
            self._logValidateError("No valid raw file.")
            isValidated = False

        # if (not isSupportLang(self.src)):
        #     self._logValidateError("Src lang {0} not supported.".format(self.src))
        #     isValidated = False

        # tmplist = []
        # for lang in self.targets:
        #     if isSupportLang(lang):
        #         tmplist.append(lang)
        #     else:
        #         self._logValidateError("Ignored target lang {0}".format(lang))
        # self.targets = []
        # self.targets.extend(tmplist)
        if len(self.targets) == 0:
            self._logValidateError("No valid target lang.")
            isValidated = False

        if not isValidated:
            raise CEValidateFailed()

    def getUserDir(self):
        """get the user directory."""
        return self.userpath

    def getPCFilePath(self, src, target):
        """get the path of process config file."""
        return os.path.join(self.userpath, localePairForm(src, target) + ".xml")

    def getProjectDir(self):
        """get the path of project directory."""
        return os.path.join(self.exportdir, self.project)

    def getCorpusDir(self, src, target):
        """get the path of corpus directory for (src, target)."""
        return os.path.join(self.getProjectDir(), localePairForm(src, target))

    def getCorpusFile(self, src, target, lang):
        """get the path of corpus file for lang in (src, target) corpus directory."""
        return self.getNamedCorpusFile(src, target, "Corpus", lang)

    def getNamedCorpusFile(self, src, target, name, lang):
        """get the path of corpus file for lang in (src, target) corpus directory."""
        return os.path.join(self.getCorpusDir(src, target), name + "." + langName(lang))

if __name__ == "__main__":
    # put unit test here.
    pass
