# ServiceLogin.pm

package ServiceLogin;

use base 'ZNC::Module';
use Authen::OATH; # required for Time-based One Time Passwords management
use Convert::Base32; # Authen::OATH requires hex secrets, Gnuworld services may supply the secret in base32

sub description {
 "This Perl Module is designed to help login to Gnuworld services such as X on Undernet supporting Time-based One Time Passwords, the +x hidden host feature (including random nick on connect), and login on connect."
}

sub GetWebMenuTitle {
 "Login Services"
}

# Module defaults for script only variables
my $hostHidden = 0;
my $randomNick = "";
my $preferredNick = "";
my $totp = "";
my $loginDetails = "";
my $reportBack = "";

# Defaults for web/stored settings
my $loginOnConnect = 0;
my $serviceName = "X";
my $serviceHost = "channels.undernet.org";
my $serviceService = $serviceName."\@".$serviceHost;
my $serviceLogin = "login";
my $serviceUsername = "";
my $servicePassword = "";
my $serviceSecret = "";
my $service32Secret = 0; # Secret is assumed HEX, with this enabled the secret is converted from a base32 secret
my $preferredModes = 1; # required for hidden host

sub serviceGetTOTP {
 my $self = shift;
 my $oath = Authen::OATH->new();
 if ( $service32Secret ) {
  $totp = $oath->totp( decode_base32 ( $serviceSecret ) );
 } else {
  $totp = $oath->totp( $serviceSecret );
 }
}

sub loginString {
 my $self = shift;
 if ( $serviceSecret ) {
  $self->serviceGetTOTP();
  $loginDetails = $serviceUsername." ".$servicePassword." ".$totp;
  $reportBack = "Logging into username: ".$serviceUsername." with One Time Password [ ".$totp." ]";
 } else {
  $loginDetails = $serviceUsername." ".$servicePassword;
  $reportBack = "Logging into username: ".$serviceUsername; 
 }
}

sub OnWebRequest {
 my $self = shift;
 my ( $webSock, $pageName, $tmpl ) = @_;
 if ( $webSock->GetParam("submitted") ) {
  my @nvkeys = $self->GetNVKeys;
  $serviceUsername = $webSock->GetParam("myuser");
  $self->SetNV("uName", $serviceUsername);
  $servicePassword = $webSock->GetParam("mypass");
  $self->SetNV("uPass", $servicePassword);
  $service32Secret = $webSock->GetParam("myb32");
  $self->SetNV("b32s", $service32Secret);
  $serviceSecret = $webSock->GetParam("myhex");
  $self->SetNV("HEXs", $serviceSecret);
  $preferredModes = $webSock->GetParam("hiddenhost");
  $self->SetNV("Modes", $preferredModes);
  $loginOnConnect = $webSock->GetParam("loginonconnect");
  $self->SetNV("loc", $loginOnConnect);
  $serviceName = $webSock->GetParam("myname");
  $self->SetNV("sName", $serviceName);
  $serviceHost = $webSock->GetParam("myhost");
  $self->SetNV("sHost", $serviceHost);
  $serviceLogin = $webSock->GetParam("mylogin");
  $self->SetNV("sLogin", $serviceLogin);
  $serviceService = $serviceName."\@".$serviceHost;
 }
 $tmpl->set("Username", $serviceUsername); 
 $tmpl->set("Password", $servicePassword); 
 $tmpl->set("HEXSecret", $serviceSecret); 
 my $row1 = $tmpl->AddRow("Options");
 $row1->set("OptionName", "hiddenhost");
 $row1->set("DisplayName", "Hidden Host");
 $row1->set("Tooltip", "Sets +ix and randomises your nickname on connect.");
 $row1->set("Checked", $preferredModes);
 $row1->set("Disabled", 0);
 my $row2 = $tmpl->AddRow("Options");
 $row2->set("OptionName", "myb32");
 $row2->set("DisplayName", "TOTP Secret is base32");
 $row2->set("Tooltip", "This module works best with HEX secrets, but if you have trouble, enable this.");
 $row2->set("Checked", $service32Secret);
 $row2->set("Disabled", 0);
 my $row3 = $tmpl->AddRow("Options");
 $row3->set("OptionName", "loginonconnect");
 $row3->set("DisplayName", "Login on Connect");
 $row3->set("Tooltip", "Login on Connect (coming to Undernet).");
 $row3->set("Checked", $loginOnConnect);
 $tmpl->set("ServiceName", $serviceName);
 $tmpl->set("ServiceHost", $serviceHost);
 $tmpl->set("ServiceCommand", $serviceLogin);
 return 1;
}

