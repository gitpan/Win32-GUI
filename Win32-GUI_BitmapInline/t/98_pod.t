#!perl -wT
# Win32::GUI::BitmapInline test suite.
# $Id: 98_pod.t,v 1.1 2008/01/13 11:42:57 robertemay Exp $

# Check that our pod documentation has valid syntax

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
plan skip_all => "Pod tests for Win32::GUI::BitmapInline done by core" if $ENV{W32G_CORE};
plan skip_all => 'set TEST_POD to enable this test' unless $ENV{TEST_POD};
all_pod_files_ok();
