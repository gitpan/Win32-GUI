#!perl -wT
# Win32::GUI::BitmapInline test suite.
# $Id: 99_pod_coverage.t,v 1.1 2008/01/13 11:42:57 robertemay Exp $

# Check the POD covers all method calls

use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
plan skip_all => "Pod Coverage tests for Win32::GUI::BitmapInline done by core" if $ENV{W32G_CORE};
all_pod_coverage_ok( { also_private => [ qr/^(share|lock)$/, ] } );