sub OnLoad {
 my $self = shift;
 my @nvkeys = $self->GetNVKeys;
 $hostHidden = 0;
 $loginOnConnect = $self->GetNV("loc") if ($self->ExistsNV("loc"));
 $serviceName = $self->GetNV("sName") if ($self->ExistsNV("sName"));
 $serviceHost = $self->GetNV("sHost") if ($self->ExistsNV("sHost"));
 $serviceService = $serviceName."\@".$serviceHost;
 $serviceLogin = $self->GetNV("sLogin") if ($self->ExistsNV("sLogin"));
 $serviceUsername = $self->GetNV("uName") if ($self->ExistsNV("uName"));
 $servicePassword = $self->GetNV("uPass") if ($self->ExistsNV("uPass"));
 $serviceSecret = $self->GetNV("HEXs") if ($self->ExistsNV("HEXs"));
 $service32Secret = $self->GetNV("b32s") if ($self->ExistsNV("b32s"));
 $preferredModes = $self->GetNV("Modes") if ($self->ExistsNV("Modes"));
 return $ZNC::CONTINUE;
}

sub OnJoining {
 my $self = shift;
 if ( !$hostHidden && $preferredModes ) {
  return $ZNC::HALT;
 }
 return $ZNC::CONTINUE;
}

sub OnRaw {
 my $self = shift;
 my ($sLine) = @_;
 my ($myhost, $code, $me, $nick, $user, $host, $end) = split(" ", $sLine);
 if ($code == '396') {
  $hostHidden = 1;
  $self->PutIRC("NICK ".$preferredNick);
  $self->PutStatus("Login successful, host hidden, trying to get nickname: ".$preferredNick);
 }
 return $ZNC::CONTINUE;
}

sub OnIRCDisconnected {
 my $self = shift;
 $hostHidden = 0;
 $preferredNick = "";
 return $ZNC::CONTINUE;
}

sub OnIRCConnected {
 my $self = shift;
 $hostHidden = 0;
 if ( !$loginOnConnect ) {
  if ( $preferredModes ) {
   $self->PutIRC("MODE ".$self->GetNetwork->GetCurNick." +ix");
  }
  $self->loginString();
  $self->PutIRC("PRIVMSG ".$serviceService." :".$serviceLogin." ".$loginDetails);
  $self->PutStatus($reportBack);
 }
 return $ZNC::CONTINUE;
}

sub OnIRCRegistration {
 my $self = shift;
 my ($pass, $nick, $ident, $realname) = @_;
 $preferredNick = $nick;
 if ( $preferredModes && !$loginOnConnect ) {
  my @set = ('0' ..'9', 'A' .. 'Z', 'a' .. 'z');
  my $str = join '' => map $set[rand @set], 1 .. 3;
  $randomNick = $nick."-".$str;
  $_[1] = $randomNick;
 } elsif ( $loginOnConnect ) {
  $self->loginString();
  $self->PutStatus( $reportBack );
  if ( $preferredModes ) {
   $_[0] = "+x".$loginDetails;
  } else {
   $_[0] = $loginDetails;
  }
 }
 return $ZNC::CONTINUE;
}

1;
