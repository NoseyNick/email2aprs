#!/usr/bin/perl -w
# parser.pl - main code of email2aprs to parse emails and make APRS!
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
use strict;            # OR ELSE!
use MIME::Parser;      # for parsing MIME emails of course!
use Encode             qw(decode);
use Date::Parse        qw(str2time);
use POSIX              qw(strftime);
use IO::Socket::INET;  # For APRS upload
our $VERSION =         'email2aprs 0.42';

# defaults for stuff we intend to parse out of AUTH, email, or TOKENs therein:
my %dat = (
    AUTH    => $ENV{AUTH} // 'AUTH',  # to point to different AUTH file
    TOKEN   => $ENV{TOKEN},   # can use env var to "sideload" a default token
    # ... AUTH or TOKENs/etoa-BLAH can contain any of these "key: val":
    APRSIS  => '127.1:14580', # connect to Server:Port
    # USER  => 'VA3NNW-E',    # email2aprs USER for APRS-IS - read from "AUTH"
    # PASS  => -1,            # email2aprs PASS for APRS-IS - read from "AUTH"
    TIMEOUT => 10,            # number of seconds to wait for APRS-IS response
    # CALL  => 'VA3NNW-E',    # MUST get via TOKEN mechanism
    TOCALL  => 'APRS',        # ++++ get ourselves a http://www.aprs.org/aprs11/tocalls.txt ?
    PATH    => 'TCPIP*',      # See http://www.aprs-is.net/Connecting.aspx
    # Lowercase ones can also be overridden in the email. If TOKENs/etoa-BLAH has:
    # def-key: val            # ... then email body can contain:
    # key: val                # ... to override
    msg     => '',            # empty msg if not set elsewhere
    obj     => '',            # 3-9-char object name, space-padded later
    sym     => '',            # See http://wa8lmf.net/aprs/APRS_symbols.htm
);

### Create parser, and set some parsing options:
my $parser = new MIME::Parser;
$parser -> output_to_core(1);
$parser -> tmp_to_core(1);
# $parser -> decode_headers(1); # can result in unparseable headers
$parser -> extract_nested_messages(1);
$parser -> ignore_errors(1);
### Parse input:
my $ent = eval { $parser->parse(\*STDIN) }
  or fatal('parse failed'); # no sense retrying
# or parse_data(\$scalar);

crawl($ent);
sub crawl {
    my ($ent) = @_;
    
    for my $key (qw(From To Date Return-path Envelope-to Subject Message-ID)) {
	my $val = $ent->head->get($key);
	next unless $val;
	$val = decode('MIME-Header', $val);
	chomp $val; # lose LF
	$dat{$key} = $val;
	if      ($key eq 'Date') {
	    my $time = str2time($val) or next;
	    # $dat{ISODate}  = strftime('%Y-%m-%dT%H:%M:%SZ', gmtime($time));
	    # +++ Perhaps TOKKEN-based feature flag to select:
	    $dat{APRSTime}   = strftime('%d%H%Mz',            gmtime($time));
	    # $dat{APRSTime} = strftime('%H%M%Sh',            gmtime($time));
	} elsif ($key eq 'Envelope-to' or $key eq 'Subject') {
	    check_toks($val);
	}
    }
    
    if ($ent->effective_type =~ '^text/') {
	$dat{_bodies}++;
	my $body = $ent->bodyhandle || { as_string => '' };
	$body = $body->as_string || '';
	$body =~ s/<.*?>/\n/g;
	# Garmin / inReach / others:
	# A bunch of URLs with lat=YYY@lon=XXX:
	$dat{Lat} = $1               if $body =~ /\bLat[= ]([-+]?\d+\.\d+)/i;
	$dat{Lon} = $1               if $body =~ /\bLon[= ]([-+]?\d+\.\d+)/i;
	# anything capable of sharing a geo: url:
	@dat{'Lat','Lon'} = ($1, $2) if $body =~ /\bgeo:([-+]?\d+\.\d+),([-+]?\d+\.\d+)/;
	
	for (grep {/^[a-z]*$/} keys %dat) {
	    # the lower-case keys can be overridden in the body:
	    # probably just msg, obj, sym:
	    $dat{$_} = $1    if $body =~ /\b$_: *(.*)/i;
	}
	check_toks($body);
    }
    
    for my $part ($ent->parts) {
	# To define recursion, we must first define recursion:
	crawl($part);
	# ... to parse sub-parts, and sub-sub parts
    }
}

