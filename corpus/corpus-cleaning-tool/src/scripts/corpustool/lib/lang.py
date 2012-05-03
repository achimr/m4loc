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

"""Lib module for handling language."""

import os

_set_support_langs = set([ # udpated in 2010-09-08
    'ar-AE',
    'bg-BG',
    'cs-CZ',
    'da-DK',
    'de-DE',
    'el-GR',
    'en-GB',
    'en-US',
    'es-ES',
    'fi-FI',
    'fr-FR',
    'he-IL',
    'hr-HR',
    'hu-HU',
    'it-IT',
    'ja-JP',
    'ko-KR',
    'lt-LT',
    'lv-LV',
    'nb-NO',
    'nl-NL',
    'no-NO',
    'pl-PL',
    'pt-BR',
    'ro-RO',
    'ru-RU',
    'sk-SK',
    'sl-SI',
    'sv-SE',
    'tr-TR',
    'uk-UA',
    'zh-CN',
    'zh-TW',
    ])

# def isSupportLang(lang):
#     return True if localeISOName(lang) in _set_support_langs else False

def localeISOName(lang):
    return lang.replace('-', '_')

def localeTMXName(lang):
    return lang.replace('_', '-')

def langName(lang):
    return localeISOName(lang).partition('_')[0]

def localePairForm(src, target):
    return localeISOName(src) + '-' + localeISOName(target)

def createDir():
    """ when you update the _set_support_langs, please run lang.py to update the engine directory hierarchy."""
    print list(_set_support_langs)
    for lang in list(_set_support_langs):
        lang = localeTMXName(lang)
        if ( not os.path.exists(lang) ):
            os.mkdir(lang)
        f = open(lang + "/__init__.py", "w")
        f.close()

if __name__ == "__main__":
    createDir()
    pass
