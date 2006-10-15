#!perl -w
use strict;
#use warnings;

# Makefile.PL for Win32::GUI::DIBitmap
# $Id: Makefile.PL,v 1.3 2006/06/11 21:00:15 robertemay Exp $

use 5.006;
use Config;
use ExtUtils::MakeMaker;
use File::Find();

my @demos;
File::Find::find(sub { push @demos, $File::Find::name if $File::Find::name =~ /\.(pl|zip|bmp|png|tga|jpg)$/ }, 'demos');

my %config = (
    NAME          =>  'Win32::GUI::DIBitmap',
    VERSION_FROM  =>  'DIBitmap.pm',
    ABSTRACT_FROM =>  'DIBitmap.pm',
    AUTHOR        =>  'ROCHER Laurent (lrocher@cpan.org)',
    PL_FILES      => {'DIBitmapRC.PL' => '$(BASEEXT).rc', },
    OBJECT        =>  '$(BASEEXT)$(OBJ_EXT) $(BASEEXT).res',
    LIBS          => ['-lmsvcprt'],
    MYEXTLIB      => 'extlib/FreeImage.lib',
    macro         => {RC => 'rc.exe',
                      RCFLAGS => '',
                      INST_DEMODIR => '$(INST_LIB)/Win32/GUI/demos/$(BASEEXT)',
                      DEMOS => "@demos", },
    clean         => {FILES => '*.rc *.res', },
);

# if building using gcc (MinGW or cygwin) use windres
# as the resource compiler
# and the MinGW C++ standard library
if($Config{cc} =~ /gcc/i) {
    $config{macro}->{RC}      =      'windres';
    $config{macro}->{RCFLAGS} = '-O coff -o $*.res';
    $config{LIBS}             = [':nosearch -lstdc++'];
    $config{MYEXTLIB}         = 'extlib/libFreeImage-mingw.a';
    if( $^O =~ /cygwin/i ) {
        $config{MYEXTLIB}     = 'extlib/libFreeImage-cygwin.a';
    }
}

# Can't build with gcc (yet).
if($Config{cc} =~ /gcc/i ) {
    print <<__EXPLAIN;

At this time Win32::GUI::DIBitmap cannot be build using gcc.
Win32::GUI::DIBitmap will be skipped during the current build process.

__EXPLAIN
    ExtUtils::MakeMaker::WriteEmptyMakefile(NAME => 'Win32::GUI::DIBitmap');
}
else {
    WriteMakefile(%config);
}

package MY;

sub special_targets {
    my $inherited = shift->SUPER::special_targets(@_);
    $inherited =~ s/^(.SUFFIXES.*)$/$1 .rc .res/m;
    return $inherited;
}

# Add rule for .rc to .res conversion
# Add rules to install demo scripts
sub postamble {
  return <<'__POSTAMBLE';

# Win32::GUI::DIBitmap RC section

.rc.res:
	$(RC) $(RCFLAGS) $<

# Win32::GUI::DIBitmap demo script section

pure_all :: demo_to_blib
	$(NOECHO) $(NOOP)

demo_to_blib: $(DEMOS)
	$(NOECHO) $(MKPATH) $(INST_DEMODIR)
	$(CP) $? $(INST_DEMODIR)
	$(NOECHO) $(TOUCH) demo_to_blib

clean ::
	-$(RM_F) demo_to_blib

__POSTAMBLE
}
