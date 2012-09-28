package ShortyApp;
use Mojo::Base 'Mojolicious';
use Mojolicious::Plugin::Config;

# This method will run once at server start
sub startup {
  my $self = shift;
  
  my $config = $self->plugin('Config');
  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('controller#welcome');

  $r->post('/')->to('controller#generate');
  $r->get('/_checkname')->to('controller#checkname');

  # disable automatic handling of file format, only match allowed characters
  $r->route('/:name', name => qr![-0-9a-zA-Z]+!, format => 0)->to('controller#route');
}

1;