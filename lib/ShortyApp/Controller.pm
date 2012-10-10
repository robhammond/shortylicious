package ShortyApp::Controller;
use Mojo::Base 'Mojolicious::Controller';
use ShortyApp::Couch;
use Mojo::Util qw(url_escape);

sub welcome {
  my $self = shift;

  $self->render();
}

sub generate {
	my $self = shift;

	my $url 	= $self->param('url')  || '';
	my $name 	= $self->param('name') || '';
	my $db 		= _create_dsn($self);

	# sanitise name
	$name =~ s![^-0-9a-zA-Z]!!g;

	# generate random string if name is empty or looks like an important file
	if ($name eq '') {
    	$name = _random_string(4);
	} elsif ($name =~ m{^(?:robots|htaccess|index|home)$}i) {
		$name = _random_string(4);
	}

	# return if URL is blank or doesn't look like a valid URL
	if (($url eq '') || ($url !~ m{^(?:[hf]t?tps?://)?\w+\.\w[^<>]*$}i)) {
		$self->render( db_response => 'fail', url => $url, name => $name );
	}

	# ensure URL starts with http/s or ftp
	if ($url !~ m{^[hf]t?tps?://}i) {
		$url = 'http://' . $url;
	}

	my $result = couch_insert($db, $url, $name);

	if (defined($result->{'ok'})) {
		$self->render( db_response => 'ok', url => $url, name => $name );
	} else {
		$self->render( db_response => 'fail', url => $url, name => $name );
	}
	
}

# ajax function to check if shortcode is available
sub checkname {
	my $self = shift;
	my $name = $self->param('name');
	my $db = _create_dsn($self);
	my $status;
	my $result = couch_exists($db, $name);
	if ($result == 404) {
		$status = 'ok';
	} elsif ($result == 200) {
		$status = 'taken';
	}
	$self->render( text => $status );
}

# route shortcodes
sub route {
	my $self = shift;
	my $db = _create_dsn($self);
	my $router = couch_fetch($db, $self->stash('name'));
	my $redirect = $router->{url};
	if (defined $redirect) {
		$self->res->code(301);
		$self->redirect_to($redirect);
	} else {
		$self->render_not_found;
	}
}

# internals

sub _random_string {
	my $len = shift;
 	my @chars=('a'..'z','A'..'Z','0'..'9','-');
 	my $random_string;
 	foreach (1..$len) {
   		$random_string .= $chars[rand @chars];
	}
	return $random_string;
}

sub _create_dsn {
  my $self = shift;

  my $couch_url  = $self->{app}->{defaults}->{config}->{couch}->{url};
  my $couch_db   = $self->{app}->{defaults}->{config}->{couch}->{db};
  my $couch_usr  = url_escape $self->{app}->{defaults}->{config}->{couch}->{user};
  my $couch_pass = url_escape $self->{app}->{defaults}->{config}->{couch}->{pass};

  # convert to http basic auth if necessary
  if ( ($couch_usr ne '') && ($couch_pass ne '') ) {
    if ($couch_url =~ m{^(https?://)(.*)$}i) {
      $couch_url = $1 . $couch_usr . ":" . $couch_pass . "@" . $2;
    }
  }
  $couch_url =~ s!^(.*?)/?$!$1/$couch_db/!;

  return $couch_url;
}

1;
