#!/bin/bash -f
# Simple wrapper around parser.pl for exim, configured like:
# etoa: |/path/to/email2aprs/wrapper.sh
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

# approx "dirname" - to find ./parser.pl ./AUTH ./TOKENs/etoa-BLAH etc:
cd "${0%/*}" || exit 45 # EX_TEMPFAIL - exim will retry

# make sure ALL stdout/stderr goes to log not to exim
exec ./parser.pl >> log 2>&1

# Still here? failed to exec?
exit 45 # EX_TEMPFAIL - exim will retry
