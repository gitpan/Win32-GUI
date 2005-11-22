#!perl -wT
# Win32::GUI test suite.
# $Id: 01_basic.t,v 1.3 2005/11/21 22:33:34 robertemay Exp $
#
# Basic tests:
# - check module loads
# - check module has a $VERSION

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

# Perform tests

# Bail out if we havent got Test::More
eval "use Test::More";
if($@) {
	# As we haven't got Test::More, can't use diag()
	print "#\n# Test::More required to perform any Win32::GUI test\n";
	chomp $@;
	$@ =~ s/^/# /gm;
	print "$@\n";
	print "Bail Out! Test::More not available\n";
	exit(1);
}

plan( tests => 3 );

# Check that we're on windows or cygwin
# bail out if we're not
if ( not ($^O =~ /MSwin32|cygwin/i)) {
	diag("\nWin32::GUI can only run on MSWin32 or cygwin, not '$^O'");
	print "Bail out! Incompatible Operating System\n";
}
pass("Correct OS");
	
# Check that Win32::GUI loads, and bail out of all
# tests if it doesn't
use_ok('Win32::GUI') or print STDOUT "Bail out! Can't load Win32::GUI";

ok(defined $Win32::GUI::VERSION, "Win32::GUI version check");

