package TheSchwartz::Fireworq::Simple;
use strict;
use warnings;

use parent qw(TheSchwartz::Fireworq);
use JSON::XS qw(decode_json);

sub new {
    my ($class, %args) = @_;
    return $class->SUPER::new(%args);
}

sub insert {
    my ($self, @args) = @_;
    my $res = $self->SUPER::insert(@args);
    if ($res->is_success) {
        my $job = eval { decode_json($res->content) } or return;
        return $job->{id};
    }
    return;
}

1;
__END__
