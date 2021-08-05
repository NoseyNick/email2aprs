# Useful links:

[APRS101](https://tapr.org/pdf/APRS101.pdf) describes all the relevant packet formats.
* Probably safest to ignore compressed / MIC-E and pay more attention to standard Position / Object / Item formats
* APRSTime = DDHHMMz or HHMMSSh? (both Zulu, both 7 chars) (p22)
* APRSPos = LatLons converted to Degrees and Decimal minutes ddmm.mm[NS]/dddmm.mm[EW]s (/s = symbol, total 8+1+9+1 chars) (p24)
* Consider position ambiguity? (make this a per-**TOKEN** param too?)
* ... and symbols (ditto) (p104)
* Comment = 0-43 chars (ditto)
* Don't think we care about altitude (at least not from this set of GPS/iridium devices)
* Nor Course and Speed, Power/Height/Gain, or any of the other "APRS Data Extensions"
* "!" + APRSPos + Comment (without timestamp) (p23 + p32)
* "/" + APRSTime + APRSPos + Comment (p23 + p32)
* Or "=" without / "@" with timestamp if we ever support APRS messaging (p32)
* ObjName = 9-char, space-padded, case-sensitive object name.
* ";" + ObjName + "*" + APRSTime + APRSPos + Comment = Objects (p58)
* ";" + ObjName + "_" + APRSTime + APRSPos + Comment = Killed Objects (p58)
* ")" + 3..9-char ItemName + "!" + APRSPos + Comment = Items (p59)
* ")" + 3..9-char ItemName + "_" + APRSPos + Comment = Killed Items (p59)
* Consider Messages (p71) later?
* Do we need to answer IGATE queries with "<IGATE,MSG_CNT=n,LOC_CNT=n" (p77)?

[APRS1.1 addendum](http://www.aprs.org/aprs11.html) gives some short notes on APRS-IS

All relevant: [Connecting](http://aprs-is.net/Connecting.aspx) to APRS-IS, 
[q Construct](http://www.aprs-is.net/q.aspx) and [q Algorithm](http://www.aprs-is.net/qalgorithm.aspx) are to be used to describe how our packets got onto APRS-IS, but are we to use `qAR,IGATECALL` "gating from RF" or `qAO` (RX-only) or something else considering this isn't direct from RF as such?

[APRS-IS.net](http://www.aprs-is.net/) makes it clear we should "**NOT** inject non-amateur radio content falsely identifying it as amateur radio stations. Use APRS Objects instead. APRS Objects are specifically apropos for non-amateur radio information" as we had planned (EG a licensed ham responsible for reporting the position of a non-ham supply vehicle). It also suggests 1/min as an appropriate rate-limiting "Beacon rate [...] for mobile [...] 20 minutes for fixed stations"

[APRS Messaging](http://www.aprs.org/aprs-messaging.html) describes a number of $X-to-APRS and APRS-to-$X gateways including email-to-APRS but says "[...] SMTP Email to the end APRS User in the field via his radio is the one remaining un-fulfilled link in the Universal Ham Radio Text Messaging System". Apparently "The fundamental obstruction to this simple yet powerful capability is simply the need for security and filters to protect the RF links from overload, possible abuse, and inappropriate material and spam". Our system of "pre-verified ham responsible for generation / maintenance of **TOKEN**s" would appear to solve almost all of the above, or combined with rate-limits probably all of the above?

We're not quite an igate as such, but some of [Hessu's IGATE-HINTS](https://github.com/hessu/aprsc/blob/master/doc/IGATE-HINTS.md) might be relevant?

## Some possible symbol sets:

We're not trying to be an APRS Map, however assuming we want users to be able to pick a symbol for their Location/Objects, we may wish to use:

* [Arguably the official symbol set](http://wa8lmf.net/aprs/APRS_symbols.htm) in a few different formats (APRSplus/UIpoint/UIview=BMP/GIF, FINDU=PNG/GIF, tiled)
* [Hessu's APRS.fi](https://github.com/hessu/aprs-symbols) symbols - Public Domain / CC / "please provide a pointer to the source" (PNG, various sizes, tiled) - see also the corresponding machine-readable [symbol index](https://github.com/hessu/aprs-symbol-index)
* [APRS Direct FAQ](https://www.aprsdirect.com/faq/list) has a symbol set free to use "mention on your website that the symbols are provided by APRS Direct". Seems to be individual PNGs or SVGs

## inReach device notes

With an inReach device there are 3 ways to set a message:
* On the account web page linked to the device.  This is for pre-set messages to pre-set recipients.  These messages are unlimited and "free" to use.
* On the Earthmate app on a smartphone paired to the device.  This is for free-form messages.  If the number of free-form messages goes over an allotted number there is a per-message fee.
* On the device itself.  This is for free-form messages.  The device has ~4 virtual keyboards, the keys operated by using the rocker button to navigate and the check button to select.  Keyboard switching is by means of 2 keys next to the delete key.  The @ and . are extra available, but ignore that.

The device 4 virtual keyboards (all keyboards have a space key):
* a through z
* A through Z
* 0 through 9 plus ()+-=#$/&@'"!,?.
* 0 through 9 plus {}<>{}|\~_^`*%:;

![inReach keyboard](https://raw.githubusercontent.com/NoseyNick/email2aprs/master/docs/keyboard-sm.jpg)