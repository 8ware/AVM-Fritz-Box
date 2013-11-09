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
  }; # <-- DONT FORGET THE SEMICOLON!

=head1 DESCRIPTION

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

  $AVM::Fritz::Box::FRITZBOX = 'your.special.url'; # w/o slash, but protocol

=cut

our $FRITZBOX = 'http://fritz.box';

=head2 METHODS

=over 4

=item new()

Creates a new FRITZ!Box instance with an initial SID of C<0000000000000000>
and a default user agent (see L<perldoc/LWP::UserAgent>).

=back

=cut

sub new($$) {
	my $class = shift;

	my $self = {
		sid => '0' x 16,
		agent => LWP::UserAgent->new(),
	};

	return bless $self, $class;
}

=item get($url[, $params])

Sends a GET request to the FRITZ!Box. The SID is set implicitly and must not
be specified additionally. Note, that the SID C<0000000000000000> is always
valid. As a side effect the expiration time and the status of the last
response will be set.

=cut

sub get($$;$) {
	my $self = shift;
	my $path = shift;
	my $params = shift || {};

	$params->{sid} = $self->{sid} if defined $self->{sid};
	my $url = "$FRITZBOX/$path?" . join '&',
			map { $_ . '=' . $params->{$_} } keys $params;

	$self->{expires} = time + 10 * 60;
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

	$params->{sid} = $self->{sid};
	my $url = "$FRITZBOX/$path";

	$self->{expires} = time + 10 * 60;
	my $response = $self->{agent}->post($url, $params);
	$self->{status} = $response->status_line();

	return $response;
}

=item status()

Returns the status line of the last request.

=cut

sub status($) {
	my $self = shift;

	return $self->{status};
}


=item fritzbox($subname, $subref)

This function is only provided to extend the API of the FRITZ!Box easily. To
add a new feature simply create a new module, e.g. C<FB::Example> where the
functionality is supplied as follows:

  use AVM::Fritz::Box ':api';

  fritzbox new_feature => sub {
      # do your thing!
  };

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


1;
__END__

=head1 SEE ALSO

  http://www.avm.de/de/Extern/files/session_id/AVM_Technical_Note_-_Session_ID.pdf

=head1 TODOs

=over 4

=item *

C<use AVM::Fritz::Box::Session> implicitly as that API is usually used always
(but consider cyclic dependencies etc.)

=item *

check parameters, i.e. $self == $_[0] in methods and $self != $_[0] in api
functions

=item *

only define fritzbox function if api shoud be included and define the methods
only if the api is not imported

=back

=head1 AUTHOR

8ware, E<lt>8wared@googlemail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by 8ware

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

