#!perl -wT
# Win32::GUI test suite.
# $Id: 05_NotifyIcon_05_DESTROY.t,v 1.1 2006/01/11 21:26:16 robertemay Exp $
#
# test coverage of Notify Icons

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 13;

use Win32::GUI();
use Win32::GUI::BitmapInline();

my $icon = geticon();

my $ctrl = "NotifyIcon";
my $class = "Test::$ctrl";

# Test DESTRUCTION
{
	my $W = new Win32::GUI::Window(
	    -name => "TestWindow",
	);

	my $C = Test::NotifyIcon->new(
		$W,
		-name => "NI",
		-icon => $icon
	);

	isa_ok($C,$class, "\$W->AddNotifyIcon creates $class object");
	isa_ok($W->NI, $class, "\$W->NI contains a $class object");

	# DESTROY tests
	is($Test::NotifyIcon::x, 0, "DESTROY not called yet");
	undef $C; # should still be a reference from the parent object
	is($Test::NotifyIcon::x, 0, "DESTROY not called yet");
	undef $W; # should reduce ref count to parent to zero, and in turn Timer
	is($Test::NotifyIcon::x, 1, "DESTROY called when parent destroyed");
}

{
	my $W = new Win32::GUI::Window(
	    -name => "TestWindow",
	);

	my $C = Test::NotifyIcon->new(
		$W,
		-name => "NI",
		-icon => $icon
	);

	my $id = $C->{-id};
	ok(defined $W->{-notifyicons}->{$id}, "Timer's id is stored in parent");
	is($C, $W->NI, "Reference sotered in Parent");
	
	# DESTROY tests
	$Test::NotifyIcon::x = 0;
	is($Test::NotifyIcon::x, 0, "DESTROY not called yet");
	undef $C; # should still be a reference from the parent object
	is($Test::NotifyIcon::x, 0, "DESTROY not called yet");
	$W->{NI} = undef; # naughty way to remove timer
	is($Test::NotifyIcon::x, 1, "DESTROY called when parent reference removed");
	ok(!defined $W->{-notifyicons}->{$id}, "DESTROY() tidies parent");
	ok(!defined $W->{NI}, "DESTROY() tidies parent");
	undef $W;
	is($Test::NotifyIcon::x, 1, "DESTROY not called when parent destroyed");
}

exit(0);

### -- helper functions --

