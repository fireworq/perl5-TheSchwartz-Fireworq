package TheSchwartz::Fireworq;
use strict;
use warnings;

our $VERSION = '0.0.1';

use Scalar::Util qw(blessed);
use Class::Load qw(load_class);
use URI::Escape qw(uri_escape);
use JSON::XS qw(encode_json);
use Furl;
use Class::Accessor::Lite::Lazy (
    ro_lazy => [qw(agent)],
);

sub new {
    my ($class, %args) = @_;
    return bless { %args }, $class;
}

sub list_jobs { }
sub lookup_job { }
sub set_verbose { }

sub insert {
    my ($self, $funcname, $arg) = @_;
    my $now = time;
    my $run_after = $now;
    if (blessed($_[1]) && $_[1]->isa('TheSchwartz::Job')) {
        $funcname = $_[1]->funcname;
        $arg = $_[1]->arg;
        $run_after = $_[1]->run_after if $_[1]->run_after;
    }
    my $worker_class = load_class($funcname);

    my $url = $self->{server} . '/job/' . uri_escape $funcname;
    $self->agent->post(
        $url,
        [ 'Content-Type' => 'application/json' ],
        encode_json({
            url => $self->{worker},
            payload => {
                funcname  => $funcname,
                arg       => $arg,
                run_after => $run_after,
            },
            run_after   => $run_after - $now,
            max_retries => $worker_class->max_retries,
            retry_delay => $worker_class->retry_delay,
        }),
    );
}

sub insert_jobs {
    my ($self, @jobs) = @_;
    $self->insert($_) for @jobs;
}

sub set_prioritize { }
sub set_floor { }
sub set_batch_size { }
sub set_strict_remove_ability { }

sub _build_agent {
    my ($self) = @_;
    return Furl->new;
}

1;
__END__
=head1 NAME

TheSchwartz::Fireworq - L<TheSchwartz> interface for L<Fireworq|https://github.com/fireworq/fireworq>.

=head1 SYNOPSIS

    package My::App;
    use TheSchwartz::Fireworq;
    
    sub work_asynchronously {
        my $client = TheSchwartz::Fireworq->new(
            server => 'http://localhost:8080',      # Fireworq host
            worker => 'http://localhost:5000/work', # Your app worker endpoint
        );
        $client->insert('My::Worker', { @_ });
    }
    
    package My::Worker;
    use parent qw(TheSchwartz::Worker);
    
    sub work {
        my ($class, $job) = @_;

        use Data::Dumper;
        warn Dumper $job->arg;
        
        $job->completed;
    }
    
    # app.psgi
    package main;
    use Plack::Builder;
    
    my $app = sub { ... };
    builder {
        enable 'TheSchwartz::Fireworq',
            path => '/work';
        $app;
    };

=head1 AUTHOR

INA Lintaro E<lt>tarao.gnn@gmail.comE<gt>

=head1 SEE ALSO

=over 4

=item L<TheSchwartz>

=item L<TheSchwartz::Simple>

=back

=cut
