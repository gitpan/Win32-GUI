#!perl -wT
# Win32::GUI::Scintilla test suite
# $Id: 02_new.t,v 1.1 2006/06/11 16:51:50 robertemay Exp $
#
# - check we can create a new Scintilla object

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 2;
use Win32::GUI();
use Win32::GUI::Scintilla();

can_ok('Win32::GUI::Scintilla', 'new');
my $W = Win32::GUI::Window->new();
my $S = $W->AddScintilla();
isa_ok($S, 'Win32::GUI::Scintilla', 'Correct object type created');
