package TheSchwartz::Fireworq::Job;
use strict;
use warnings;

use parent qw(TheSchwartz::Job);
use Class::Accessor::Lite (
    rw => [qw(status message)],
);

sub completed {
    my ($job) = @_;
    return 0 if $job->did_something;
    $job->message('ok');
    $job->status('success');
    $job->did_something(1);
}

sub permanent_failure {
    my ($job, $msg, $ex_status) = @_;
    return 0 if $job->did_something;
    $job->message($msg // $ex_status // '<no message>');
    $job->status('permanent-failure');
    $job->did_something(1);
}

sub decliend { die 'Not supported' }

sub failed {
    my ($job, $msg, $ex_status) = @_;
    return 0 if $job->did_something;

    if ( $job->did_something ) {
        return 0;
    }
    $job->message($msg // $ex_status // '<no message>');
    $job->status('failure');
    $job->did_something(1);
}

1;
__END__
