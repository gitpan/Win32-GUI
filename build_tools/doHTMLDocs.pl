#!perl

# This file is part of the build tools for Win32::GUI
# It expects to be run in the same directory as the make
# command is run from, and performs the following functions:
# (1) converts all POD documentation in the blib/lib directory, and puts
#     it in the blib/html/site/lib directory
# (2) Copies any GIF files from the document source to the relavent location
#     in the blib/html tree

# it is typically invoked as
#  make htmldocs
# or automatically as part of the distribution build
# process
#
# Author: Robert May , rmay@popeslane.clara.co.uk
# $Id: doHTMLDocs.pl,v 1.2 2005/06/30 22:36:22 robertemay Exp $

use strict;
use warnings;

use BuildTools;
use Pod::Html;
use Cwd;
my $cwd = cwd;

my $DEBUG = 0;

my $srcdir = "blib/lib";
my $destdir = "blib/html/site/lib";
my $docroot  = "blib/html";
my $imgsrcdir = "docs/";

print BuildTools::macro_subst(
    "Converting POD documentation to HTML for Win32::GUI v__W32G_VERSION__ on __W32G_DATE__\n"
    );

# recursively traverse everything inside the source directory, find .pod files
# convert to html and put in a corresponding location in the blib/html directory
BuildTools::mkpath($destdir);
doHtml($srcdir, $destdir);

# remove pod2html cache files; 5.6 uses ".x~~" and 5.8 uses ".tmp" extensions
unlink("pod2htmd.$_", "pod2htmi.$_") for qw(x~~ tmp);

# copy all GIF files from docs directy to html tree
doGIF($imgsrcdir, "$destdir/Win32");

exit(0);

sub doHtml
{
  my ($src, $dst) = @_;

  opendir(my $DH, $src) || die "Can't open directory $src: $!";
  while(my $file = readdir($DH)) {
    # process .pod files
    if($file =~ /\.pod$/ || $file =~ /GridLayout.pm$/ || $file =~ /BitmapInline.pm$/) {
      (my $htmlfile = $file) =~ s/\.(pod|pm)$/.html/;
      print STDERR "Converting $file to $dst/$htmlfile\n" if $DEBUG;

      # calculate the relative paths (cope with non-standard perl installs)
      my $path2root = "$dst/";
      $path2root =~ s|^$docroot/||;
      $path2root =~ s|\w*/|../|g;
      $path2root =~ s|/$||;

      # ensure the destination directory exists
      print STDERR "Creating directory $dst/$file\n" if $DEBUG;
      BuildTools::mkpath($dst);

      # and convert the source POD to destination HTML
      my @options = (
        "--infile=$src/$file",
        "--outfile=$dst/$htmlfile",
        "--header",
        "--css=$path2root/Active.css",
        "--htmlroot=$path2root/site/lib",
        "--podroot=$cwd/blib",
      );
      print STDERR "pod2html @options\n" if $DEBUG;
      pod2html(@options);
    }

    # recurse to directories
    elsif (-d "$src/$file") {
      # ignore '.' and '..'
      if ($file !~ /^\.{1,2}$/) {
        doHtml("$src/$file", "$dst/$file");
      }
    }

    # ignore anything else
    else {
    }
  }
  closedir($DH);

  return 1;
}

sub doGIF
{
  my ($src, $dst) = @_;

  opendir(my $DH, $src) || die "Can't open directory $src: $!";
  while(my $file = readdir($DH)) {

    # copy .gif files
    if($file =~ /\.gif$/) {

      # ensure the destination directory exists
      print STDERR "Creating directory $dst/$file\n" if $DEBUG;
      BuildTools::mkpath($dst);

      # copy the file
      print STDERR "Copying $file to $dst/$file\n" if $DEBUG;
      BuildTools::cp("$src/$file","$dst");
    }

    # recurse to directories
    elsif (-d "$src/$file") {
      # ignore '.' and '..'
      if ($file !~ /^\.{1,2}$/) {
        doGIF("$src/$file", "$dst/$file");
      }
    }

    # ignore anything else
    else {
    }
  }
  closedir($DH);

  return 1;
}
