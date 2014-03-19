#! /usr/bin/env perl

use strict;
use warnings;

use feature 'say';


use Test::More 'no_plan';#tests => 1;
#use AVM::Fritz::Box;
BEGIN { use_ok('AVM::Fritz::Box::Session') };


use Digest::MD5 'md5_hex';
use Encode 'encode';
use XML::Simple 'xml_out';

use AVM::Fritz::Box::Test::FakeAgent;


my $fritzbox = AVM::Fritz::Box->new();

my $challenge = '8891c710';
my $sid = 'ff88e4d39354992f';
my $password = "password";

my $agent = AVM::Fritz::Box::Test::FakeAgent->init($fritzbox);
$agent->content(
	"login_sid.lua" => xml_out({
			SID => $sid,
			Challenge => $challenge
		}, NoAttr => 1, RootName => 'SessionInfo', XMLDecl => 1),
	"jason_boxinfo.xml" => join ("\n", <DATA>),
);

is($fritzbox->session_expires(), 0,
		"session expiration time is zero before login");

#$agent->content($challenge_data, $info_data, $challenge_data);
ok($fritzbox->login($password), "login succeeds");
my $got = $agent->params->{response};
my $expected = '8891c710-a18653502a435e39e56cbf83d8f4abed';
is($got, $expected, "correct computation of UTF-16LE encoded md5sum");

ok($fritzbox->session_expires() - time - 10 * 60 <= 1,
		"expiration time of session is 10min in the future");
ok(! $fritzbox->session_expired(), "session should not be expired after login");

$fritzbox->logout();
is($agent->params->{sid}, $sid, "using correct SID for logout");

ok($fritzbox->session_expired(), "session should be expired after logout");
is($fritzbox->session_expires(), 0,
		"session expiration time is zero after logout");

__DATA__
<j:BoxInfo xmlns:j="http://jason.avm.de/updatecheck/">
	<j:Name>FRITZ!Box Fon WLAN 7170</j:Name>
	<j:HW>94</j:HW>
	<j:Version>29.04.87</j:Version>
	<j:Revision>19985</j:Revision>
	<j:Serial>XXXXXXXXXXXX</j:Serial>
	<j:OEM>avm</j:OEM>
	<j:Lang>de</j:Lang>
	<j:Annex>B</j:Annex>
	<j:Lab></j:Lab>
	<j:Country>049</j:Country>
	<j:Flag>nomini</j:Flag>
</j:BoxInfo>

