use strict;
use warnings;

use Test::More tests => 5;
use Plack::Test;

use Plack::Builder;
use HTTP::Request::Common;
use JSON::XS qw(decode_json encode_json);

my $app = builder {
    enable 'TheSchwartz::Fireworq',
        path => '/work';
    sub { [ 200, [ 'Conent-Type' => 'text/plain' ], [ 'OK' ] ] };
};

{
    package My::Worker1;
    use parent qw(TheSchwartz::Worker);
    sub work {
        my ($class, $job) = @_;
        $job->completed;
    }
}

{
    package My::Worker2;
    use parent qw(TheSchwartz::Worker);
    sub work {
        my ($class, $job) = @_;
        $job->failed('foo');
    }
}

{
    package My::Worker3;
    use parent qw(TheSchwartz::Worker);
    sub work {
        my ($class, $job) = @_;
        $job->permanent_failure('bar');
    }
}

{
    package My::Worker4;
    use parent qw(TheSchwartz::Worker);
    sub work {
        my ($class, $job) = @_;
        die;
    }
}

test_psgi $app, sub {
    my ($cb) = @_;

    subtest 'success' => sub {
        my $req = POST '/work',
            'Content-Type' => 'application/json',
            Content => encode_json({
                funcname  => 'My::Worker1',
                arg       => { id => 3 },
                run_after => time,
            });

        my $res = $cb->($req);
        my $result = decode_json($res->content);
        is $result->{status}, 'success';
    };

    subtest 'failure' => sub {
        my $req = POST '/work',
            'Content-Type' => 'application/json',
            Content => encode_json({
                funcname  => 'My::Worker2',
                arg       => { id => 5 },
                run_after => time,
            });

        my $res = $cb->($req);
        my $result = decode_json($res->content);
        is $result->{status}, 'failure';
        is $result->{message}, 'foo';
    };

    subtest 'permanent-failure' => sub {
        my $req = POST '/work',
            'Content-Type' => 'application/json',
            Content => encode_json({
                funcname  => 'My::Worker3',
                arg       => { id => 7 },
                run_after => time,
            });

        my $res = $cb->($req);
        my $result = decode_json($res->content);
        is $result->{status}, 'permanent-failure';
        is $result->{message}, 'bar';
    };

    subtest 'die' => sub {
        my $req = POST '/work',
            'Content-Type' => 'application/json',
            Content => encode_json({
                funcname  => 'My::Worker4',
                arg       => { id => 7 },
                run_after => time,
            });

        my $res = $cb->($req);
        ok $res->is_server_error;
        ok !$res->{status};
    };

    subtest 'wrong method' => sub {
        my $req = PUT '/work',
            'Content-Type' => 'application/json',
            Content => encode_json({
                funcname  => 'My::Worker1',
                arg       => { id => 7 },
                run_after => time,
            });

        my $res = $cb->($req);
        is $res->code, 405;
    };
};
