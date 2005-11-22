use strict;
use warnings;

use File::Spec();
use ExtUtils::MakeMaker;
use Config;

$main::USERESOURCE = 1;
$main::BUILDENV = '';
$main::BUILDENV_SETONCMDLINE = 0;

# parse our command line options, removing them from @ARGV so that
# MakeMaker doesn't warn that they are unrecoginised.
my @tmp;
foreach (@ARGV) {
  if(/USERESOURCE=0/) {
    $main::USERESOURCE = -1;
  }
  elsif(/USERESOURCE=1/) {
    $main::USERESOURCE = 1;
  }
  elsif(/BUILDENV=(.*)/) {
    $main::BUILDENV = $1;
    $main::BUILDENV_SETONCMDLINE = 1;
  }
  else {
    push @tmp, $_;
  }
}
@ARGV=@tmp;

# determine the build environment, and report it.  We support 3 variants:
# (1) MSWin32 and Visual C++  BUILDENV=vc
# (2) MSWin32 and MinGW       BUILDENV=mingw
# (3) Cygwin (and gcc)        BUILDENV=cygwin

my %allowed = (
  vc     => 'MSWin32 and Visual C++',
  mingw  => 'MSWin32 and MinGW',
  cygwin => 'Cygwin',
);

if (not $main::BUILDENV) {
  if ($^O eq "cygwin") {
    $main::BUILDENV = 'cygwin';
  }
  elsif ($^O eq "MSWin32") {
    if($Config{'cc'} =~ /^cl(\.exe)?/i) {
      $main::BUILDENV = 'vc';
    }
    elsif($Config{'cc'} =~ /^gcc(\.exe)?/i) {
      $main::BUILDENV = 'mingw';
    }
  }
}

if (not $main::BUILDENV) {
  print STDERR <<__NOBUILDENV;

Building on OS $^O with compiler $Config{'cc'} is not officially supported.
To force a build call this script with the additional parameter 'BUILDENV':

  perl Makefile.PL BUILDENV=xxxx

where xxxx is one of:
__NOBUILDENV

  print "$_\t($allowed{$_})\n" for (keys %allowed);

  exit(1);
}

if ( not exists $allowed{$main::BUILDENV} ) {
  print STDERR <<__BADBUILDENV;

Unrecognised build environment BUILDENV=$main::BUILDENV

Allowed values are:
__BADBUILDENV

	print "$_\t($allowed{$_})\n" for (keys %allowed);

  exit(1);
}

print "\n\nBUILDENV=$main::BUILDENV  Used build environment is: $allowed{$main::BUILDENV}\n\n";

# If we got this far, then we have a buildenv and compiler that
# we want to try to use.  Check that we can find the compiler,
# and exit with a nice error message if we can't.  This stops
# us from failing CPAN Smoke tests on boxes that don't have
# compilers.
if($main::BUILDENV_SETONCMDLINE == 0) {
  my @path = File::Spec->path();
  unshift @path, ('', '.');

  my $found = 0;
  foreach my $prog ( map { ( $_, "$_.exe" ) } ($Config{cc}) ) {
    foreach my $path ( @path ) {
      if( -f File::Spec->catfile( $path, $prog ) ) {
        $found=1, last;
      }
    }
  }

  if(!$found) {
    print STDERR <<__NOCOMPILER;

Makefile.PL was unable to find compiler '$Config{cc}' on your path.
To force a build call this script with the additional parameter 'BUILDENV':

  perl Makefile.PL BUILDENV=xxxx

where xxxx is one of:
__NOCOMPILER

    print "$_\t($allowed{$_})\n" for (keys %allowed);


    exit(1);
  }
}

if($main::USERESOURCE == -1) {
    $main::USERESOURCE = 0;
} else {
  print <<____EXPLAIN;

NOTE: Makefile.PL will add the instruction to use the Resource Compiler to 
your Makefile; if you don't want to compile resources with your extension,
call this script with this additional argument:

    perl Makefile.PL USERESOURCE=0

____EXPLAIN

  $main::USERESOURCE = 1;
}

my @subpackages = qw(
    Animation
    Bitmap
    Button
    Combobox
    DateTime
    DC
    Font
    Header
    ImageList
    Label
    Listbox
    ListView
    MDI
    MonthCal
    NotifyIcon
    ProgressBar
    Rebar
    RichEdit
    Splitter
    StatusBar
    TabStrip
    Textfield
    Toolbar
    Tooltip
    Trackbar
    TreeView
    UpDown
    Window
);

