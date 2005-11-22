#!perl -w

# This file is part of the build tools for Win32::GUI
# It expects to be run in the same directory as the make
# command is run from, and updates the VERSIONINFO resource
# definition

# it is typically invoked as
#  make GUI.rc
# or automatically as part of the build process

#
# Author: Robert May , rmay@popeslane.clara.co.uk
# $Id: updateRC.pl,v 1.1 2005/08/03 21:45:58 robertemay Exp $

use strict;
use warnings;

use BuildTools;

my $rcfile = "GUI.rc";

my $version = BuildTools::macro_subst('__W32G_VERSION__');
my $year    = BuildTools::macro_subst('__W32G_YEAR__');

my $changed = 0;
my $outtext = '';

# Parse $version into 4 parts:
my($maj, $min, $rc, $extra) = split(/\.|_/, $version . ".00.00.00");

print "Checking RC file ... ";

open(my $in, "<$rcfile") or die "Filaed to open $rcfile for reading: $!";
while (my $inline = <$in>) {
	my $outline = $inline;

	if($outline =~ /FILEVERSION/) {
		$outline =~ s/\d+,\d+,\d+,\d+/$maj,$min,$rc,$extra/;
	}
	elsif($outline =~ /PRODUCTVERSION/) {
		$outline =~ s/\d+,\d+,\d+,\d+/$maj,$min,$rc,$extra/;
	}
	elsif($outline =~ /VALUE.*FileVersion/) {
		$outline =~ s/"[^"]*"$/"$version"/;
	}
	elsif($outline =~ /VALUE.*ProductVersion/) {
		$outline =~ s/"[^"]*"$/"$version"/;
	}
	elsif($outline =~ /VALUE.*Comments/) {
		$outline =~ s/v.*"$/v$version"/;
	}
	elsif($outline =~ /VALUE.*LegalCopyright/) {
		$outline =~ s/\d{4}"$/$year"/;
	}

	$changed = 1 unless $inline eq $outline;
	$outtext .= $outline;
}
close($in);

# write out the new rcfile
open(my $out, ">$rcfile") or die "Failed to open $rcfile for writing";
print $out $outtext;
close($out);

print $changed ? "updated.\n" : "no change.\n";

exit(0);

