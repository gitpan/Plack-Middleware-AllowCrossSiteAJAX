package Plack::Middleware::AllowCrossSiteAJAX;
use strict;
use warnings;

use parent qw( Plack::Middleware );

our $VERSION = 0.01;

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

Plack::Middleware::AllowCrossSiteAJAX - Set the CORS Access-Control-Allow-Origin header family 

=head1 SYNOPSIS

  # in app.psgi
  use Plack::Builder;

  builder {
      enable "AllowCrossSiteAJAX";
      $app;
  };

=head1 DESCRIPTION

Plack::Middleware::AllowCrossSiteAJAX allows your client browser to submit
XmlHttpRequest documents to your server if they were referred by
a different site.

This is according to the Cross-Origin Resource Sharing (CORS) standard,
as published at http://www.w3.org/TR/access-control/

=head1 CONFIGURATIONS

=over 4

=item origin

A string that specifies the allowed origin web site.  Defaults to
'*' which means any origin is allowed.

=item credentials

A boolean whether or not credentials should be forwarded to this
page.  Defaults to 1.  If you want to forward credentials, you
should also add the following Javascript to your page:

    // From: http://www.nczonline.net/blog/2010/05/25/cross-domain-ajax-with-cross-origin-resource-sharing/
    function createCORSRequest(method, url){
	    var xhr = new XMLHttpRequest();
	    if ("withCredentials" in xhr){
	        xhr.open(method, url, true);
	    } else if (typeof XDomainRequest != "undefined"){
	        xhr = new XDomainRequest();
	        xhr.open(method, url);
	    } else {
	        xhr = null;
	    }
	    return xhr;
	}
   
And then call 'var xhr = createCORSRequest(method, url); xhr.withCredentials = "true";' when you want to
have an XMLHttpRequest that forwards credentials.

=item custom_headers

An arrayref of any custom headers that are allowed to be submitted to the page.
Default is [].

=item default_headers

An arrayref of standard headers that are allowed to be submitted to the page.
Default taken from http://www.webdavsystem.com/ajax/programming/cross_origin_requests

=item methods

An arrayref that specifies the HTTP methods allowed by this page.
Defaults to all standard HTTP and WebDAV methods (['GET', 'POST', ...]).


=item timeout

An integer that specifies the number of seconds before the client
should refresh this information.  Defaults to 30.

=back

=head1 AUTHOR

Leo Lapworth
Michael FIG (Original author)

=head1 SEE ALSO

L<Plack>

=cut
