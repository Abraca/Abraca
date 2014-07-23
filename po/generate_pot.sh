#!/usr/bin/sh

VERSION=$(git describe)


touch tmp.pot

git ls-tree -r --full-tree --name-only HEAD:data/ui \
| sed -nr "/\\.xml$/ s|^|../data/ui/| p" \
| xgettext -f - -L glade --from-code=UTF-8 -j -o tmp.pot


git ls-tree -r --full-tree --name-only HEAD:src \
| sed -nr "/\\.vala$/ s|^|../src/| p" \
| xgettext -f - -L vala --from-code=UTF-8 -j -o tmp.pot

sed -r "s/VERSION/$VERSION/" << HERE \
| msgmerge - tmp.pot -q > messages.pot
#
# Abraca, an XMMS2 client.
# Copyright (C) 2007-2014 Abraca Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
msgid ""
msgstr ""
"Project-Id-Version: Abraca VERSION\n"
"Report-Msgid-Bugs-To: \n"
"POT-Creation-Date: 2013-07-16 22:15+0200\n"
"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\n"
"Language-Team: LANGUAGE <LL@li.org>\n"
"Language: \n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"
HERE

rm -f tmp.pot