my @c_files = qw(
    GUI
    GUI_Constants
    GUI_Events
    GUI_Helpers
    GUI_Options
    GUI_MessageLoops
);

my $c_ext = "cpp";

my @arg_c = ();
my $arg_object = "";

foreach (@c_files) {
    push( @arg_c, $_ . '.' . $c_ext );
    $arg_object .= ' ' . $_ . $Config{'obj_ext'};
}

my %arg_xs = ( 'GUI.xs' => 'GUI.' . $c_ext );
my @arg_dl_funcs = ( 'boot_Win32__GUI' );
foreach (@subpackages) {
    $arg_xs{$_.'.xs'} = $_ . '.' . $c_ext;
    push( @arg_c, $_ . '.' . $c_ext );
    push( @arg_dl_funcs, 'boot_Win32__GUI__' . $_ );
    $arg_object .= ' ' . $_ . $Config{'obj_ext'};
}

$arg_object .= ' GUI.res' if $main::USERESOURCE;

my %MakefileArgs = (
    NAME            => 'Win32::GUI',
    VERSION_FROM    => 'GUI.pm',
    LIBS            => [':nosearch -lcomctl32 -lcomdlg32 -lshell32 -lgdi32 -luser32'],
    PREREQ_PM       => {
                         'Test::More' => 0,
                       },
    PM              => {
                         'GUI.pm'          => '$(INST_LIBDIR)/GUI.pm',
                         'BitmapInline.pm' => '$(INST_LIBDIR)/GUI/BitmapInline.pm',
                         'GridLayout.pm'   => '$(INST_LIBDIR)/GUI/GridLayout.pm',
                      },
    XS              => { %arg_xs },
    C               => [ @arg_c ],
    OBJECT          => $arg_object,
    DL_FUNCS        => { 'Win32::GUI' => [ @arg_dl_funcs ] },
    dist            => {
                         ZIP => 'zip',
                         ZIPFLAGS => '-r9',
                         DIST_DEFAULT => 'zipdist',
                       },
  ($] < 5.005 ? () : (
    AUTHOR          => 'Aldo Calpini <dada@perl.it>',
    ABSTRACT        => 'Perl-Win32 Graphical User Interface Extension',
  )),
    BINARY_LOCATION => 'Win32-GUI.tar.gz',
    macro           => {
                         BUILD_TOOLS  => './build_tools',
                         INST_DEMO    => '$(INST_LIBDIR)/GUI/demos',
                         PPMDISTVNAME => '$(DISTVNAME)-PPM-' . substr($Config{version},0,3),
                       },
    clean           => {
                         FILES => 'comctrl32.def cygwin.o libcyg.a GUI.res',
                       },
    realclean       => {
                         FILES => '$(PPMDISTVNAME) Readme.old Readme.html.old',
                       },
    depend          => {
                         distdir => 'readmedocs',
                       },
);

if ($main::BUILDENV eq "cygwin") {
  $MakefileArgs{'LIBS'} = ['-L/usr/lib/w32api -lcomctl32 -lcomdlg32 -lshell32 -lgdi32 -luser32'];
  $MakefileArgs{'DEFINE'} = '-UWIN32';
  $MakefileArgs{'MYEXTLIB'} = './libcyg.a';
}

WriteMakefile( %MakefileArgs );

# tweak the generated Makefile

package MY;

use strict;
use warnings;

sub xs_c {
  my $inherited = shift->SUPER::xs_c(@_);
  $inherited =~ s/\.c/.cpp/g;
  return $inherited;
}

sub xs_o {
  my $inherited = shift->SUPER::xs_o(@_);
  $inherited =~ s/\.c$/.cpp/mg;
  return $inherited;
}

# Remove the Test-More dependency from the PPD file, as it is not
# a requirement for a binary distribution
sub ppd {
  my $inherited = shift->SUPER::ppd(@_);
  #perl 5.6
  $inherited =~ s/qq\{\\t\\t<DEPENDENCY NAME=.*Test-More.*?\}\.//s;
  #perl 5.8
  $inherited =~ s/^.*DEPENDENCY.*Test-More.*$//m;
  return $inherited;
}

