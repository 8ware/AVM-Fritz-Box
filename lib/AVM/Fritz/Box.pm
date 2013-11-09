package AVM::Fritz::Box;

use 5.014002;
use strict;
use warnings;

=head1 NAME

AVM::Fritz::Box - Perl interface to AVM's FRITZ!Box

=head1 SYNOPSIS

  use AVM::Fritz::Box;

  $fritzbox = AVM::Fritz::Box->new();
  $fritzbox->login($password) or die "cannot login: " . $fritzbox->status();

  $response = $fritzbox->get("syslog.lua", { tab => wlan });
  $response = $fritzbox->post("syslog.lua", { tab => wlan });

  if ($fritzbox->session_expired()) {
      $fritzbox->login($password);
  } else {
      printf "session expires in %ds\n", $fritzbox->session_expires();
  }

  $fritzbox->logout() or warn "cannot logout: " . $fritzbox->status();

  # OR

  use AVM::Fritz::Box ':api';

  fritzbox new_feature => sub {
      # do some magic stuff...
  };

=head1 DESCRIPTION

This module is the base for all functional extensions regarding the FRITZ!Box.
It provides the basic operations like GET and POST requests and cares about
several parameters (requests as well as responses).

=head2 EXPORT

None by default. The C<api> tag will import the C<fritzbox> subroutine which
is used to extend the capability of the module in an object oriented way. For
more information consider the description of this subroutine somewhere below.

=cut

use base 'Exporter';

our %EXPORT_TAGS = ( 'api' => [ qw( fritzbox ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'api'} } );

our $VERSION = '1.00';


use Carp;
use LWP::UserAgent;

=head2 VARIABLES

The URL of the FRITZ!Box is stored in the public C<$FRITZBOX> variable and
thus can be modified if e.g. the FRITZ!Box is only reachable under a certain
IP or other domain. Simply define

  $AVM::Fritz::Box::FRITZBOX = 'http://box.url'; # w/o slash, but protocol

=cut

our $FRITZBOX = 'http://fritz.box';

=head2 METHODS

=over 4

=item new()

Creates a new FRITZ!Box instance with an initial SID of C<0000000000000000>
and a default user agent (see L<perldoc/LWP::UserAgent>).

=cut

sub new($) {
	my $class = shift;

	my $self = {
		sid => '0' x 16,
		agent => LWP::UserAgent->new(),
	};

	return bless $self, $class;
}

=item get($url[, $params])

Sends a GET request to the FRITZ!Box. The SID is set implicitly (if defined)
and must not be specified additionally. Note, that the SID C<0000000000000000>
is always valid. As a side effect the request time and the status of the last
response will be set. Beside the URL some parameters can be passed optionally
as hash reference. Consider the following example:

  $self->get("cgi-bin/webcm", { getpage => '../html/de/menus/menu2.html' })

which will result in the following URL (assuming that C<$FRITZBOX> was not
altered):

  http://fritz.box/cgi-bin/webcm?sid=0123456789abcdef&getpage=../html/de/menus/menu2.html

The method always returns a C<HTTP::Response> object.

=cut

sub get($$;$) {
	my $self = shift;
	my $path = shift;
	my $params = shift || {};

	$params->{sid} = $self->{sid} if defined $self->{sid};
	my $url = "$FRITZBOX/$path?" . join '&',
			map { $_ . '=' . $params->{$_} } keys $params;

	$self->{reqtime} = time;
	my $response = $self->{agent}->get($url);
	$self->{status} = $response->status_line();

	return $response;
}

=item post($url[, $params])

Sends a POST request to the FRITZ!Box. See C<get>-method for information
about implicit parameters, expiration time and status settings.

=cut

sub post($$;$) {
	my $self = shift;
	my $path = shift;
	my $params = shift || {};

	$params->{sid} = $self->{sid} if defined $self->{sid};
	my $url = "$FRITZBOX/$path";

	$self->{reqtime} = time;
	my $response = $self->{agent}->post($url, $params);
	$self->{status} = $response->status_line();

	return $response;
}

=item status()

Returns the status line of the last request.

=back

=cut

sub status($) {
	my $self = shift;

	return $self->{status};
}

=head2 API

The current API only consists of the C<fritzbox> subroutine and is imported
via the C<api> tag as shown in the SYNOPSIS section.

=over 4

=item fritzbox($subname, $subref)

This function is only provided to extend the API of the FRITZ!Box easily by
adding the given subroutine reference with the specified name to the namespace
C<AVM::Fritz::Box>. Within the method the reference to itself can be used as
is usual.

  use AVM::Fritz::Box ':api';

  fritzbox new_feature => sub {
      $self = shift;

      # check SID...
      warn unless defined $self->{sid};

      # send request...
      $resp = $self->get("cgi-bin/webcm", $params);

      # print request time and status line
      say 'sent at ', join ':', (localtime $self->{reqtime})[2, 1, 0];
      say $self->status()," eq ", $resp->status_line();

      # do stuff...

      return $resp->is_success();
  }; # <-- DONT FORGET THE SEMICOLON!

=cut

sub fritzbox($$) {
	my $subname = shift;
	my $subref = shift;

	no strict 'refs';
	my $symname = __PACKAGE__ . '::' . $subname;
	if (defined *{$symname}) {
		carp "already defined: $symname";
	} else {
		*{$symname} = $subref;
	}
	use strict 'refs';
}

=back

=cut


1;
__END__

=head1 TODOs

=over 4

=item *

C<use AVM::Fritz::Box::Session> implicitly as that API is usually used always
(but consider cyclic dependencies etc.)

=item *

check parameters, i.e. $self == $_[0] in methods and $self != $_[0] in api
functions

=item *

only define fritzbox function if API should be included and define the methods
only if the API is not imported (?)

=back

=head1 AUTHOR

8ware, E<lt>8wared@googlemail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by 8ware

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

