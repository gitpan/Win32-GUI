#!perl -w
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use strict;
use vars qw( $loaded $clip $actual );

######################### We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use Win32::GUI;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

my $W = new Win32::GUI::Window(
    -name => "TestWindow",
    -pos  => [  0,   0],
    -size => [100, 100],
    -text => "TestWindow",
);
print ((defined $W) ? "" : "not ");
print "ok 2\n";

my $B = $W->AddButton(
    -name => "TestButton",
    -pos  => [  0,   0],
    -text => "TestButton",
);

print ((defined $B and ref($B) =~ /Win32::GUI::Button/) ? "" : "not ");
print "ok 3\n";

print ((defined $W->{TestButton}) ? "" : "not ");
print "ok 4\n";

print ((defined $W->TestButton) ? "" : "not ");
print "ok 5\n";

print (($B->Left == 0) ? "" : "not ");
print "ok 6\n";

print (($B->Top == 0) ? "" : "not ");
print "ok 7\n";

$W->TestButton->Left(100);
print (($W->TestButton->Left == 100) ? "" : "not ");
print "ok 8\n";

$W->Top(100);
print (($W->Top == 100) ? "" : "not ");
print "ok 9\n";

$W->Move(0, 0);
print (($W->Left == 0 && $W->Top == 0) ? "" : "not ");
print "ok 10\n";

