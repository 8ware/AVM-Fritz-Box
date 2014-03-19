#! /usr/bin/env perl

use strict;
use warnings;

use feature 'say';

use Test::More 'no_plan';#tests => 1;
BEGIN { use_ok('AVM::Fritz::Box') };


use AVM::Fritz::Box::Test::FakeAgent;


my $fritzbox = AVM::Fritz::Box->new();

my $agent = AVM::Fritz::Box::Test::FakeAgent->init($fritzbox);
$agent->content("jason_boxinfo.xml" => join "\n", <DATA>);


is(scalar $fritzbox->info(), "29.04.87",
		"compare version (info in scalar context)");
is_deeply({ $fritzbox->info() }, {
		Name => "FRITZ!Box Fon WLAN 7170",
		HW => 94,
		Version => "29.04.87",
		Revision => 19985,
		Serial => "XXXXXXXXXXXX",
		OEM => "avm",
		Lang => "de",
		Annex => "B",
		Lab => {},
		Country => "049",
		Flag => "nomini",
}, "compare received and expected info hash");


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

