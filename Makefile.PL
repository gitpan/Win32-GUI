use ExtUtils::MakeMaker;
use Config;

$USERESOURCE = 0;

foreach (@ARGV) {
    if(/USERESOURCE=0/) {
        $USERESOURCE = -1;
        undef $_;
        last;
    }
}

if($USERESOURCE == -1) {
    $USERESOURCE = 0;
} else {
    if($Config{'cc'} eq "cl.exe") {

        print <<____EXPLAIN;

Using Visual C++
NOTE:Makefile.PL will add the instruction to use the Resource Compiler to 
your Makefile; if you're not using Visual C++, or don't want to compile 
resources with your extension, call this script with this additional 
argument:

    perl Makefile.PL USERESOURCE=0    

____EXPLAIN

        $USERESOURCE = 1;
    }
}

%MakefileArgs = (
    'NAME'  => 'Win32::GUI',
    'VERSION_FROM' => 'GUI.pm',
    'LIBS' => 'comctl32.lib',
    'XS'                => { 'GUI.xs' => 'GUI.cpp' },
    'PM' => {
        'GUI.pm'            => '$(INST_LIBDIR)/GUI.pm',
        'BitmapInline.pm'   => '$(INST_LIBDIR)/GUI/BitmapInline.pm',
        'GridLayout.pm'     => '$(INST_LIBDIR)/GUI/GridLayout.pm',
    },
    'dist'  => {
        ZIP => 'zip',
        ZIPFLAGS => '-r9',
    },
    ($] < 5.005 ? () :
      (
	'AUTHOR'        => 'Aldo Calpini <dada@perl.it>',
	'ABSTRACT'      => 'Perl-Win32 Graphical User Interface Extension',
      )),

);


$MakefileArgs{'LDFROM'} = '$(OBJECT) GUI.res' if $USERESOURCE;

WriteMakefile( %MakefileArgs );

# tweak the generated Makefile to include resource

package MY;

sub xs_c {
    '
.xs.cpp:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs >xstmp.c && $(MV) xstmp.c $*.cpp
';
}

sub constants {
    my $inherited = shift->SUPER::constants(@_);
    if($main::USERESOURCE) {
        $inherited =~ s/\.SUFFIXES([^\n]+)\n/\.SUFFIXES$1 .rc .res\n/;
    }
    return $inherited;
}

sub c_o {
    my $inherited = shift->SUPER::c_o(@_);
    if($main::USERESOURCE) {
        $inherited .= "\nGUI.res:\n    rc.exe /l 0x409 /fo\"GUI.res\" GUI.rc\n\n";
    }
    return $inherited;
}

sub top_targets {
    my $inherited = shift->SUPER::top_targets(@_);
    if($main::USERESOURCE) {
        $inherited =~ s/pure_all(.*) linkext/pure_all$1 GUI.res linkext/;
    }
    return $inherited;
}
