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

sub initialize {

  # config...
  Irssi::command("SET timestamp_format %H:%M:%S");
  Irssi::command("SET theme scripts/sprawl/sprawl.theme");
  Irssi::command("SET window_history on");

  # signals
  Irssi::signal_add_first('event 311', \&sig_whois);
  Irssi::signal_add('redir_whois_end', sub { add_window_level( 'status', 'crap' ) } );
  Irssi::signal_add("event mode", "sig_mode");
  Irssi::signal_add_first("complete word", "sig_complete_go");

  # commands
  Irssi::command_bind("g", "cmd_go");

  # script load
  Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'sprawl_loaded', $IRSSI{name}, $VERSION, $IRSSI{authors});
}

sub unload {
  Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'sprawl_unload', $IRSSI{name});
  Irssi::command('SET -default theme');
}

initialize();
