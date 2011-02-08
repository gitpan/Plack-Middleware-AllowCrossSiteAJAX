package Plack::Middleware::AllowCrossSiteAJAX;
use strict;
use warnings;

use parent qw( Plack::Middleware );

our $VERSION = 0.02;

use Plack::Util::Accessor
    qw( origin timeout credentials methods custom_headers default_headers );

sub prepare_app {
    my ($self) = @_;
    $self->origin('*')    unless defined $self->origin;
    $self->timeout(30)    unless defined $self->timeout;
    $self->credentials(1) unless defined $self->credentials;
    $self->methods(
        [   qw(PROPFIND PROPPATCH COPY MOVE DELETE MKCOL LOCK UNLOCK
                PUT GETLIB VERSION-CONTROL CHECKIN CHECKOUT UNCHECKOUT REPORT
                UPDATE CANCELUPLOAD HEAD OPTIONS GET POST)
        ]
    ) unless defined $self->methods;
    $self->custom_headers( [] ) unless defined $self->custom_headers;
    $self->default_headers(
        [   qw(Content-Type Depth User-Agent X-File-Size
                X-Requested-With If-Modified-Since X-File-Name Cache-Control)
        ]
    ) unless defined $self->default_headers;
}

sub call {
    my ( $self, $env ) = @_;

    my $origin = $self->origin;

    # This is mostly written in accordance with:
    # https://developer.mozilla.org/en/HTTP_access_control
    $origin = $env->{HTTP_ORIGIN}
        if ( $origin eq '*'
        && $self->credentials
        && defined $env->{HTTP_ORIGIN} );
    my $headers = [ 'Access-Control-Allow-Origin' => $origin ];

    push( @$headers, 'Access-Control-Allow-Credentials' => 'true' )
        if $self->credentials();

    if ( $env->{REQUEST_METHOD} eq 'OPTIONS' ) {

        # Preflight request: add in all the specified options.
        push(
            @$headers,
            'Access-Control-Allow-Methods' =>
                join( ', ', @{ $self->methods } ),
            'Access-Control-Max-Age'       => $self->timeout,
            'Access-Control-Allow-Headers' => join( ', ',
                @{ $self->custom_headers },
                @{ $self->default_headers } ),
            'Content-Type' => 'text/plain'
        );
        return [ 200, $headers, [''] ];
    }

    my $r = $self->app->($env);
    $self->response_cb(
        $r,
        sub {
            my $r = shift;
            push( @{ $r->[1] }, @$headers );
        }
    );
}

1;

__END__

=head1 NAME

Plack::Middleware::AllowCrossSiteAJAX - DEPRECATED

=head1 IMPORTANT

This module is deprecated. Please use L<Plack::Middleware::CrossOrigin> instead.

=head1 AUTHOR

Leo Lapworth
Michael FIG (Original author)

=head1 SEE ALSO

L<Plack::Middleware::CrossOrigin>

=cut
