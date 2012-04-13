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

"""The entrance module for corpus tool. Calling this module with configuration file specified in command line, will
execute the python scripts to complete the tasks specified by configuration file.

--hlep to get more usage information."""

import errno
import os
import shutil
import sys

from optparse import OptionParser

from corpustool.common.conversion import Conversion

from corpustool.lib.config import ConversionConfig
from corpustool.lib.config import ConfigException

from corpustool.lib.logger import log_done
from corpustool.lib.logger import log_error
from corpustool.lib.logger import log_fail
from corpustool.lib.logger import log_stderr

def main():
    """The main function of convert module. Parse the cmdline, and create the config from xml file which describe the
    configuration for conversion. Then run the conversion to create and filter the corpus files according to config."""

    progname = sys.argv[0]
    usage="""%prog -f command.xml"""

    parser = OptionParser(usage, version="%prog v0.1 (c) 2010 by Leo Jiang <ljiang@adobe.com>")
    parser.add_option("-f", "--file", dest="filename", metavar="FILE", type="string",
                      help="read the command from file.")
    (options, args) = parser.parse_args()

    log_stderr("convert.py v0.1 (c) 2010 by Leo Jiang <ljiang@adobe.com>")

    if (options.filename == None):
        log_stderr("Usage: {0} -f command.xml".format(progname))
        log_stderr(os.strerror(errno.EINVAL) + " : config file not specified.")
        sys.exit(errno.EINVAL)

    path = os.path.abspath(options.filename)
    if not os.path.isfile(path):
        log_error(os.strerror(errno.EINVAL) + " : file '{0}' not existed.".format(path))
        log_fail("Convert")
        sys.exit(errno.EINVAL)

    try:
        config = ConversionConfig(path)
        conversion = Conversion(config)
        conversion.run()
    except ConfigException as e:
        log_fail("Convert: ConfigException")
        sys.exit(-1)
    except Exception as e:
        print "failed."
        log_fail(e.message)
        log_fail("Convert: unknown exception.")
        sys.exit(-1)

    log_done("Convert")
    sys.exit(0)

if __name__ == "__main__":
    main()
