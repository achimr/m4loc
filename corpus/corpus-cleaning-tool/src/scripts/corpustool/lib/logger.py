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

"""Logger module of corpus tool."""

import os
import sys

def log_stderr(str):
    """Log the message on console. These messages should be always user-visible. If running in GUI Application, these
    messages should be prompted to user explicitly."""

    # Currently, the AIR application monitor the stderr stream, and display the message in the status bar or pop up the
    # model dialog.
    sys.stderr.write(str + os.linesep)

def log_start(str):
    log_stderr("")
    log_stderr("[START ] " + str)

def log_done(str):
    log_stderr("[DONE  ] " + str)

def log_fail(str):
    log_stderr("[FAILED] " + str)

def log_error(str):
    """The program should be terminated intermediately when error happened."""
    log_stderr("[ERROR] " + str)

def log_warning(str):
    """The program should go ahead, since the it's warning or just one step/process failed."""
    log_stderr("[WARNING] " + str)

class Logger:
    """The logger for process tool in corpus tool. Logger objects should be created for statistic and general
    information respectively."""

    def __init__(self):
        """init logger object with setting fp as None."""
        self._fp = None

    def setLogFile(self, fp):
        """Only opened file descriptor stored in logger object. The conversion will open the logger files for filter
        tools, and close them in the end. Set fp as None will disable the logger."""
        self._fp = fp

    def log(self, msg):
        """Write the msg into log."""
        if self._fp != None :
            self._fp.write( msg + os.linesep )

if __name__ == "__main__":
    pass
