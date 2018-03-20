# ServiceLogin
ServiceLogin is a ZNC network perl module for logging into Gnuworld irc channel services such as X on Undernet.

This module includes support for Time-based One Time Passwords (TOTP), hidden host (usermode +x and randomised nickname while connecting), and for Login on Connect.

#### Perl will need the following perl modules installed:
- Authen::OATH for TOTP support
- Convert::Base32 for converting base 32 TOTP secrets.

Unless you have a preferred method for installing perl modules, I recommend using `sudo cpan module::name`.

#### Install the following into .znc/modules
- ServiceLogin.pm
- ServiceLogin/tmpl/index.tmpl

Configuration is currently only available via the znc web interface, as these are set-and-forget type settings. 


ServiceLogin is based on ZNC's q module, using ideas from the q module, and combining them with ideas from TOTP login, and Login on Connect ZNC Perl modules I wrote: https://halo.wak.co.nz/ZNC-ULoCTOTP


#### To come:
- [ ] Option for +x! (connect with hidden host only if login valid, i.e. no service to login to, or invalid login, disconnect)
- [ ] Attempt to recover nickname
- [ ] Commands to edit settings to replace the web page with since the web page doesn't work in ZNC 1.6.5+ (appears to be a bug in ZNC people are having trouble isolating).
