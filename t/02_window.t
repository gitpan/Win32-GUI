#!perl -wT
# Win32::GUI test suite.
# $Id: 02_window.t,v 1.3 2006/05/16 18:57:26 robertemay Exp $
#
# Win32::GUI::Window tests:
# - check that we can create and manipulate Windows

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 16;

use Win32::GUI();

# check that the methods we want to use are available
can_ok('Win32::GUI::Window', qw(new Left Top Width Height Move Resize Text) );

my $W = new Win32::GUI::Window(
    -name => "TestWindow",
    -pos  => [  0,   0],
    -size => [210, 200],
    -text => "TestWindow",
);

isa_ok($W, "Win32::GUI::Window");

is($W->Left,0, "Window LEFT correct");
is($W->Top, 0, "Window TOP correct");
is($W->Width,210, "Window WIDTH correct");
is($W->Height, 200, "Window HEIGHT correct");
is($W->Text, "TestWindow", "Window TITLE correct");

$W->Left(100);
is($W->Left, 100, "Change window LEFT");

$W->Top(100);
is($W->Top, 100, "Change window TOP");

$W->Width(310);
is($W->Width, 310, "Change window WIDTH");

$W->Height(300);
is($W->Height, 300, "Change window HEIGHT");

$W->Move(0, 0);
is($W->Left, 0, "Move window, LEFT");
is($W->Top, 0, "Move winodw TOP");

$W->Resize(210, 200);
is($W->Width, 210, "Resize winodw WIDTH");
is($W->Height, 200, "Resize winodw HEIGHT");

$W->Text("TestChanged");
is($W->Text ,"TestChanged", "Change winodw TITLE");

