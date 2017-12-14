use strict;
use warnings;

use Test::More;
use Test::TCP;

use Plack::Runner;
use Plack::Request;
use JSON::XS qw(decode_json encode_json);

use TheSchwartz::Fireworq::Simple;

my $fireworq = sub {
    my ($env) = @_;

    my $req = Plack::Request->new($env);
    my $job = decode_json($req->content);

    my $res = $req->new_response(200);
    $res->content_type('application/json');
    $res->body(encode_json({
        %$job,
        id         => 123,
        queue_name => 'test1',
        category   => $job->{funcname},
    }));
    return $res->finalize;
};


{
    package My::Worker;
    use parent qw(TheSchwartz::Worker);
}

test_tcp
    client => sub {
        my ($port) = @_;
        my $worker_url = 'http://example.com/work';
        my $client = TheSchwartz::Fireworq::Simple->new(
            server => "http://127.0.0.1:$port",
            worker => $worker_url,
        );

        my $worker_class = 'My::Worker';
        my $arg = {};

        my $id = $client->insert($worker_class, $arg);
        is $id, 123;
    },
    server => sub {
        my $port = shift;
        my $runner = Plack::Runner->new;
        $runner->parse_options(split(/\s+/, qq(
            --host 127.0.0.1
            --env test
            --port $port
        )));
        $runner->run($fireworq);
        exit;
    };

done_testing();
