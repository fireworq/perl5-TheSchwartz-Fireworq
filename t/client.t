use strict;
use warnings;

use Test::More;
use Test::TCP;

use Plack::Runner;
use Plack::Request;
use JSON::XS qw(decode_json encode_json);

use TheSchwartz::Fireworq;
use TheSchwartz::Job;

my $echo = sub {
    my ($env) = @_;

    my $req = Plack::Request->new($env);
    my $job = decode_json($req->content);

    my $res = $req->new_response(200);
    $res->content_type('application/json');
    $res->body(encode_json({
        method => $req->method,
        path   => $req->path,
        job    => $job,
    }));
    return $res->finalize;
};


{
    package My::Worker1;
    use parent qw(TheSchwartz::Worker);
}

{
    package My::Worker2;
    use parent qw(TheSchwartz::Worker);
    sub max_retries { 5 }
    sub retry_delay { 60 }
}

test_tcp
    client => sub {
        my ($port) = @_;
        my $worker_url = 'http://example.com/work';
        my $client = TheSchwartz::Fireworq->new(
            server => "http://127.0.0.1:$port",
            worker => $worker_url,
        );

        my $worker_class = 'My::Worker1';
        my $arg = { id => 3 };

        my $res = $client->insert($worker_class, $arg);
        ok $res->is_success;

        my $requested = decode_json($res->content);
        is $requested->{method}, 'POST';
        is $requested->{path}, "/job/$worker_class";

        my $job = $requested->{job};
        is $job->{url}, $worker_url;
        is $job->{run_after}, 0;
        is $job->{max_retries}, 0;
        is $job->{retry_delay}, 0;

        my $payload = $job->{payload};
        is_deeply $payload->{funcname}, $worker_class;
        is_deeply $payload->{arg}, $arg;
    },
    server => sub {
        my $port = shift;
        my $runner = Plack::Runner->new;
        $runner->parse_options(split(/\s+/, qq(
            --host 127.0.0.1
            --env test
            --port $port
        )));
        $runner->run($echo);
        exit;
    };

test_tcp
    client => sub {
        my ($port) = @_;
        my $worker_url = 'http://example.com/work';
        my $client = TheSchwartz::Fireworq->new(
            server => "http://127.0.0.1:$port",
            worker => $worker_url,
        );

        my $worker_class = 'My::Worker2';
        my $arg = { id => 7 };

        my $res = $client->insert($worker_class, $arg);
        ok $res->is_success;

        my $requested = decode_json($res->content);
        is $requested->{method}, 'POST';
        is $requested->{path}, "/job/$worker_class";

        my $job = $requested->{job};
        is $job->{url}, $worker_url;
        is $job->{run_after}, 0;
        is $job->{max_retries}, 5;
        is $job->{retry_delay}, 60;

        my $payload = $job->{payload};
        is_deeply $payload->{funcname}, $worker_class;
        is_deeply $payload->{arg}, $arg;
    },
    server => sub {
        my $port = shift;
        my $runner = Plack::Runner->new;
        $runner->parse_options(split(/\s+/, qq(
            --host 127.0.0.1
            --env test
            --port $port
        )));
        $runner->run($echo);
        exit;
    };

test_tcp
    client => sub {
        my ($port) = @_;
        my $worker_url = 'http://example.com/work';
        my $client = TheSchwartz::Fireworq->new(
            server => "http://127.0.0.1:$port",
            worker => $worker_url,
        );

        my $worker_class = 'My::Worker1';
        my $arg = { id => 1 };
        my $run_after = 30;

        my $res = $client->insert(TheSchwartz::Job->new(
            funcname  => $worker_class,
            arg       => $arg,
            run_after => time + $run_after,
        ));
        ok $res->is_success;

        my $requested = decode_json($res->content);
        is $requested->{method}, 'POST';
        is $requested->{path}, "/job/$worker_class";

        my $job = $requested->{job};
        is $job->{url}, $worker_url;
        is $job->{run_after}, $run_after;
        is $job->{max_retries}, 0;
        is $job->{retry_delay}, 0;

        my $payload = $job->{payload};
        is_deeply $payload->{funcname}, $worker_class;
        is_deeply $payload->{arg}, $arg;
    },
    server => sub {
        my $port = shift;
        my $runner = Plack::Runner->new;
        $runner->parse_options(split(/\s+/, qq(
            --host 127.0.0.1
            --env test
            --port $port
        )));
        $runner->run($echo);
        exit;
    };

done_testing();
