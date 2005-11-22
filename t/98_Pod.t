#!perl -wT
# Win32::GUI test suite.
# $Id: 98_Pod.t,v 1.1 2005/11/21 22:33:34 robertemay Exp $

# Testing RichEdit::GetCharFormat()

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();
