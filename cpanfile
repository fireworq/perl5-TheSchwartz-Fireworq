requires 'Class::Accessor::Lite';
requires 'Class::Load';
requires 'URI::Escape';
requires 'JSON::XS';
requires 'Furl';
requires 'Plack';
requires 'TheSchwartz';

on 'test' => sub {
    requires 'Test::More';
    requires 'Test::TCP';
    requires 'Plack::Test';
    requires 'HTTP::Request::Common';
};
