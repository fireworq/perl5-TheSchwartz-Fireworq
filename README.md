# NAME

TheSchwartz::Fireworq - [TheSchwartz](https://metacpan.org/pod/TheSchwartz) interface for [Fireworq](https://github.com/fireworq/fireworq).

# SYNOPSIS

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
            pah => '/work';
        $app;
    };

# AUTHOR

INA Lintaro <tarao.gnn@gmail.com>

# SEE ALSO

- [TheSchwartz](https://metacpan.org/pod/TheSchwartz)
- [TheSchwartz::Simple](https://metacpan.org/pod/TheSchwartz::Simple)
