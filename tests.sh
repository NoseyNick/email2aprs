#!/bin/bash
# tests.sh for testing email2aprs parser.pl, parsing tests/*.eml,
# sending to aprs-listener.sh
######################################################################
# (C) Copyright 2020-2021 "Nosey" Nick Waterman VA3NNW
# <e2a-copyright@noseynick.com> https://github.com/NoseyNick/email2aprs
######################################################################
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
######################################################################
# tests/*.eml are complete RFC-format text / MIME emails, one per
# file, including headers. They are NOT provided with email2aprs, for
# privacy reasons, but you are welcome to provide a directory of files
# and use this script for your own tests.

for X in tests/*.eml; do
  echo "#### $X"
  AUTH=AUTH-test  ./parser.pl < "$X"
  echo _RET: $?
done
