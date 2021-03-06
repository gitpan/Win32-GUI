#!perl -w
use strict;
use warnings;
use ExtUtils::MakeMaker;

# $Id: GridRC.PL,v 1.1 2006/06/11 16:42:10 robertemay Exp $
# perl script to produce the RC file for
# Win32::GUI::Grid  create Resource
# file with a VERSIONINFO section

# The variables:
my %info = (
    Version => MM->parse_version('Grid.pm'),
    Dllname => 'Grid.dll',
    Years   => '2003..2006',
    Win32GUIVersion => MM->parse_version('../GUI.pm'),
);

# Open the target file
if ( @ARGV > 0 ) {
    my $file = $ARGV[0];
    open(my $fh, '>', $file) or die qq(Failed to open '$file': $!);
    select $fh;
}

{
    my $fileVersion = $info{Version};
    $fileVersion .= "_00" unless $fileVersion =~ m/_/;
    $info{FileVersion} =
        sprintf("%02d,%02d,%02d,00", $fileVersion =~ m/^(.*)\.([^_]*)_?(.*)$/);
    my $prodVersion = $info{Win32GUIVersion};
    $prodVersion .= "_00" unless $prodVersion =~ m/_/;
    $info{ProductVersion} =
        sprintf("%02d,%02d,%02d,00", $prodVersion =~ m/^(.*)\.([^_]*)_?(.*)$/);
}

print <<"__RC";
#include "Winver.h"

1 VERSIONINFO
FILEVERSION    $info{FileVersion}
PRODUCTVERSION $info{ProductVersion}
FILEOS         VOS__WINDOWS32
FILETYPE       VFT_DLL
{
  BLOCK "StringFileInfo"
  {
    BLOCK "040904E4"
    {
      VALUE "Comments"         , "Win32::GUI::Grid, part of the perl Win32::GUI module. Includes code by Chris Maunder from MFCGrid: http://www.codeproject.com/miscctrl/gridctrl.asp"
      VALUE "CompanyName"      , "perl-win32-gui.sourceforge.net"
      VALUE "FileDescription"  , "Win32::GUI::Grid perl extension"
      VALUE "FileVersion"      , "$info{Version}"
      VALUE "InternalName"     , "$info{Dllname}"
      VALUE "LegalCopyright"   , "Copyright � Laurent Rocher $info{Years}"
      VALUE "LegalTrademarks"  , "GNU and Artistic licences"
      VALUE "OriginalFilename" , "$info{Dllname}"
      VALUE "ProductName"      , "Win32::GUI perl extension"
      VALUE "ProductVersion"   , "$info{Win32GUIVersion}"
    }
  }

  BLOCK "VarFileInfo"
  {
    VALUE "Translation", 0x0409, 0x04E4
  }
}
__RC

exit(0);
__END__
