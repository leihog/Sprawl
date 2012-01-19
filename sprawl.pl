#
# Adds some stuff that makes me fuzzy inside.
#
# Installation:
# 1) place in ~/.irssi/scripts/
# 2) From within irssi type /run sprawl/sprawl.pl (If run doesn't exist type: /script load sprawl/sprawl.pl)
#
# For autoloading type mkdir ~/.irssi/scripts/autorun; cd ~/.irssi/scripts/autorun; ln -s ../sprawl/sprawl.pl

use strict;
use Irssi;
use vars qw($VERSION %IRSSI);

$VERSION = "0.4";

%IRSSI = (
    authors     => 'Leif Högberg',
    contact     => 'leihog@gomitech.com',
    name        => 'sprawl',
    description => 'Adds some stuff that makes me fuzzy inside.',
    license     => 'GNU General Public License',
    url         => 'http://www.gomitech.com/sprawl',
    changed     => 'Mon Jan 17 13:37:00 CET 2011',
);

Irssi::theme_register([
  'sprawl_loaded', '%R>>%n Loading %_$0%_ v$1 by $2.',
  'sprawl_unload', '%R>>%n %_$0%_ unloaded. Got feedback? Contact me @ %w $1 %n',
#  'whois_begin', '/whois for $0:',
]);

my $sb_pos = 0;
my $sprawl_sb_timeout;
my $sprawl_sb_dbl=0;

my $karmabomb_server;
my $karmabomb_count;
my $karmabomb_target;
my $karmabomb_payload;
my $karmabomb_timer;

sub add_window_level {
  my($window_name, $level) = @_;

  Irssi::window_find_name("($window_name)")->command("^window level +$level");
}

sub remove_window_level {
  my($window_name, $level) = @_;

  Irssi::window_find_name("($window_name)")->command("^window level -$level");
}

# tab completion for /g <winname>
sub sig_complete_go {
  my ($complist, $window, $word, $linestart, $want_space) = @_;
  my $channel = $window->get_active_name();
  my $k = Irssi::parse_special('$k');
  return unless ($linestart =~ /^\Q${k}\Eg/i);

  @$complist = ();
  foreach my $w (Irssi::windows) {
    my $name = $w->get_active_name();
    if ($word != "" && $name =~ /\Q${word}\E/i) {
      push(@$complist, $name);
    } else {
      push(@$complist, $name);
    }
  }
  Irssi::signal_stop();
}

sub sig_whois {

  my ($server, $data, $nick, $host) = @_;
  my ($me, $nick, $user, $host) = split(" ", $data);

  remove_window_level( 'status', 'crap' );
  $server->redirect_event("whois", 1, "$nick", 0, undef, {
	"event 318" => "redir_whois_end",
	"event 369" => "redir_whois_end"
  });

#  my $awin = Irssi::active_win();
#  $awin->printformat(MSGLEVEL_CRAP, "whois_begin", $nick);
}