sub check_toks {
    return unless $_[0] =~ s/(etoa-[a-z]+)//i;  # MODIFY first arg
    $dat{TOKEN} = lc $1;
}

# read an AUTH file or TOKENs/etoa-blah, set all the vars/defaults:
sub readconf {
    my ($fi) = @_;
    open(IN, $fi) or return;
    while (<IN>) {
	s/\s*#.*//; # strip trailing comments
	if (/^def-(\w+): *(.*)/) { $dat{$1} ||= $2; }
	elsif  (/^(\w+): *(.*)/) { $dat{$1}   = $2; }
    }
    return close IN;
}

# contains global settings, USER:, PASS:, probably APRSIS:, maybe TIMEOUT:
my $AUTH = delete $dat{AUTH} // 'AUTH';
readconf($AUTH) or err("Unable to read $AUTH: $!");
# contains CALL and any other per-TOKEN options:
readconf("TOKENs/$dat{TOKEN}")  if $dat{TOKEN};
# ... don't worry about TOKEN errors though - stale TOKENs handled by:
fatal('No CALL/TOKEN') unless $dat{CALL}; # no sense retrying

# See if we have Lat/Lon/sym to create a valid APRS position
sub { # anonymous sub just so we can "return" to bail early
    my $lat = delete $dat{Lat};
    my $lon = delete $dat{Lon};
    (delete $dat{sym} // '') =~ /^(.)(.)/; # boobies!
    my ($symtab, $sym) = ($1 // '/', $2 // '/'); # Red dot - sym of last resort
    
    return unless defined($lat) && $lat =~ /^[-+]?\d+\.\d+$/;
    return unless $lat >=  -90 && $lat <=  90;
    return unless defined($lon) && $lon =~ /^[-+]?\d+\.\d+$/;
    return unless $lon >= -180 && $lon <= 180;
    
    my ($ns, $ew) = ('N', 'E');
    if ($lat < 0) { $lat = -$lat; $ns = 'S'; }
    if ($lon < 0) { $lon = -$lon; $ew = 'W'; }
    
    # +++ Perhaps TOKEN-based position ambiguity setting?
    $dat{APRSPos} = sprintf
      '%02d' . '%05.2f'              . '%1.1s' . '%1.1s' .
      '%03d' . '%05.2f'              . '%1.1s' . '%1.1s',
      $lat,    ($lat - int $lat) * 60,  $ns,      $symtab,
      $lon,    ($lon - int $lon) * 60,  $ew,      $sym;
} -> ();

# Try to assemble an APRS packet from various fragments:
sub APRS {
    my $type = shift;
    my $packet  = '';
    for ('CALL', '>', 'TOCALL', ',', 'PATH', ':', @_) {
	# try to insert various packet fragments, return if we can't:
	if (/^[A-Za-z]/) { $packet .= $dat{$_} // return; }
	else             { $packet .= $_; } # insert symbols and stuff
    }
    # If we got here, we have sucessfully assembled a whole packet:
    $dat{-APRS} = $packet;
    delete @dat{qw(CALL TOCALL PATH), @_}; # "consumed" them - shorter logs.
    return $dat{APRSType} = $type;
}

# Could check for presence of each of these fields but honestly
# easier to just attempt to build packet and fail a few times:

if ($dat{obj}) {
    $dat{obj} = sprintf('%-9.9s', $dat{obj}); # min9 max9 ch, space-pad
    # note ITEMS are    '%-3.9s' (see below)  # min3 max9 ch not padded
} else {
    delete $dat{obj};
}

APRS qw(Object ; obj  * APRSTime APRSPos msg)
# +++ or                     _ ... to kill?
# +++ or       Item  \) item ! with no APRSTime?
# +++ or       Item  \) item _ to kill?
  or APRS qw(TimePos / APRSTime APRSPos msg)
  or APRS qw(Pos     ! APRSPos msg)
  or ($dat{msg} && APRS qw(Status  > msg))
# ++++ TOKEN-based flag to say we DO want positionless Status msg?:
# COULD send  APRS(qw(Status  > APRSTime)) - pointless w/o Pos or msg?
  or fatal('No packet to send'); # no sense retrying

# Now see if we can send it:
$SIG{ALRM} = sub { err('Timeout'); };
alarm $dat{TIMEOUT}; # ... if no response

my $peer = delete $dat{APRSIS} or return err('No APRSIS server:port');
my $USER = delete $dat{USER}   or return err('No USER');
my $PASS = delete $dat{PASS}   or return err('No PASS');

my $aprsis = new IO::Socket::INET ( PeerAddr => $peer )
  or err("Connect $peer - $!");

print $aprsis "user $USER pass $PASS vers $VERSION\n$dat{-APRS}\n";

my $n  = 0;
while (<$aprsis>) {
    chomp;
    $dat{sprintf('-RESP%02d',$n)} = $_;
    last if /logresp/;
    err('Too much response') if ++$n > 50;
}

alarm 0;
# sleep 1; # allow 1sec extra for packet to flush?
close $aprsis;
done(OK => 'SENT');

# As per https://www.exim.org/exim-html-3.20/doc/html/spec_18.html#SEC534 ...
sub err   { done(ERR   => @_, 45); } # EX_TEMPFAIL so exim will retry later
sub fatal { done(FATAL => @_); }     # exit 0 misleading but exim WON'T try again
sub done  {
    my ($status, $msg, $exit) = @_;
    $dat{"-$status"} = $msg;
    my $LOG = strftime('%Y-%m-%dT%H:%M:%SZ ', gmtime( $^T )) # program start time
      . '#'x60 . "\n";
    for (sort keys %dat) {
	next unless $dat{$_};
	$LOG .= "$_: $dat{$_}\n";
    }
    print $LOG;
    exit ($exit // 0);
}

######################################################################
# For posterity, the first ever email2aprs packets gated to APRS-IS:

# 2020-04-23 04:05Z First packet ever sent from email2aprs to APRS-IS, v.manual, TOKEN edited in etc:
# KE5CEP-E>APRS,TCPIP*,qAS,VA3NNW:/231405z3552.96N/10617.29W/Testing email2aprs (simulated position)

# 2020-04-24 03:54Z First packet with real TOKEN ever gated UNEDITED, though still semi-manual:
# KE5CEP-E>APRS,TCPIP*:/240250z3553.01N/10618.53W/Testing email2aprs (simulated position)
# KE5CEP-E>APRS,TCPIP*,qAS,VA3NNW:/240250z3553.01N/10618.53W/Testing email2aprs (simulated position)

# 2020-04-27 03:29Z First packet that really did go email to APRS-IS, no human MitM:
# VA3NNW-4>APRS,TCPIP*,qAS,VA3NNW-E:>NoseyNick testing, please ignore

# 2020-04-27 03:31Z ... followed by a buggy object with 0-length name:
# VA3NNW-4>APRS,TCPIP*,qAS,VA3NNW-E:;*270331z4327.61NN08034.79WnNoseyNick testing, please ignore [Invalid object]

# 2020-04-27 03:39Z ... followed by a "real" (simulated) position:
# VA3NNW-4>APRS,TCPIP*,qAS,VA3NNW-E:/270339z4327.61NN08034.79WnNoseyNick testing, please ignore
