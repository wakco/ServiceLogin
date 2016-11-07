# ServiceLogin
ZNC network perl module for logging into Gnuworld irc channel services such as X on Undernet.

This module includes support for Time-based One Time Passwords (TOTP), hidden host (usermode +x and randomised nickname while connecting), and for the coming (and planned) Login on Connect.

Perl will need Authen::OATH for TOTP support, and Convert::Base32 for converting base 32 TOTP secrets.

Install the following into .znc/modules
ServiceLogin.pm
ServiceLogin/tmpl/index.tmpl

Configuration is currently only available via the znc web interface, as these are set-and-forget type settings. 


ServiceLogin is based on ZNC's q module, using ideas from the q module, and combining them with idea from TOTP login, and Login on Connect ZNC Perl modules I wrote: https://halo.wak.co.nz/ZNC-ULoCTOTP (note: private https certificate will require acceptance).