sub geticon
{
	return newIcon Win32::GUI::BitmapInline( q(
AAABAAIAICAQAAAAAADoAgAAJgAAACAgAAAAAAAAqAgAAA4DAAAoAAAAIAAAAEAAAAABAAQAAAAA
AIACAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAgAAAgAAAAICAAIAAAACAAIAAgIAAAMDAwACAgIAA
AAD/AAD/AAAA//8A/wAAAP8A/wD//wAA////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAIgAd3AAiIAAAAAAAAAAAAgHgIcACAiAAAAAAAAAAAAI
CIiAAAAIAAAAAAAAAAAAAAiIAAAAAAAAAAAAAAAAAIgHiAAAAAAAAAAAAAAAAACIB3cACAAAAAAA
AAAAAAAACIB3gAAAAAgAAAAAAAAAAAAIgIiAAAAAAAAAAAAAAAAAAAAAiAiAgAAAAAAAAAAAAAAA
AAeIiAAAAAAAAAAAAAAIgIAAiAiAAAAAAAAAAAAAAIdwAACAAAAAAAAAAAAAgAAABwAAAAAAAAAA
AAAAAAAICHcAAAAAAAAAAAAAAAAACAB3cHAACIgAAAAAAAAIAAiId3gIAAgHAAAAAAAAAAiAB3d4
AIAABwAAAAAAAId3d3eIiAAAAAgAAAAAh3eHd3dwAAiAAACAAAAACAh3d3d3AAAHeAAAAAAAAAAA
iAh3dwCIAAgIeAAAAAAACIiHAHAAh3gAgHAAAAAAAAgACIAACAeIgICAAAAAAAAAAAAAAACIcAiA
AAAAAAAAAAAAAAAAAAAIiAAAAAAAAAAAAAAAAIAACIAAAAAAAAAAAAAAAAAIgIAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/////////////////wAAf/8AAH//AAB//wAAf/8A
AH//AAB//wAAP/8AAD//AAA//4AAH/+AAB//wAAf/8AAH//gAB//4AAP/4AAD/gAAA/4AAAP8AAA
H+AAAD/wAAA/+AAAP/iAAH//+AD///4A////Af///4f///////////8oAAAAIAAAAEAAAAABAAgA
AAAAAIAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAgAAAAICAAIAAAACAAIAAgIAAAMDAwADA
3MAA8MqmANTw/wCx4v8AjtT/AGvG/wBIuP8AJar/AACq/wAAktwAAHq5AABilgAASnMAADJQANTj
/wCxx/8Ajqv/AGuP/wBIc/8AJVf/AABV/wAASdwAAD25AAAxlgAAJXMAABlQANTU/wCxsf8Ajo7/
AGtr/wBISP8AJSX/AAAA/gAAANwAAAC5AAAAlgAAAHMAAABQAOPU/wDHsf8Aq47/AI9r/wBzSP8A
VyX/AFUA/wBJANwAPQC5ADEAlgAlAHMAGQBQAPDU/wDisf8A1I7/AMZr/wC4SP8AqiX/AKoA/wCS
ANwAegC5AGIAlgBKAHMAMgBQAP/U/wD/sf8A/47/AP9r/wD/SP8A/yX/AP4A/gDcANwAuQC5AJYA
lgBzAHMAUABQAP/U8AD/seIA/47UAP9rxgD/SLgA/yWqAP8AqgDcAJIAuQB6AJYAYgBzAEoAUAAy
AP/U4wD/sccA/46rAP9rjwD/SHMA/yVXAP8AVQDcAEkAuQA9AJYAMQBzACUAUAAZAP/U1AD/sbEA
/46OAP9rawD/SEgA/yUlAP4AAADcAAAAuQAAAJYAAABzAAAAUAAAAP/j1AD/x7EA/6uOAP+PawD/
c0gA/1clAP9VAADcSQAAuT0AAJYxAABzJQAAUBkAAP/w1AD/4rEA/9SOAP/GawD/uEgA/6olAP+q
AADckgAAuXoAAJZiAABzSgAAUDIAAP//1AD//7EA//+OAP//awD//0gA//8lAP7+AADc3AAAubkA
AJaWAABzcwAAUFAAAPD/1ADi/7EA1P+OAMb/awC4/0gAqv8lAKr/AACS3AAAerkAAGKWAABKcwAA
MlAAAOP/1ADH/7EAq/+OAI//awBz/0gAV/8lAFX/AABJ3AAAPbkAADGWAAAlcwAAGVAAANT/1ACx
/7EAjv+OAGv/awBI/0gAJf8lAAD+AAAA3AAAALkAAACWAAAAcwAAAFAAANT/4wCx/8cAjv+rAGv/
jwBI/3MAJf9XAAD/VQAA3EkAALk9AACWMQAAcyUAAFAZANT/8ACx/+IAjv/UAGv/xgBI/7gAJf+q
AAD/qgAA3JIAALl6AACWYgAAc0oAAFAyANT//wCx//8Ajv//AGv//wBI//8AJf//AAD+/gAA3NwA
ALm5AACWlgAAc3MAAFBQAPLy8gDm5uYA2traAM7OzgDCwsIAtra2AKqqqgCenp4AkpKSAIaGhgB6
enoAbm5uAGJiYgBWVlYASkpKAD4+PgAyMjIAJiYmABoaGgAODg4A8Pv/AKSgoACAgIAAAAD/AAD/
AAAA//8A/wAAAP8A/wD//wAA////AOnp6enp6enp6enp6enp6enp6enp6enp6enp6enp6enr5+T/
//////8AAAAA6+sAAAcHBwAAAOvr6///////5Ovn5P///////wAAAOsAB+sA6wcAAADrAOvr////
///k6+fk////////AAAA6wDr6+vrAAAAAAAA6wD//////+Tr5+T///////8AAAAAAOvr6wAAAAAA
AAAAAP//////5Ovn5P///////wAA6+sAB+vrAAAAAAAAAAAA///////k6+fk////////AADr6wAH
BwcAAADrAAAAAAD//////+Tr5+T///////8AAADr6wAHB+sAAAAAAAAAAOv/////5Ovn5P//////
/wAAAAAA6+sA6+vrAAAAAAAAAP/////k6+fk////////AAAAAAAAAAAAAOvrAOvrAOsA/////+Tr
5+T/////////AAAAAAAAAAAAAAfr6+vrAAAA////5Ovn5P////////8AAAAA6+sA6wAAAOvrAOvr
AAD////k6+fk//////////8AAAAA6wcHAAAAAADrAAAAAP///+Tr5+T//////////+sAAAAAAAAH
AAAAAAAAAAAA////5Ovn5P///////////wAA6wDrBwcAAAAAAAAAAAD////k6+fk////////////
AADrAAAHBwcABwAAAADr6+v//+Tr5+T/////////6wAAAOvr6wcHB+sA6wAAAOsAB///5Ovn5P//
/wAAAAAAAOvrAAAHBwcH6wAA6wAAAAAH///k6+fk////AAAA6wcHBwcHBwfr6+vrAAAAAAAAAOv/
/+Tr5+T//+sHBwfrBwcHBwcHAAAAAOvrAAAAAADr////5Ovn5P/rAOsHBwcHBwcHBwAAAAAABwfr
AAAAAP/////k6+fk//8AAOvrAOsHBwcHAADr6wAAAOsA6wfr/////+Tr5+T////r6+vrBwAABwAA
AOsHB+sAAOsABwD/////5Ovn5P///+sAAP/r6wAAAADrAAfr6+sA6wDr///////k6+fk////////
//////8AAADr6wcAAOvrAP///////+Tr5+T/////////////////AAAAAAAA6+vr////////5Ovn
5P//////////////////6wAAAADr6//////////k6+fn5+fn5+fn5+fn5+fn5+fn6+sA6+fn5+fn
5+fn5wfr5wcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHBwcHB+vnZxFnZ2dnZ2dnZ2dnZ2dnZ2dn
Z2dnZ2dn6+vr6+tn6+dnDmdnZ2dnZ2dnZ2dnZ2dnZ2dnZ2dnZ2cH6gfqB2fr5+vr6+vr6+vr6+vr
6+vr6+vr6+vr6+vr6+vr6+vr6+sAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==
) );
}

package Test::NotifyIcon;
our (@ISA, $x);

BEGIN {
	@ISA = qw(Win32::GUI::NotifyIcon);
	$x = 0;
}

sub DESTROY
{
	++$x;
	shift->SUPER::DESTROY();
}
