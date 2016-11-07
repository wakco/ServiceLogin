# ServiceLogin
znc network perl module for logging into Gnuworld irc channel services such as X on Undernet.

This module includes support for Trivial One Time Passwords (TOTP), hidden host (usermode +x and randomised nickname while connecting), and for the coming (and planned) Login on Connect.

Perl will need Authen::OATH for TOTP support, and Convert::Base32 for converting base 32 TOTP secrets.

Install the following into .znc/modules
ServiceLogin.pm
ServiceLogin/tmpl/index.tmpl

Configuration is currently only available via the znc web interface, as these are set-and-forget type settings. 
