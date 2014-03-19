package AVM::Fritz::Box::Session;

use 5.014002;
use strict;
use warnings;

=head1 NAME

AVM::Fritz::Box::Session - Perl interface to FRITZ!Box' session management

=head1 SYNOPSIS

  use AVM::Fritz::Box;
  use AVM::Fritz::Box::Session;

=head1 DESCRIPTION

This module extends the C<AVM::Fritz::Box> module by session related methods.
Thus it MUST be used in combination with that base module.

=head2 EXPORT

None by default.

=cut

our $VERSION = '1.00';


use AVM::Fritz::Box qw(:api $INIT_REQTIME);
use Digest::MD5 'md5_hex';
use Encode 'encode';
use HTTP::Status 'HTTP_SEE_OTHER';
use XML::Simple 'xml_in';

=head2 METHODS

=over 4

=item login($password)

Logs into the FRITZ!Box via the challenge-response authentication as described
in [1]. The rusult is a valid session ID (SID) distinct from C<'0' x 16>.

Note, that the current implementation is written for FRITZ!Box 7170 (Firmware
v29.04.87).

=cut

fritzbox login => sub($$) {
	my $self = shift;
	my $password = shift;

	my $response = $self->get("login_sid.lua");
	return 0 unless $response->is_success();
	my $xml = xml_in($response->decoded_content());

	if ($xml->{iswriteaccess}) {
		$self->{sid} = $xml->{SID};
		return 1;
	}

	my $challenge = $xml->{Challenge};
	$password =~ s/(.)/ord $1 > 255 ? '.' : $1/eg;
	my $resp = encode('UTF-16LE', "$challenge-$password");
	my $chresp = "$challenge-" . md5_hex($resp);

#	$response = $self->post("login.lua", { response => $chresp });
#	unless ($response->code() == 303) {
#		$self->{status} = "wrong password (?)";
#		return 0;
#	}
#	my $resp_string = $response->as_string();
#	my ($sid) = $resp_string =~ /Location:.+sid=(\w+)$/m;
#	$self->{sid} = $sid if $sid;

	if ($self->info eq '29.04.88') {
		$self->login_v290487($chresp);
	} else {
		$self->login_fritzos($chresp);
	}

	return $self->{sid} ne 0 x 16;
};

fritzbox login_v290487 => sub($) {
	my $self = shift;
	my $chresp = shift;

	my $response = $self->post("login.lua", { response => $chresp });
	unless ($response->code() == HTTP_SEE_OTHER) {
		$self->{status} = "wrong password (?)";
		return 0;
	}

	my $location = $response->header('Location');
	my ($sid) = $location =~ /sid=(\w+)$/;
	$self->{sid} = $sid if $sid;
};

fritzbox login_fritzos => sub($) {
	my $self = shift;
	my $chresp = shift;

	my $response = $self->get("login_sid.lua",
			{ username => '', response => $chresp });
	return 0 unless $response->is_success();
	my $xml = xml_in($response->decoded_content());
	$self->{sid} = $xml->{SID};
};

=item logout()

Logs out of the FRITZ!Box as described in [1].

=cut

fritzbox logout => sub($) {
	my $self = shift;

	my $response = $self->get("login_sid.lua", { logout => 1 });

	if ($response->is_success()) {
		$self->{reqtime} = $INIT_REQTIME;
		return 1;
	}

	return 0;
};

=item session_expires()

Returns the time in milliseconds (as described in L<perlfunc/time>) plus 10
minutes 'cause the session will expire after 10 minutes if no request is sent
within this time range.

=cut

fritzbox session_expires => sub($) {
	my $self = shift;

	return $self->{reqtime} + 10 * 60;
};

=item session_expired()

Returns a boolean value whether the session is expired. This is the case if
no request was sent within the last 10 minutes.

=cut

fritzbox session_expired => sub($) {
	my $self = shift;

	return $self->{reqtime} + 10 * 60 < time;
};

=back

=cut


1;
__END__

=head1 SEE ALSO

  [1] http://www.avm.de/de/Extern/files/session_id/AVM_Technical_Note_-_Session_ID.pdf

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

=item * 

return time to wait on login failure

=back

=head1 AUTHOR

8ware, E<lt>8wared@googlemail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by 8ware

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

