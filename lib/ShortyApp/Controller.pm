package ShortyApp::Controller;
use Mojo::Base 'Mojolicious::Controller';
use MongoDB;
use DateTime;
use Mojo::Util qw(url_escape);

sub welcome {
  my $self = shift;

  $self->render();
}

sub generate {
	my $self = shift;

	my $url 	= $self->param('url')  || '';
	my $name 	= $self->param('name') || '';
	my $db 		= $self->db;
	my $routes  = $db->get_collection( 'routes' );

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

	my $result = $routes->insert({
		_id => $name,
		url => $url,
		added => DateTime->now,
		});
	my $last_error = $db->last_error();

	if (!defined($last_error->{'err'})) {
		$self->render( db_response => 'ok', url => $url, name => $name );
	} else {
		$self->render( db_response => 'fail', url => $url, name => $name );
	}
	
}

# ajax function to check if shortcode is available
sub checkname {
	my $self = shift;
	my $name = $self->param('name');
	my $status;
	
	my $db 	   = $self->db;
	my $routes = $db->get_collection( 'routes' );

	my $res = $routes->find({ _id => $name });

	if ($res->count == 0) {
		$status = 'ok';
	} else {
		$status = 'taken';
	}

	$self->render( text => $status );
}

# route shortcodes
sub route {
	my $self   = shift;
	my $db     = $self->db;
	my $routes = $db->get_collection( 'routes' );

	my $cursor = $routes->find({ _id => $self->stash('name') });
	my $router = $cursor->next;

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


1;
