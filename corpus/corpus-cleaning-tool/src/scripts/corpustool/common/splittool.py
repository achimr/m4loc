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

from corpustool.lib.lang   import localePairForm

from corpustool.lib.logger import log_done
from corpustool.lib.logger import log_error
from corpustool.lib.logger import log_fail
from corpustool.lib.logger import log_start
from corpustool.lib.logger import log_stderr
from corpustool.lib.logger import log_warning

from corpustool.lib.splitter import Splitter
from corpustool.lib.splitexception import SplitException

class CorpusFilePool:
    """CorpusFilePool store all the corpus open file descriptors. The splitter should have an instance of filepool, and
    get the file descriptor when write the seg into corpus file."""

    def __init__(self):
        self.fmap = {}

    def setMapping(self, src, target, src_fp, target_fp):
        self.fmap[(src, target)] = (src_fp, target_fp)

    def fps(self, langs):
        (src_fp, target_fp) = (None, None)
        (src, target) = langs
        if langs in self.fmap:
            (src_fp, target_fp) = self.fmap[langs]
        elif (target, src) in self.fmap:
            (target_fp, src_fp) = self.fmap[(target, src)]
        return (src_fp, target_fp)

    def isEmpty(self):
        return (len(self.fmap.keys()) == 0)

    def closeFiles(self):
        for k, v in self.fmap.iteritems():
            (src, target) = v
            src.close()
            target.close()

    def clean(self):
        self.fmap = {}

class SplitTool:
    def __init__(self):
        self.filepool = CorpusFilePool()
        self.splitter = Splitter()
        self.splitter.setFilepool(self.filepool)
        self.config = None

    def setConfig(self, config):
        self.config = config

    def _prepare(self):
        """Prepare the corpus directory hierarchy."""

        log_stderr("Preparing corpus directory hierarchy ...")

        # prepare the project directory.
        projPath = self.config.getProjectDir()
        if not os.path.exists(projPath):
            os.mkdir(projPath)
            log_stderr("Creating project directory.")

        # create the directory for corpus if necessary, clean the Corpus.en/zh file. if cannot open the corpus file,
        # remove the target language from the list, so will not do the process for that target language.
        srclang = self.config.src
        targets = self.config.targets[:] # same as: targets = list(self.config.targets)
        for targetlang in targets:
            log_stderr("")
            log_stderr(localePairForm(srclang, targetlang))
            corpusDirPath = self.config.getCorpusDir(srclang, targetlang)
            if not os.path.exists(corpusDirPath):
                os.mkdir(corpusDirPath)
                log_stderr("Creating corpus directory '{0}'.".format(corpusDirPath))

            log_stderr("Cleaning the corpus files ...")
            srcCorpusFile    = self.config.getCorpusFile(srclang, targetlang, srclang)
            targetCorpusFile = self.config.getCorpusFile(srclang, targetlang, targetlang)
            srcfile = None
            targetfile = None
            try:
                srcfile    = open(srcCorpusFile, 'w')
                targetfile = open(targetCorpusFile, 'w')
                log_stderr("Cleaned: {0}".format(srcCorpusFile))
                log_stderr("Cleaned: {0}".format(targetCorpusFile))
            except IOError as e:
                self.config.targets.remove(targetlang)
                log_stderr(str(e))
            finally:
                if srcfile:
                    srcfile.close()
                if targetfile:
                    targetfile.close()

    def fillPool(self, filename):
        fname = self._pureName(filename)
        srclang = self.config.src
        for targetlang in self.config.targets:
            srcCorpusFile    = self.config.getNamedCorpusFile(srclang, targetlang, fname, srclang)
            targetCorpusFile = self.config.getNamedCorpusFile(srclang, targetlang, fname, targetlang)
            srcfile    = open(srcCorpusFile, 'w')
            targetfile = open(targetCorpusFile, 'w')
            self.filepool.setMapping(srclang, targetlang, srcfile, targetfile)

    def generateCorpus(self):
        log_start("Split")
        self._prepare()
        if ( len(self.config.targets) == 0 ):
            raise SplitException("Prepare the directory failed.")

        filelist = []
        for afile in self.config.rawfiles:
            try:
                log_start("Split {0}".format(afile))
                self.fillPool(afile)
                self.splitter.split(afile)
                self.filepool.closeFiles()
                self.filepool.clean()
                filelist.append(afile)
                log_done("Split {0}".format(afile))
            except SplitException as e:
                log_warning(e.message)
                # TODO: del the files when failed.
                log_fail("Split {0}".format(afile))

        if filelist == [] :
            log_error("No corpus file generated.")
            log_fail("Split")
        else:
            self.mergeCorpus(filelist)
            log_done("Split")

    def _pureName(self, filename):
        basename = os.path.basename(filename)
        (name, sep, ext) = basename.rpartition('.')
        return name

    def _mergeFiles(self, filelist, src, target, lang):
        corpus = self.config.getCorpusFile(src, target, lang)
        cf = open(corpus, "w")
        for afile in filelist:
            with open(afile, "r") as f:
                for line in f:
                    cf.write(line)
        cf.close()
        corpus_orig = corpus + ".orig"
        shutil.copyfile(corpus, corpus_orig)

    def mergeCorpus(self, filelist):
        srclang = self.config.src
        for targetlang in self.config.targets:
            slist = [ self.config.getNamedCorpusFile(srclang, targetlang, self._pureName(filename), srclang) for filename in filelist]
            tlist = [ self.config.getNamedCorpusFile(srclang, targetlang, self._pureName(filename), targetlang) for filename in filelist]
            self._mergeFiles(slist, srclang, targetlang, srclang)
            self._mergeFiles(tlist, srclang, targetlang, targetlang)
            for file in slist:
                os.remove(file)
            for file in tlist:
                os.remove(file)

if __name__ == "__main__":
    # put unit test here.
    pass
