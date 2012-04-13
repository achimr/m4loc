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

"""Conversion module."""

import os.path

from corpustool.common.process   import ProcessEngine
from corpustool.common.splittool import SplitTool

from corpustool.lib.config  import ConfigException
from corpustool.lib.lang    import localePairForm
from corpustool.lib.logger  import log_stderr
from corpustool.lib.logger  import log_start
from corpustool.lib.logger  import log_done

class Conversion:
    """A conversion will create the corpus directory hierarchy and clean the corpus file according to configuration.
    Then invoke the split tool to generate the corpus files and filter the corpus files thru process engine."""

    def __init__(self, config):
        self.config = config

    def run(self):
        splittool = SplitTool()
        splittool.setConfig(self.config)
        splittool.generateCorpus()

        engine = ProcessEngine()
        engine.setConfig(self.config)

        for lang in self.config.targets:
            try:
                engine.process(lang)
            except ConfigException as e:
                print e.message

if __name__ == "__main__":
    # put unit test here.
    pass
