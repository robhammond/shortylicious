package ShortyApp::Couch;
use Mojo::UserAgent;
use Exporter;
@ISA = qw(Exporter);
our @EXPORT = qw(couch_insert couch_fetch couch_exists);

my $ua = Mojo::UserAgent->new;

sub couch_insert {
	my ($db, $url, $name) = @_;
	my $doc = { '_id' => $name, 'url' => $url };
	my $r = $ua->post( $db => { 'Content-Type' => 'application/json' } => Mojo::JSON->encode($doc) )->res->json;	
	return $r;
}

sub couch_fetch {
	my ($db, $id) = @_;
    my $r = $ua->get( $db . $id )->res->json;
    return $r;
}

sub couch_exists {
	my ($db, $id) = @_;
    my $r = $ua->head( $db . $id )->res->code;
    return $r;
}

1;