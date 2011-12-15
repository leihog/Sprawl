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

sub initialize {

  Irssi::command("SET timestamp_format %H:%M:%S");
  Irssi::command("SET theme scripts/sprawl/sprawl.theme");
  Irssi::command("SET window_history on");

  # redir
  Irssi::signal_add_first('event 311', \&sig_whois);
  Irssi::signal_add('redir_whois_end', sub { add_window_level( 'status', 'crap' ) } );

  # script load
  Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'sprawl_loaded', $IRSSI{name}, $VERSION, $IRSSI{authors});
}

sub unload {
  Irssi::printformat(MSGLEVEL_CLIENTCRAP, 'sprawl_unload', $IRSSI{name});
  Irssi::command('SET -default theme');
}

initialize();
