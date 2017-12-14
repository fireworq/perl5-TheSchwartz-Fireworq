package Plack::Middleware::TheSchwartz::Fireworq;
use strict;
use warnings;

use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(path);
use Plack::Request;
use JSON::XS qw(decode_json encode_json);
use Class::Load qw(load_class);
use TheSchwartz::Fireworq::Job;

sub call {
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);
    return $self->_handle($req) if $req->path eq $self->path;
    return $self->app->($env);
}

sub _handle {
    my ($self, $req) = @_;
    return [ 405, [], [ 'Method Not Allowed' ] ]
        unless $req->method eq 'POST';

    my $payload = decode_json($req->content);

    my $worker = load_class($payload->{funcname});
    my $job = TheSchwartz::Fireworq::Job->new(%$payload);
    $worker->work($job);

    my $res = $req->new_response(200);
    $res->content_type('application/json');
    $res->body(encode_json({
        status  => $job->status,
        message => $job->message,
    }));

    return $res->finalize;
}

1;
__END__
