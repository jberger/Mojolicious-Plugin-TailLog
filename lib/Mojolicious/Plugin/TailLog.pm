package Mojolicious::Plugin::TailLog;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($plugin, $app, $conf) = @_;
  push @{ $app->renderer->classes }, __PACKAGE__;
  my $r = $conf->{route} || $app->routes->any('/log');
  $r->get('/')->to(cb => \&_tail_log)->name('tail_log');
}

sub _tail_log {
  my $c = shift;
  die 'Log must be a file' unless my $f = $c->app->log->path;
  return $c->render('tail_log_page') unless $c->tx->is_websocket;
  my $pid = open my $log, '-|', 'tail', '-f', $f;
  die "Could't spawn: $!" unless defined $pid;
  my $stream = Mojo::IOLoop::Stream->new($log);
  $stream->on(read  => sub { $c->send({text => pop}) });
  $stream->on(close => sub { kill KILL => $pid; close $log });
  my $sid = Mojo::IOLoop->stream($stream);
  $c->on(finish => sub { Mojo::IOLoop->remove($sid) });
}

1;

__DATA__

@@ tail_log_window.html.ep

<pre id="tail_log_window"></pre>
<script>
  var ws = new WebSocket('<%= url_for('tail_log')->to_abs->scheme('ws') %>');
  var log = document.getElementById('tail_log_window');
  ws.onmessage = function (event) { log.innerHTML += event.data };
</script>

@@ tail_log_page.html.ep

<!DOCTYPE html>
<html>
  <head>
    <title><%= title || "@{[app->moniker]} log file" %></title>
    %= stylesheet begin
      #tail_log_window {
        background-color: black;
        color: white;
        border-radius: 25px;
        padding: 20px;
      }
    % end
  </head>
  <body>
    %= include 'tail_log_window'
  </body>
</html>

