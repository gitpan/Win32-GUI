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
    if($Config{'cc'} =~ /^cl(\.exe)?/i) {

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

@subpackages = qw(
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
    TabStrip
    Textfield
    Toolbar
    Tooltip
    Trackbar
    TreeView
    StatusBar
    UpDown
    Window
);

@c_files = qw(
    GUI
    GUI_Constants
    GUI_Helpers
    GUI_Options
    GUI_MessageLoops
    GUI_Events
);

$c_ext = ($^O eq "cygwin") ? "c" : "cpp";

@arg_c = ();
$arg_object = "";

foreach (@c_files) {
    push( @arg_c, $_ . '.' . $c_ext );
    $arg_object .= ' ' . $_ . $Config{'obj_ext'};
}

%arg_xs = ( 'GUI.xs' => 'GUI.' . $c_ext );
@arg_dl_funcs = ( 'boot_Win32__GUI' );
foreach (@subpackages) {
    $arg_xs{$_.'.xs'} = $_ . '.' . $c_ext;
    push( @arg_c, $_ . '.' . $c_ext );
    push( @arg_dl_funcs, 'boot_Win32__GUI__' . $_ );
    $arg_object .= ' ' . $_ . $Config{'obj_ext'};
}


%MakefileArgs = (
    'NAME'         => 'Win32::GUI',
    'VERSION_FROM' => 'GUI.pm',
    'LIBS'         => ( ($^O eq "cygwin") ? '-lcomctl32' : 'comctl32.lib' ),
    'PM' => {
        'GUI.pm'            => '$(INST_LIBDIR)/GUI.pm',
        'BitmapInline.pm'   => '$(INST_LIBDIR)/GUI/BitmapInline.pm',
        'GridLayout.pm'     => '$(INST_LIBDIR)/GUI/GridLayout.pm',
    },
    'XS' => { %arg_xs },
    'C'  => [ @arg_c ],
    'OBJECT' => $arg_object,
    'DL_FUNCS' => { 'Win32::GUI' => [ @arg_dl_funcs ] },

    ($^O eq "cygwin") ? ( 'DEFINE' => '-UWIN32' ) : (), 

    'dist'  => {
        ZIP => 'zip',
        ZIPFLAGS => '-r9',
    },
    ($] < 5.005 ? () : (
        'AUTHOR'        => 'Aldo Calpini <dada@perl.it>',
        'ABSTRACT'      => 'Perl-Win32 Graphical User Interface Extension',
    )),

);


$MakefileArgs{'LDFROM'} = '$(OBJECT) GUI.res' if $USERESOURCE;

WriteMakefile( %MakefileArgs );

# tweak the generated Makefile to include resource

package MY;

sub xs_c {
($^O eq 'cygwin') ? 
    shift->SUPER::xs_c(@_)
:
    '
.xs.cpp:
    $(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs >$*.cpp
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
        $inherited .= "\nGUI.res:\n\trc.exe /l 0x409 /fo\"GUI.res\" GUI.rc\n\n";
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
