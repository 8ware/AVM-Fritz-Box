package AVM::Fritz::Box::Test::FakeAgent;

use strict;
use warnings;


=head1 NAME

AVM::Fritz::Box::Test::FakeAgent - Perl module for testing AVM::Fritz::Box
modules without send requests to a real FRITZ!Box

=head1 SYNOPSIS

  use AVM::Fritz::Box;
  use AVM::Fritz::Box::Test::FakeAgent;
  use Test::More;

  # set up test configuration
  $fritzbox = AVM::Fritz::Box->new();
  $fakeagent = AVM::Fritz::Box::Test::FakeAgent->init($fritzbox);

  # set content of response
  $fakeagent->content($content);

  # request fake agent and evaluate result
  $response = $fritzbox->get($url, { param => $param });
  is($response->decoded_content, $content);
  is($fakeagent->url, $url);
  is($fakeagent->params, { param => $param });

=head1 DESCRIPTION

This module is used for test purposes only to avoid frequent requests to
the FRITZ!Box.

=cut


use Carp;
use HTTP::Response;
use Test::Simple;


=head2 METHODS

=over 4

=item AVM::Fritz::Box::Test::Fake::Agent->init($fritzbox)

Creates a new instance of a fake agent and replaces the agent of the
FRITZ!Box instance with that one. Returns the fake agent instance for
further configuration.

=cut

sub init($$) {
	my $class = shift;
	my $fritzbox = shift;

	my $self = bless {
		url => undef,
		params => undef,
		content => undef,
	}, $class;

	$fritzbox->{agent} = $self;

	return $self;
}

=item $fakeagent->get($url)

Simulates a GET request while setting the URL and its parameters. Returns
a HTTP 200 response with the afore set content. This method is typically
called by the FRITZ!Box module to test (via the AVM::Fritz::Box module).

=cut

sub get($$) {
	my $self = shift;
	my $url = shift;

	$url =~ s/\?(.+)//;
	$self->url($url);
	$self->params({ map { /^(.+)=(.*)/; $1, $2 ? $2 : '' } split /&/, $1 });

#	ok(defined $self->{params}->{sid});

	my $response = HTTP::Response->new(200);
	$response->content($self->content);

	return $response;
}

=item $fakeagent->post($url, $params)

Simulates a POST request while setting the URL and parameters. Returns
a HTTP 200 response with the afore set content. This method is typically
called by the FRITZ!Box module to test (via the AVM::Fritz::Box module).

=cut

sub post($$$) {
	my $self = shift;
	my $url = shift;
	my $params = shift;

	$self->url($url);
	$self->params($params);

#	ok(defined $self->{params}->{sid});

	my $response = HTTP::Response->new(200);
	$response->content($self->content);

	return $response;
}

=item $fakeagent->url([$url])

Returns the URL of the last request. The optional URL argument sets the
URL attribute.

=cut

sub url($;$) {
	my $self = shift;
	my $url = shift;

	if ($url) {
		$self->{url} = $url;
	} elsif (not $self->{url}) {
		carp("url was not set, yet");
	}

	return $self->{url};
}

=item $fakeagent->params([$params])

Returns the params as hash-reference of the last request. The optional
params argument sets the params attribute.

=cut

sub params($;$) {
	my $self = shift;
	my $params = shift;

	if ($params) {
		$self->{params} = $params;
	} elsif (not $self->{params}) {
		carp("params was not set, yet");
	}

	return $self->{params};
}

=item $fakeagent->content([$content])

Returns the content for the next response. The optional content argument
sets the content attribute.

=cut

sub content($;$) {
	my $self = shift;
	my $content = shift;

	if ($content) {
		$self->{content} = $content;
	} elsif (not $self->{content}) {
		carp("content was not set, yet");
	}

	return $self->{content};
}

=back

=cut


1;
__END__

=head1 AUTHOR

8ware, E<lt>8wared@googlemail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by 8ware

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

