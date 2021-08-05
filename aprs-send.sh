#!/bin/bash -f
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
# Little wrapper to send packets manually

# Get config from AUTH file:
conf () {
  sed -Ei "/^$1:/ !d;  s/^[a-z]*: *//" < AUTH | grep .
}
APRSIS=$(conf APRSIS) || { echo no APRSIS; exit 9; }
USER=$(conf USER)     || { echo no USER;   exit 9; }
PASS=$(conf PASS)     || { echo no PASS;   exit 9; }

{
  sleep 1
  echo "user $USER pass $PASS"
  cat
} | nc -q1 "${APRSIS/:/ }" # replace : with space