# Will highlight the window in the statusbar 
# if your chanop status changes.
sub sig_mode {
  my ($server, $data, $nick) = @_;
  my ($channel, $mode, $rest) = split(/ /, $data, 3);
  my $win = Irssi::active_win();
  my $winchan = $server->window_find_item($channel);

  return if $win->{refnum} == $winchan->{refnum};

  my @rest = split(/ +/, $rest);
  return unless grep {/^$server->{nick}$/} @rest;

  my $par = undef;
  my $i = 0;
  my $isop = $winchan->{active}->{chanop};
  my $change = $isop;

  for my $c (split(//, $mode)) {
    if ($c =~ /[+-]/) {
      $par = $c;
    } elsif ($c == "o") {
      $change = ($par == "+" ? 1 : 0) if $rest[$i] == $server->{nick};
    } elsif ( $c =~ /[vbkeIqhdO]/ || ($c == "1" && $par == "+") ) {
      $i++;
    }
  }

  $winchan->activity(4) unless $change == $isop;
}

####
# Commands

# @todo will stop at the first matching window name. 
# If #cookie comes before #cook in the window list
# #cookie will be shown even tho the user types #cook.
sub cmd_go {
  my ($chan, $server, $witem) = @_;

  $chan =~ s/ *//g;
  foreach my $w (Irssi::windows) {
    my $name = $w->get_active_name();
    if ($name =~ /^[#&+]?\Q${chan}\E/) {
      $w->set_active();
      return;
    }
  }
}

sub do_karmabomb {

  $karmabomb_server->send_message($karmabomb_target, $karmabomb_payload, 1);  

  if (--$karmabomb_count > 0) {
    $karmabomb_timer = Irssi::timeout_add_once(60000, "do_karmabomb", undef);
  } else {
    my $win = Irssi::active_win();
    $win->print("karmabomb against $karmabomb_target ended.");

    undef $karmabomb_server;
    undef $karmabomb_target;
    undef $karmabomb_payload;
  }
}

sub cmd_karmabomb {
  my ($params, $server, $witem) = @_;
  my ($target, $payload, $count) = split(/ /, $params);
  my $win = Irssi::active_win();

  if ( $karmabomb_timer ) {
    $win->print("A karmabomb is already active.");
    return;
  }

  $karmabomb_server = $server;
  $karmabomb_target = $target;
  $karmabomb_count  = $count;
  $karmabomb_payload = $payload;
  
  $win->print("Will karmabomb $target with payload $payload $count times.");
  do_karmabomb();
}

sub sprawl_sb_show {
  my ( $item, $get_size_only ) = @_;
  my $text = sprawl_sb_get();
  $item->default_handler($get_size_only, "{sb %m.:%n[". $text ."]%m:.%n}", undef, 1);
}
sub sprawl_sb_setup {
  my $interval = Irssi::settings_get_int("sprawl_sb_interval");
  if ( !$interval || $interval < 10 ) {
    $interval = 500;
  }

  Irssi::timeout_remove($sprawl_sb_timeout);
  $sprawl_sb_timeout = Irssi::timeout_add($interval, "sprawl_sb_redraw", undef);
}

sub sprawl_sb_redraw { Irssi::statusbar_items_redraw('sprawl_sb'); }

sub sprawl_sb_get {
  my $text = "";
  my @chars  = split //, "sprawl";
  my $total = $#chars;
  
  for my $i (0..$total) {
    if ($i == $sb_pos) {
      $text .= "%m" . $chars[$i] . "%n";
    } else {
      $text .= $chars[$i];
    }
  }

  if ( $sprawl_sb_dbl )
  {
    $sprawl_sb_dbl=0;
    return $text;
  } else {
    $sprawl_sb_dbl=1;
  }

  $sb_pos++;
  if ( $sb_pos > $total ) {
    $sb_pos = 0;
  }

  return $text;
}

sub initialize {

  # config...
  Irssi::statusbar_item_register('sprawl_sb', '$0', 'sprawl_sb_show');
  Irssi::settings_add_int('sprawl', 'sprawl_sb_interval', 500);

  Irssi::command("SET timestamp_format %H:%M:%S");
  Irssi::command("SET theme scripts/sprawl/sprawl.theme");
  Irssi::command("SET window_history on");
  Irssi::command("statusbar window add -after user sprawl_sb");

  # signals
  Irssi::signal_add_first("event 311", \&sig_whois);
  Irssi::signal_add("redir_whois_end", sub { add_window_level( 'status', 'crap' ) } );
  Irssi::signal_add("event mode", "sig_mode");
  Irssi::signal_add_first("complete word", "sig_complete_go");
  Irssi::signal_add("setup changed", "sprawl_sb_setup");

  # commands
  Irssi::command_bind("g", "cmd_go");
  Irssi::command_bind("karmabomb", "cmd_karmabomb");

  # kickstart stuff
  sprawl_sb_setup();

  # script loaded
  Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'sprawl_loaded', $IRSSI{name}, $VERSION, $IRSSI{authors});
}

sub unload {
  Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'sprawl_unload', $IRSSI{name});
  Irssi::command('SET -default theme');
}

initialize();
