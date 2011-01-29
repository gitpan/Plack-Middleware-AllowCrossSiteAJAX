use Test::More;
use Plack::Test;
use Plack::Builder;
use Plack::Middleware::AllowCrossSiteAJAX;
use HTTP::Request;
use URI;

my $app = sub {
    return [ 200, [ 'Content-Type' => 'text/plain' ], ["Hello"] ];
};

my @tests = (
    {   name           => 'Basic request',
        request_method => 'GET',
        request_url    => '/foo',
        app            => $default_app,
        options        => {},
        headers_out    => {
            'Access-Control-Allow-Origin'      => '*',
            'Access-Control-Allow-Credentials' => 'true',
        },
    },
    {   name           => 'Credentials off',
        request_method => 'GET',
        request_url    => '/foo',
        app            => $default_app,
        options        => { credentials => 0 },
        headers_out    => { 'Access-Control-Allow-Origin' => '*', },
    },
    {   name           => 'Set origin limit',
        request_method => 'GET',
        request_url    => '/foo',
        app            => $default_app,
        options        => { origin => 'http://www.example.com/' },
        headers_out    => {
            'Access-Control-Allow-Origin'      => 'http://www.example.com/',
            'Access-Control-Allow-Credentials' => 'true',
        },
    },
    {   name           => 'OPTIONS request method',
        request_method => 'OPTIONS',
        request_url    => '/foo',
        app            => $default_app,
        options        => {
            origin  => 'http://www.example.com/',
            methods => [qw(GET POST)],
        },
        headers_out => {
            'Access-Control-Allow-Origin'      => 'http://www.example.com/',
            'Access-Control-Allow-Credentials' => 'true',
            'Access-Control-Allow-Methods'     => 'GET, POST',
            'Access-Control-Max-Age'           => '30',
            'Access-Control-Allow-Headers' =>
                'Content-Type, Depth, User-Agent, X-File-Size, '
                . 'X-Requested-With, If-Modified-Since, X-File-Name, Cache-Control',
        },
    },

);

foreach my $test (@tests) {

    pass( '---- ' . $test->{name} . ' ----' );
    my $handler = builder {
        enable "Plack::Middleware::AllowCrossSiteAJAX",
            %{ $test->{options} || {} };
        $app;
    };

    test_psgi
        app    => $handler,
        client => sub {
        my $cb = shift;

        my $req = HTTP::Request->new( $test->{request_method},
            $test->{request_url} );
        my $res = $cb->($req);

        my $h = $res->headers();

        # Do not worry about content-type
        $h->remove_header('Content-Type');

        while ( my ( $header, $value ) = each %{ $test->{headers_out} } ) {
            is $res->header($header), $value, "Header $header - ok";
            $h->remove_header($header);
        }

        is $h->as_string, '', 'No extra headers were set';

        };

}

done_testing;
