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
# Minimal fake APRS-IS listener for testing
# Configure AUTH or individual TOKENs/etoa-SOMETHING with:
# APRSIS: 127.0.0.1:14580

while true; do
  # See http://www.aprs-is.net/ServerDesign.aspx
  # should theoretically wait for valid login but...
  {
    echo "# FakeAPRS 1.0"
    echo "# logresp YOU verified FakeAPRS honest"
  } | nc -vlq0 0.0.0.0 14580
done
