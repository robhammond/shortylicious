package ShortyApp;
use Mojo::Base 'Mojolicious';
use MongoDB::Connection;
use Mojolicious::Plugin::Config;

# This method will run once at server start
sub startup {
  my $self = shift;
  
  # Get config from file
  my $config = $self->plugin('Config');

  # Init MongoDB
  $self->attr(db => sub { 
      MongoDB::Connection
          ->new(host => $config->{database_host})
          ->get_database($config->{database_name});
  });
  $self->helper('db' => sub { shift->app->db });

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