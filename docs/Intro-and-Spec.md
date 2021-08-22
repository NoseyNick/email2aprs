# Intro

We wish to create a gateway between inreach :tm: and other GPS device emails,
and the APRS network (specifically APRS-IS). The intention is that affordable
consumer iridium/GPS devices can (indirectly) beacon to
[aprs.fi](https://aprs.fi/),
[APRSDirect](https://aprsdirect.com/),
and other APRS maps / apps.

# Spec

Licensed hams go through some sort of pre-verification to prove they ARE
a ham **(TBD)**, and are then given the ability to generate as many **TOKEN**s as they
wish (within reason, mechanism **TBD** but probably a web page). Each **TOKEN** implies:

* (pre-verified) CALL with (optional) -SSID suffix
* (optional) Object to update (otherwise will update location of CALL-SSID itself)
* [type A] an optional fixed APRS "comment" **OR**
* [type B] a flag asserting that FREEFORM APRS "comment" is allowed+legal
* Perhaps a hint as to what type of device is being used / what parsers to use
* Perhaps a rate limit, to ensure **TOKEN** isn't abused to spam APRS(-IS)
* Perhaps requested position ambiguity
* Perhaps an APRS symbol to use
* Perhaps some other options / presets

**TOKEN**s later revocable at short notice by that ham (EG if abused / obsolete)

Spec could later be extended so **TOKEN**s can be used for other gates / non-APRS purposes?

Email to etoa-**CALL**@**domain.fict** (TBD) is expected to have a **TOKEN** in the
body, probably useful for the 3 "preset messages" provided by inreach devices.
Might be triggered by a non-ham, might have been gone via mailing-lists and/or
been forwarded through various other 3rd parties but will still be sent "from" the
licensed ham's call, and the licensed ham is still the "responsible
party" for any legal/licensing purposes (particularly responsible for making
sure any use by non-hams is legal in their jurisdiction).

Email to etoa-**TOKEN**@**domain.fict** obviously doesn't need a **TOKEN**
in the body, might be useful for **LICENSED HAMS ONLY** for the "type B"
where freeform "comment" can appear in the body for forwarding in APRS
comment. Could be used in the 3 "preset" messages or could be put in the
address book on the device for use in "freeform" (but
paid/premium/quota'd) messages. If a freeform "comment" is being used,
it should probably be carefully delimited to avoid dangerous/expensive
URLs accidentally leaking onto APRS(-IS) even if the URL syntax has been
changed at zero notice by inreach / other sat providers.

"Object to update" is useful for one ham to update multiple objects like
"first marathon runner", "last marathon runner", "need supplies here"
rather than just "**CALL** is here".

I'm looking at gating to APRS (specifically APRS-IS), so some care has to be taken
to make sure a ham is either directly responsible for the transmissions,
or for understanding all local law / ham regulations for forwarding any
3rd-party traffic.

## TOKENs

**TOKEN** needs to be short enough to not eat TOO many of your 160 char
limit, but long+secure+unique enough to avoid spoofing /
dictionary-attack possibilities. Realistically they're not for typing by
hand, but for copying+pasting into "preset messages" or address book, but
in case they are ever typed on the GPS unit itself, users would prefer NOT
to have too much of a mixture of upper/lower/digits/symbols which require
lots of switching between keyboards. First proposal: Something like "etoa-",
followed by 10 lowercase letters, EG "etoa-fwttekjhag"? These may
occasionally randomly contain rude words, however are never gated to APRS so
should not break any rules/regs. They are a secret shared between the gateway,
the licensed amateur, and the GPS owner/user, and can always be discarded and
regenerated if they cause offence.

## Date headers and other timestamps

It is not yet clear whether the email "Date:" field contains the actual time
corresponding to the payload position - if there are delays caused by coverage
issues, network delays, SMS gateway delays, can we expect the time+position to
match, or are we getting the timestamp of some later part of the process, EG
the time the network converts the message to an email?

Can some messages contain multiple conflicting timestamps? Would it be useful
to extract multiple timestamps and pick (say) the earliest one from a message?

## Later considerations:

We will need to think about APRS **symbols** - can presumably also implied by **TOKEN**

Position Ambiguity (EG for privacy reasons?) might be implied by **TOKEN** as well

Garmin URLs within the message can be fetched, and the HTML parsed for a JavaScript/JSON
version of the position, possibly even including a more useful timestamp? Messages sent
over SMS DON'T even contain a LatLon, but do contain a shorter URL that redirects to one
of the pages as above. If a future version of the gateway can spot and fetch those URLs,
and (at least partially) parse the HTML/JS, more useful info might be available than in
the email (or especially SMS) itself. Other manufacturers of similar GPS/sat devices may
also be assumed to have different URLs with different formats on the resultant web pages?