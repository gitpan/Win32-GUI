#!perl -wT
# Win32::GUI test suite.
# $Id: 02_constants.t,v 1.1 2006/05/16 19:16:20 robertemay Exp $
#
# test coverage of constants.  Most of the coverage is provided by the
# Win32::GUI::Constants module, here we just want to check that
# delegation happens, and warnigs are raised appropriately

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More tests => 14;

use Win32::GUI();

# Check warnings from import statements
{
    my $warning;
    local $SIG{__WARN__} = sub {
        $warning = $_[0];
    };

    $warning = '';
    eval "use Win32::GUI()";
    is($warning, '', "No warning from 'use Win32::GUI()'");

    $warning = '';
    eval "use Win32::GUI";
    like($warning, '/deprecated/i', "Unadorned 'use Win32::GUI' deprecated warning");

    $warning = '';
    eval "use Win32::GUI 1.03";
    like($warning, '/deprecated/i', "Unadorned 'use Win32::GUI 1.03' deprecated warning");

    $warning = '';
    eval "use Win32::GUI 1.03,''";
    is($warning, '', "No warning from 'use Win32::GUI 1.03,'''");
}

# Check basic export mechanism
ok(!defined &main::CW_USEDEFAULT, "CW_USEDEFAULT not defined in main package");
eval "use Win32::GUI qw(CW_USEDEFAULT)";
ok(!defined &main::CW_USEDEFAULT, "CW_USEDEFAULT still not defined in main package");
is(CW_USEDEFAULT(), 0x80000000, "CW_USEDEFAULT autoloaded");
ok(defined &main::CW_USEDEFAULT, "CW_USEDEFAULT defined in main package after calling it");

# Check warnings from Win32::GUI::constants()
{
    my $warning;
    local $SIG{__WARN__} = sub {
        $warning = $_[0];
    };

    $warning = '';
    is(Win32::GUI::constant("CW_USEDEFAULT"), 0x80000000, "Win32::GUI::constant lookup OK");
    like($warning, '/deprecated/i', "Win32::GUI::constant() deprecated warning");
}

# Check warnings from autoload of Win32::GUI::SOME_CONSTANT
{
    my $warning;
    local $SIG{__WARN__} = sub {
        $warning = $_[0];
    };

    ok(!defined &Win32::GUI::CW_USEDEFAULT, "CW_USEDEFAULT not defined in Win32::GUI package");
    $warning = '';
    is(Win32::GUI::CW_USEDEFAULT(), 0x80000000, "Win32::GUI constant AUTOLOAD OK");
    like($warning, '/deprecated/i', "Win32::GUI constant AUTOLAD deprecated warning");
    ok(defined &Win32::GUI::CW_USEDEFAULT, "CW_USEDEFAULT defined in Win32::GUI package after calling it");
}

# Check warnings from autoload of Win32::GUI::SOME_CONSTANT
