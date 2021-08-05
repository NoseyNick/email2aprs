#!/usr/bin/perl -w
# gentoken.pl - generate nice random 10-digit tokens for email2aprs
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
use strict;

my ($entropy, $denom, $bits, $TOK) = (0, 1, 0, '');
open(IN, "/dev/urandom") or die "No /dev/urandom? $!\n";
while (length $TOK < 10) {
    while ($denom < 250) {
	my $buf = '';
	sysread(IN, $buf, 1) or die "Failed to read a random byte: $!\n";
	$entropy += $denom * ord($buf);
	$denom *= 256;
	$bits += 8;
    }
    $TOK    .= chr(($entropy % 26) + ord('a'));
    $entropy = int ($entropy / 26);
    $denom   = int ($denom   / 26);
}
close IN;
print "etoa-$TOK\n";
print "# Used $bits bits of entropy, leftover $entropy / $denom\n" if $ENV{DEBUG};
