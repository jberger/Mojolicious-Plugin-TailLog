use Mojolicious::Lite;

plugin 'TailLog';

# log must be a real file, not a terminal
app->log->path(app->home->rel_file(app->moniker . '.log'));

my $count = 0;
Mojo::IOLoop->recurring(1 => sub {
  app->log->info('Count: ' . $count++);
});

app->start;