# In the following here-doc fragments, ensure that command lines are indented with TAB
# and not space for gnu-make compatibility (cygwin)
sub postamble {

  my $cygwin_frag = '';

  # cygwin w32api comctl32 before 2004-12-02 misses some stubs
  if ($main::BUILDENV eq "cygwin") {
    my $missing = '';
    my $defs = `nm -g /usr/lib/w32api/libcomctl32.a`;
    for (qw(ImageList_Duplicate@4 ImageList_DrawIndirect@4 ImageList_Copy@20)) {
      unless ($defs =~ / _$_/) {
        $missing .= "\t" . '$(NOECHO)$(ECHO) "' . $_ . '" >$@' . "\n";
      }
    }
    if($missing) {
      $cygwin_frag = sprintf <<'CYGWIN_FRAG1', $missing;

# -- Win32::GUI Cygwin section --

comctl32.def: 
	$(NOECHO)$(ECHO) "LIBRARY COMCTL32.DLL" >$@
	$(NOECHO)$(ECHO) "EXPORTS" >$@
%s

libcyg.a: comctl32.def cygwin.o
	dlltool -k --output-lib libcyg.a --def comctl32.def
	ar r libcyg.a cygwin.o

CYGWIN_FRAG1

    } else {
      $cygwin_frag = <<'CYGWIN_FRAG2';

# -- Win32::GUI Cygwin section --

libcyg.a: cygwin.o
	ar r libcyg.a cygwin.o

CYGWIN_FRAG2

    }
  }

	my $rc_frag = '';

  if($main::USERESOURCE) {
    if ($main::BUILDENV eq 'vc') {  # Visual C++
      $rc_frag = <<'RC_FRAG1';

# -- Win32::GUI resource section --

GUI.res: GUI.rc
	rc.exe /l 0x409 /fo"GUI.res" GUI.rc

RC_FRAG1
	
    } else {                        # cygwin and MinGW
      $rc_frag = <<'RC_FRAG2';

# -- Win32::GUI resource section --

GUI.res: GUI.rc
	windres -O coff -i GUI.rc -o GUI.res

RC_FRAG2

    }
    $rc_frag .= <<'RC_FRAG3'

GUI.rc: GUI.pm
	$(PERL) -I$(BUILD_TOOLS) $(BUILD_TOOLS)/updateRC.pl

RC_FRAG3

	}

  my $doc_frag = <<'DOC_FRAG';

# -- Win32::GUI documents section --

readmedocs:
	$(NOECHO) $(PERL) -I$(BUILD_TOOLS) $(BUILD_TOOLS)/doReadme.pl

poddocs:
	$(NOECHO) $(PERL) -I$(BUILD_TOOLS) $(BUILD_TOOLS)/doPodDocs.pl

htmldocs: poddocs
	$(NOECHO) $(PERL) -I$(BUILD_TOOLS) $(BUILD_TOOLS)/doHTMLDocs.pl

all:: poddocs demos

DOC_FRAG

  my $ppm_frag = '';

  if ($main::BUILDENV eq "vc" || $main::BUILDENV eq "mingw") {

    $ppm_frag = <<'PPM_FRAG';

# -- Win32::GUI ppm section --

demos:
	$(MKPATH) $(INST_DEMO)
	$(CP) samples/* $(INST_DEMO)

ppmdist: all htmldocs
	$(TAR) --exclude="*.pod" -$(TARFLAGS) $(DISTNAME).tar blib
	$(COMPRESS) $(DISTNAME).tar

ppm: readmedocs ppd ppmdist
	$(RM_RF) $(PPMDISTVNAME)
	$(MKPATH) $(PPMDISTVNAME)
	$(CP) Readme $(PPMDISTVNAME)/Readme.txt
	$(CP) Readme.html $(PPMDISTVNAME)/Readme.html
	$(CP) CHANGELOG $(PPMDISTVNAME)/Changelog.txt
	$(MV) $(DISTNAME).tar.gz $(PPMDISTVNAME)
	$(MV) $(DISTNAME).ppd $(PPMDISTVNAME)
	$(RM_F) $(PPMDISTVNAME).zip
	$(ZIP) $(ZIPFLAGS) $(PPMDISTVNAME).zip $(PPMDISTVNAME)
	$(RM_RF) $(PPMDISTVNAME)

PPM_FRAG

  }

  return $cygwin_frag . $rc_frag . $doc_frag . $ppm_frag;
}
