#?perl -w
use strict;

use Win32::GUI;
use Win32::GUI::BitmapInline ();
use Win32::Registry qw(HKEY_LOCAL_MACHINE);

my $VERSION = "0.22";

my $DEBUG = 0;

my %items;
my %InfoCache;

my $PmxWindow_left;
my $PmxWindow_top;
my $PmxWindow_width;
my $PmxWindow_height;
my $PmxViewExDump;
my $PmxViewScripts;
my $PmxSaveSettings;

my $BMP_UNKFOLDER;
my $BMP_FOLDER;
my $BMP_MODULE;
my $BMP_DLL;

InitBitmaps();
print "BMP_UNKFOLDER = $BMP_UNKFOLDER ($!)\n";

ReadConfig();

my $Menu = Win32::GUI::MakeMenu(
    "&File"                       => "File",
    "   > &Properties"            => "FileProps",
    "   > &View POD"              => "FilePod",
    "   > &Dump"                  => "FileDump",
    "   > -"                      => 0,
    "   > E&xit"                  => "FileExit",
    "&View"                       => "View",
    "   > &Scripts (PL)"          => { -name => "ViewPL", -checked => $PmxViewScripts },
    "   > E&xtended Dump"         => { -name => "ViewExtendedDump", -checked => $PmxViewExDump },
    "   > -"                      => 0,
    "   > &Refresh"               => "ViewRefresh",
    "   > Perl &Version"          => "ViewPerlVersion",
    "&Settings"                   => "Settings",
    "   > &Save settings on exit" => { -name => "SettingsSave", -checked => $PmxSaveSettings },
    "   > &Reset settings"        => "SettingsReset",
    "&?"                          => "Help",
    "   > &About PMX"             => "HelpAbout",
);

my $PopMenu = Win32::GUI::MakeMenu(
    "POP with POD"         => "POPUP_POD",
    "   >&Properties"      => {-name => "PopProps1", -default => 1},
    "   >&View POD"        => "PopPod",
    "   >&Dump"            => "PopDump1",
    "POP without POD"      => "POPUP_NOPOD",
    "   >&Properties"      => {-name => "PopProps2", -default => 1},
    "   >&Dump"            => "PopDump2",
    "POP for DLLs"         => "POPUP_DLL",
    "   >&Properties"      => {-name => "PopProps3", -default => 1},
);

my $Window = new Win32::GUI::Window(
    -name   => "Window",
    -text   => "PMX version ".$VERSION,
    -height => $PmxWindow_height,
    -width  => $PmxWindow_width,
    -left   => $PmxWindow_left,
    -top    => $PmxWindow_top,
    -menu   => $Menu,
);

my $Icon = new Win32::GUI::Icon("camel.ico");

$Window->SetIcon($Icon);

my $IL = new Win32::GUI::ImageList(16, 16, 24, 4, 10);
my $IL_UNKFOLDER = $IL->Add($BMP_UNKFOLDER);
my $IL_FOLDER    = $IL->Add($BMP_FOLDER);
my $IL_MODULE    = $IL->Add($BMP_MODULE);
my $IL_DLL       = $IL->Add($BMP_DLL);
my $result = $IL->BackColor(hex("00FF00"));

$Window->AddStatusBar(
    -name => "Status",
);

$Window->AddTabStrip(
    -name    => "Dirs",
    -left    => 0,
    -top     => 0,
    -width   => $Window->ScaleWidth,
    -height  => $Window->ScaleHeight - $Window->Status->Height,
    -visible => 1,
);

my $I;
my %dirs;
my @Tabs;
foreach $I (0..$#INC) {
    if(!exists($dirs{lc($INC[$I])})) {
        $Window->Dirs->InsertItem(-text => lc($INC[$I]));
        $dirs{lc($INC[$I])} = 1;
        push(@Tabs, $INC[$I]);
    }
}

$Window->AddTreeView(
    -name      => "Tree",
    -text      => "hello world!",
    -left      => 0+$Window->Dirs->Left,
    -top       => 20+$Window->Dirs->Top,
    -width     => $Window->Dirs->ScaleWidth,
    -height    => $Window->Dirs->ScaleHeight,
    -lines     => 1,
    -rootlines => 1,
    -buttons   => 1,
    -visible   => 1,
    -imagelist => $IL,
);

my $ModuleWindow = new Win32::GUI::DialogBox(
    -title   => "Module Properties",
    -left    => 110,
    -top     => 110,
    -width   => 400,
    -height  => 400,
    -name    => "ModuleWindow",
    -style   => WS_BORDER
              | DS_MODALFRAME
              | WS_POPUP
              | WS_CAPTION
              | WS_SYSMENU,
    -exstyle => WS_EX_DLGMODALFRAME
              | WS_EX_WINDOWEDGE
              | WS_EX_CONTEXTHELP
              | WS_EX_CONTROLPARENT,
);


$ModuleWindow->AddTabStrip(
    -left    => 5,
    -top     => 5,
    -name    => "ModuleTabs",
    -tabstop => 1,
    -width   => $ModuleWindow->ScaleWidth-10,
    -height  => $ModuleWindow->ScaleHeight-45,
);
$ModuleWindow->ModuleTabs->InsertItem(-text => "General");
$ModuleWindow->ModuleTabs->InsertItem(-text => "Dump");

my($cx, $cy) = $ModuleWindow->GetTextExtentPoint32("I'm a placeholder");

my $lblleft   = 15;
my $fldleft   = 80;
my $fldwidth  = $ModuleWindow->ScaleWidth-$fldleft-20;
my $top       = 40;
my $interline = $cy*1.5;

$ModuleWindow->ModuleTabs->AddLabel(
    -name => "ModuleNameLbl",
    -text => "Name:",
    -left => $lblleft,
    -top  => $top,
);
$ModuleWindow->ModuleTabs->AddLabel(
    -text  => "I'm a placeholder",
    -left  => $fldleft,
    -top   => $top,
    -width => $fldwidth,
    -name  => "ModuleName",
);

$top += $interline;

$ModuleWindow->ModuleTabs->AddLabel(
    -name => "ModuleVersionLbl",
    -text => "Version:",
    -left => $lblleft,
    -top  => $top,
);
$ModuleWindow->ModuleTabs->AddLabel(
    -name  => "ModuleVersion",
    -text  => "I'm a placeholder",
    -left  => $fldleft,
    -top   => $top,
    -width => $fldwidth,
);

$top += $interline;

$ModuleWindow->ModuleTabs->AddLabel(
    -name  => "ModuleTypeLbl",
    -text => "Type:",
    -left => $lblleft,
    -top  => $top,
);
$ModuleWindow->ModuleTabs->AddLabel(
    -name  => "ModuleType",
    -text  => "I'm a placeholder",
    -left  => $fldleft,
    -top   => $top,
    -width => $fldwidth,
);

$top += $interline;

$ModuleWindow->ModuleTabs->AddLabel(
    -name  => "ModuleFileLbl",
    -text => "Filename:",
    -left => $lblleft,
    -top  => $top,
);
$ModuleWindow->ModuleTabs->AddLabel(
    -name  => "ModuleFile",
    -text  => "I'm a placeholder",
    -left  => $fldleft,
    -top   => $top,
    -width => $fldwidth,
);

$top += $interline;

$ModuleWindow->ModuleTabs->AddLabel(
    -name  => "ModuleSizeLbl",
    -text => "File size:",
    -left => $lblleft,
    -top  => $top,
);
$ModuleWindow->ModuleTabs->AddLabel(
    -name  => "ModuleSize",
    -text  => "I'm a placeholder",
    -left  => $fldleft,
    -top   => $top,
    -width => $fldwidth,
);

$top += $interline*1.5;

$ModuleWindow->ModuleTabs->AddLabel(
    -name  => "ModuleCtimeLbl",
    -text => "Creation\r\ntime:",
    -left => $lblleft,
    -top  => $top-$cy,
    -height => 30,
);
$ModuleWindow->ModuleTabs->AddLabel(
    -name  => "ModuleCtime",
    -text  => "I'm a placeholder",
    -left  => $fldleft,
    -top   => $top,
    -width => $fldwidth,
);

$top += $interline*1.5;

$ModuleWindow->ModuleTabs->AddLabel(
    -name  => "ModuleMtimeLbl",
    -text => "Modification\r\ntime:",
    -left => $lblleft,
    -top  => $top-$cy,
    -height => 30,
);
$ModuleWindow->ModuleTabs->AddLabel(
    -name  => "ModuleMtime",
    -text  => "I'm a placeholder",
    -left  => $fldleft,
    -top   => $top,
    -width => $fldwidth,
);

no strict 'subs';

$ModuleWindow->ModuleTabs->AddTextfield(
	-name      => "ModuleDump",
	-multiline => 1,
	-vscroll   => 1,
	-hscroll   => 1,
    -top       => 40,
    -left      => 5,
    -width     => $ModuleWindow->ModuleTabs->ScaleWidth-10,
    -height    => $ModuleWindow->ModuleTabs->ScaleHeight-50,
    -tabstop   => 1,
    -visible   => 0,
);

print $ModuleWindow->ModuleTabs->ModuleDump, "\n";

use strict 'subs';

$ModuleWindow->ModuleTabs->AddButton(
    -name    => "ModuleViewPod",
    -text    => "View POD",
    -left    => $ModuleWindow->ScaleWidth-110,
    -top     => 300,
    -width   => 80,
    -tabstop => 1,
);

$ModuleWindow->AddButton(
    -name    => "ModuleWindowClose",
    -text    => "Close",
    -left    => $ModuleWindow->ScaleWidth-90,
    -top     => 345,
    -width   => 80,
    -tabstop => 1,
    -menu    => 2,
    -cancel  => 1,
    -default => 1,
);

my $AboutWindow = new Win32::GUI::DialogBox(
    -name    => "AboutWindow",
    -title   => "About PMX...",
    -left    => 110,
    -top     => 110,
    -width   => 200,
    -height  => 150,
    -style   => DS_MODALFRAME
              | WS_CAPTION
              | WS_POPUP,
    -exstyle => WS_EX_DLGMODALFRAME
              | WS_EX_CONTROLPARENT,
);

$AboutWindow->AddLabel(
    -name => "AboutIcon",
    -top => 5,
    -left => 5,
    -height => 32,
    -width => 32,
    -style => 3,
    -visible => 1,
);
# 368 == STM_SETICON
$AboutWindow->{AboutIcon}->SendMessage(368, $Icon->{-handle}, 0);

my $AboutTitleFont = new Win32::GUI::Font(-name => "Times New Roman", -height => 16, -bold => 1);

$AboutWindow->AddLabel(
    -name => "AboutTitle",
    -top => 13,
    -left => 42,
    -height => 32,
    -width => $AboutWindow->ScaleWidth-47,
    -text => "PMX Version $VERSION",
    -font => $AboutTitleFont,
);

$AboutWindow->AddLabel(
    -name => "AboutDetails",
    -top => 42,
    -left => 5,
    -height => $AboutWindow->ScaleHeight-62,
    -width => $AboutWindow->ScaleWidth-10,
    -text => "Author: Aldo Calpini\r\nContact: dada\@divinf.it\r\nDate: 17 May 1998\r\n\r\n",
);

$AboutWindow->AddButton(
    -name => "AboutOK",
    -left => 0,
    -top => 0,
    -text => "    OK    ",
    -visible => 1,
    -default => 1,
    -ok => 1,
);
$AboutWindow->AboutOK->Move(
    $AboutWindow->ScaleWidth - $AboutWindow->AboutOK->Width,
    $AboutWindow->ScaleHeight - $AboutWindow->AboutOK->Height,
);

AddModules($INC[0], 0);

$Window->Show;
$Window->Show; # twice to avoid being preset by a 'start minimized' shortcut

my $retcode = Win32::GUI::Dialog();

print "exiting with return code $retcode\n" if $DEBUG;

#==================
sub Window_Resize {
#==================
    $Window->Dirs->Resize($Window->ScaleWidth, $Window->ScaleHeight - $Window->Status->Height);
    $Window->Tree->Move(0, 22);
    $Window->Tree->Resize($Window->Dirs->ScaleWidth, $Window->Dirs->ScaleHeight-22);
#    $Window->Status->Move(0, $Window->ScaleHeight - $Window->Status->Height);
#    $Window->Status->Resize($Window->ScaleWidth, $Window->Status->Height);
    return 1;
}

#=====================
sub Window_Terminate {
#=====================
    if($Menu->{SettingsSave}->Checked()) {
        my $key;
        $main::HKEY_LOCAL_MACHINE->Open("SOFTWARE\\dada", $key)
        or $main::HKEY_LOCAL_MACHINE->Create("SOFTWARE\\dada", $key);
        $key->Close();
        undef $key;
        $main::HKEY_LOCAL_MACHINE->Open("SOFTWARE\\dada\\PMX", $key)
        or $main::HKEY_LOCAL_MACHINE->Create("SOFTWARE\\dada\\PMX", $key);
        if($key) {
            $PmxWindow_left = $Window->Left;
            $PmxWindow_top = $Window->Top;
            $PmxWindow_width = $Window->Width;
            $PmxWindow_height = $Window->Height;
            $PmxViewExDump = $Menu->{ViewExtendedDump}->Checked();
            $PmxViewScripts = $Menu->{ViewPL}->Checked();

            WriteConfig($key);
            $key->Close();
        }
    }
    return -1;
}

#====================
sub Window_Activate {
#====================
    $Window->Tree->SetFocus();
    return 0;
}

#===============
sub Dirs_Click {
#===============
    my $dir = $Window->Dirs->SelectedItem;
    if(defined($dir)) {
        $Window->Tree->Clear;
        AddModules($Tabs[$dir], 0);
    }
}

#=================
sub Tree_KeyDown {
#=================
    my($key) = @_;
    #          Enter         Numpad +       Normal +
    if($key == 13 or $key == 107 or $key == 187) {
        my %itemdata = $Window->Tree->GetItem($Window->Tree->SelectedItem);
        if($itemdata{-image} == $IL_UNKFOLDER) {
            ExpandDir($Window->Tree->SelectedItem);
            $Window->Tree->Expand($Window->Tree->SelectedItem);
            return 0;
        } else {
            Tree_DblClick() if $key == 13; # Enter
            return 0;
        }
    }
    return 1;
}

#===================
sub Tree_NodeClick {
#===================
    my %itemdata = $Window->Tree->GetItem($Window->Tree->SelectedItem);
    if($itemdata{-image} == $IL_MODULE) {
        GetInfo($Window->Tree->SelectedItem);
        $Menu->{'FileProps'}->Enabled(1);
        $Menu->{'FileDump'}->Enabled(1);
    } elsif($itemdata{-image} == $IL_DLL) {
        $Menu->{'FileProps'}->Enabled(1);
        $Menu->{'FilePod'}->Enabled(0);
        $Menu->{'FileDump'}->Enabled(0);
    } else {
        $Window->Status->Text("");
        $Menu->{'FileProps'}->Enabled(0);
        $Menu->{'FilePod'}->Enabled(0);
        $Menu->{'FileDump'}->Enabled(0);
    }
    return 0;
}

#==================
sub Tree_DblClick {
#==================
    my %itemdata = $Window->Tree->GetItem($Window->Tree->SelectedItem);
    if($itemdata{-image} == $IL_UNKFOLDER) {
        ExpandDir($Window->Tree->SelectedItem);
    } elsif($itemdata{-image} == $IL_MODULE
         or $itemdata{-image} == $IL_DLL) {
        FileProps_Click();
    }
    return 0;
}

#====================
sub Tree_RightClick {
#====================
    my($X, $Y) = Win32::GUI::GetCursorPos();
	print "Tree_RightClick: screen ($X, $Y)\n";
	print "Tree_RightClick: window (", 
		$Window->Left, 
		", ", 
		$Window->Top, 
		")\n";
	print "Tree_RightClick: tree (", 
		$Window->Tree->Left, 
		", ", 
		$Window->Tree->Top , 
		")\n";
	print "Tree_RightClick: client (", 
		$X - ($Window->Left + $Window->Dirs->Left   + $Window->Tree->Left),
		", ", 
		$Y - ($Window->Top  + $Window->Dirs->Height + $Window->Tree->Top ),
		")\n";
    my($TVI, $flags) = $Window->Tree->HitTest(
        $X - ($Window->Left + $Window->Dirs->Left   + $Window->Tree->Left),
        $Y - ($Window->Top  + $Window->Dirs->Height + $Window->Tree->Top ),
    );
    if($TVI) {
        $Window->Tree->Select($TVI);
        my %itemdata = $Window->Tree->GetItem($TVI);
        print "Selected Item: $itemdata{-text}\n" if $DEBUG;
        if($itemdata{-image} == $IL_MODULE) {
            if($ModuleWindow->ModuleTabs->ModuleViewPod->IsEnabled()) {
                $Window->TrackPopupMenu($PopMenu->{POPUP_POD}, $X, $Y);
            } else {
                $Window->TrackPopupMenu($PopMenu->{POPUP_NOPOD}, $X, $Y);
            }
        } elsif($itemdata{-image} == $IL_DLL) {
            $Window->TrackPopupMenu($PopMenu->{POPUP_DLL}, $X, $Y);
        }
    }
    return 1;
}

#============
sub GetInfo {
#============
    my($item) = @_;
    my %itemdata = $Window->Tree->GetItem($item);
    my $name = GetFullPath($item);
    my $pname = GetPerlPath($item);
    $name .= ".pm" unless $name =~ /\.(pl|pm|dll)$/i;
    if(!exists($InfoCache{$name})) {
        $InfoCache{$name} = {};
        if($itemdata{-image} == $IL_MODULE) {
            $InfoCache{$name}->{version} = $pname;
            if(-f $name) {
                print "GetInfo: opening $name...\n" if $DEBUG;
                open(PM, "<$name");
                while(<PM>) {
                    if(/\$version\s*=\s*['"]?([^'";]*)['"]?;/i) {
                        $InfoCache{$name}->{version} .= " Version: $1";
                    }
                    if(/^=head/) {
                        $InfoCache{$name}->{haspod} = 1;
                    }
                }
                close(PM);
            }
        } elsif($itemdata{-image} == $IL_DLL) {
            $InfoCache{$name}->{version} = "";
            $InfoCache{$name}->{haspod} = 0;
        }
    }
    $Window->Status->{-text} = $InfoCache{$name}->{version};
    if($InfoCache{$name}->{haspod} == 1) {
        $ModuleWindow->ModuleTabs->ModuleViewPod->Enable();
        $Menu->{'FilePod'}->Enabled(1);
    } else {
        $ModuleWindow->ModuleTabs->ModuleViewPod->Disable();
        $Menu->{'FilePod'}->Enabled(0);
    }
}

#==============
sub ExpandDir {
#==============
    my($node) = @_;
    if($node) {
        my $name = "";
        my $n = 0;
        $name = GetFullPath($node);
        if(-d $name) {
            $Window->Tree->Clear($node);
            $Window->Tree->ChangeItem($node, -image => $IL_FOLDER);
            AddModules($name, $node);
        }
    }
    return 1;
}

#================
sub GetPerlPath {
#================
    my($node) = @_;
    my $name = "";
    my $n = $node;
    my $delim;
    while($items{$Window->Tree->GetParent($n)}) {
        $delim = ($name =~ /^::/) ? "" : "::";
        $delim = "" if $name eq "";
        $name = $items{$Window->Tree->GetParent($n)} . $delim . $name;
        $n = $Window->Tree->GetParent($n) if $Window->Tree->GetParent($n);
    }
    $delim = ($name =~ /::$/) ? "" : "::";
    $delim = "" if $name eq "";
    $name .= $delim . $items{$node};
    return $name;
}

#================
sub GetFullPath {
#================
    my($node) = @_;
    my $name = "";
    my $n = $node;
    my $delim;
    while($items{$Window->Tree->GetParent($n)}) {
        $delim = ($name =~ /^\//) ? "" : "/";
        $name = $items{$Window->Tree->GetParent($n)} . $delim . $name;
        $n = $Window->Tree->GetParent($n) if $Window->Tree->GetParent($n);
    }
    $delim = ($name =~ /\/$/) ? "" : "/";
    $name .= $delim . $items{$node};
    $name = $Tabs[$Window->Dirs->SelectedItem]."/".$name;
    $name =~ s/[\\\/]+/\\/g;
    return $name;
}

#===============
sub AddModules {
#===============
    my($dir, $parent) = @_;
    my $TVI;
    my $image;
    opendir(LIB, $dir) or print "Can't open dir $dir!\n";
    my @files = readdir(LIB);
    closedir(LIB);
    my $file;
    my $ModulesToAdd = "p[ml]";
    $ModulesToAdd = "pm" if $Menu->{ViewPL}->Checked() == 0;

    # print "found $#files files.\n";
    my $dirs = 0;
    my $files = 0;
    foreach $file (sort CaseInsensitive @files) {
        next if $file =~ /^(.|..)$/;
        if(-d $dir."/".$file) {
            $TVI = $Window->Tree->InsertItem(
                -parent => $parent,
                -text => $file,
                -image => $IL_UNKFOLDER,
            );
            $items{$TVI} = $file;
            # $Window->Tree->Select($TVI);
            # ExpandDir($TVI);
            $dirs++;
        } else {
            # print "FILE = $file\n";
            next unless ($file =~ /\.$ModulesToAdd$/i or $file =~ /\.[pd]ll$/i);
            $files++;
            $image = $IL_MODULE;
            $image = $IL_DLL if $file =~ /\.[pd]ll$/i;
            $file =~ s/\.pm$//i;
            $TVI = $Window->Tree->InsertItem(
                -parent => $parent,
                -text   => $file,
                -image  => $image,
            );
            # print "ITEMS($TVI) = $file\n";
            $items{$TVI} = $file;
        }
    }
    $Window->Status->Text(
        "Found $files file"
        .(($files==1)? "":"s")." and $dirs director"
        .(($dirs==1)? "y":"ies")
    );
}

#=================
sub ViewPL_Click {
#=================
    $Menu->{ViewPL}->Checked(!$Menu->{ViewPL}->Checked());
}

#===========================
sub ViewExtendedDump_Click {
#===========================
    $Menu->{ViewExtendedDump}->Checked(!$Menu->{ViewExtendedDump}->Checked());
}

#======================
sub ViewRefresh_Click {
#======================
    %InfoCache = ();
    Dirs_Click();
}

#=======================
sub SettingsSave_Click {
#=======================
    $Menu->{SettingsSave}->Checked(!$Menu->{SettingsSave}->Checked());
    $PmxSaveSettings = $Menu->{SettingsSave}->Checked();
    my $key;
    $main::HKEY_LOCAL_MACHINE->Open("SOFTWARE\\dada", $key)
    or $main::HKEY_LOCAL_MACHINE->Create("SOFTWARE\\dada", $key);
    $key->Close() if $key;
    undef $key;
    $main::HKEY_LOCAL_MACHINE->Open("SOFTWARE\\dada\\PMX", $key)
    or $main::HKEY_LOCAL_MACHINE->Create("SOFTWARE\\dada\\PMX", $key);
    if($key) {
        $key->SetValueEx("SaveSettings", 0, 1, $PmxSaveSettings);
        $key->Close();
    }
    return 1;
}

#========================
sub SettingsReset_Click {
#========================
    my $key;
    $main::HKEY_LOCAL_MACHINE->Open("SOFTWARE\\dada", $key)
    or $main::HKEY_LOCAL_MACHINE->Create("SOFTWARE\\dada", $key);
    $key->Close();
    undef $key;
    $main::HKEY_LOCAL_MACHINE->Open("SOFTWARE\\dada\\PMX", $key)
    or $main::HKEY_LOCAL_MACHINE->Create("SOFTWARE\\dada\\PMX", $key);
    if($key) {
        undef $PmxWindow_left;
        undef $PmxWindow_top;
        undef $PmxWindow_width;
        undef $PmxWindow_height;
        undef $PmxViewExDump;
        undef $PmxViewScripts;
        WriteConfig($key);
        $key->Close();
    }
    $Window->Move($PmxWindow_left, $PmxWindow_top);
    $Window->Resize($PmxWindow_width, $PmxWindow_height);
    $Menu->{ViewPL}->Checked($PmxViewScripts);
    $Menu->{ViewExtendedDump}->Checked($PmxViewExDump);
}


#===================
sub FileExit_Click {
#===================
    Window_Terminate();
}


#==========================
sub ViewPerlVersion_Click {
#==========================
    Win32::GUI::MessageBox(0, "This is perl, version $]", "Perl Version", 64);
}

#====================
sub CaseInsensitive { uc($b) cmp uc($a); }
#====================

#====================
sub FileProps_Click {
#====================
    GetProps();
    $ModuleWindow->ModuleTabs->Select(0);
    ModuleTabs_Click();
    $ModuleWindow->Show();
    $ModuleWindow->SetForegroundWindow();
    $Window->Disable();
}
sub PopProps1_Click { FileProps_Click(); }
sub PopProps2_Click { FileProps_Click(); }
sub PopProps3_Click { FileProps_Click(); }

#===================
sub FileDump_Click {
#===================
    GetProps();
    # DoModuleDump();
    $ModuleWindow->ModuleTabs->Select(1);
    ModuleTabs_Click();
    $ModuleWindow->Show();
    $Window->Disable();
}
sub PopDump1_Click { FileDump_Click(); }
sub PopDump2_Click { FileDump_Click(); }

#=============
sub GetProps {
#=============
    my $node = $Window->Tree->SelectedItem;
    my $name = GetFullPath($node);
    my %nodedata = $Window->Tree->GetItem($node);
    my $pname = GetPerlPath($node);
    if($nodedata{-image} == $IL_MODULE) {

        $name .= ".pm" unless $name =~ /\.p[lm]$/i;
        $ModuleWindow->Text($pname." Properties");
        $ModuleWindow->ModuleTabs->ModuleName->Text($pname);
        my $mversion;
        if(-f $name) {
            open(PM, "<$name");
            while(<PM>) {
                if(/\$version\s*=\s*['"]?([^'";]*)['"]?;/i) {
                    #$mversion = eval($1);
                    $mversion = $1;
                    seek(PM, 0, 2);
                }
            }
            close(PM);
        }
        if($mversion) {
            $ModuleWindow->ModuleTabs->ModuleVersion->Text($mversion);
        } else {
            $ModuleWindow->ModuleTabs->ModuleVersion->Text("");
        }
        if($name =~ /\.pm$/i) {
            $ModuleWindow->ModuleTabs->ModuleType->Text("Module");
        } else {
            $ModuleWindow->ModuleTabs->ModuleType->Text("Script");
        }
    } elsif($nodedata{-image} == $IL_DLL) {
        $ModuleWindow->ModuleTabs->ModuleName->Text($nodedata{-text});
        $ModuleWindow->ModuleTabs->ModuleVersion->Text("");
        $ModuleWindow->ModuleTabs->ModuleType->Text("Loadable object");
    }
    $ModuleWindow->ModuleTabs->ModuleFile->Text($name);
    my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
        $atime,$mtime,$ctime,$blksize,$blocks)           = stat($name);
    $ModuleWindow->ModuleTabs->ModuleSize->Text($size);
    $ModuleWindow->ModuleTabs->ModuleCtime->Text(scalar(localtime($ctime)));
    $ModuleWindow->ModuleTabs->ModuleMtime->Text(scalar(localtime($mtime)));
}

#========================
sub ModuleViewPod_Click {
#========================
    my $node = $Window->Tree->SelectedItem;
    my $name = GetFullPath($node);
    $name .= ".pm" unless $name =~ /\.p[lm]$/i;
    if($ModuleWindow->IsVisible()) {
        $ModuleWindow->Disable();
    } else {
        $Window->Disable();
    }
    system("$^X podview.pl $name");
    # my $pid;
    # Win32::Spawn("$^X", "podview.pl $name", $pid);
    if($ModuleWindow->IsVisible()) {
        $ModuleWindow->Enable();
        $ModuleWindow->SetForegroundWindow();
    } else {
        $Window->Enable();
        $Window->SetForegroundWindow();
    }
    return 1;
}
sub PopPod_Click { ModuleViewPod_Click(); }
sub FilePod_Click { ModuleViewPod_Click(); }

#============================
sub ModuleWindowClose_Click {
#============================
    $Window->Enable();
    $Window->SetForegroundWindow();
    Window_Activate();
    $ModuleWindow->Hide();
    return 1;
}
sub ModuleWindow_Terminate { ModuleWindowClose_Click(); }

#=====================
sub ModuleTabs_Click {
#=====================
    my $control;
    print "Got ModuleTabs_Click (", $ModuleWindow->ModuleTabs->SelectedItem, ")\n" if $DEBUG;
    my @controls = (
        $ModuleWindow->ModuleTabs->ModuleNameLbl,
        $ModuleWindow->ModuleTabs->ModuleName,
        $ModuleWindow->ModuleTabs->ModuleVersionLbl,
        $ModuleWindow->ModuleTabs->ModuleVersion,
        $ModuleWindow->ModuleTabs->ModuleTypeLbl,
        $ModuleWindow->ModuleTabs->ModuleType,
        $ModuleWindow->ModuleTabs->ModuleFileLbl,
        $ModuleWindow->ModuleTabs->ModuleFile,
        $ModuleWindow->ModuleTabs->ModuleCtimeLbl,
        $ModuleWindow->ModuleTabs->ModuleCtimeLbl,
        $ModuleWindow->ModuleTabs->ModuleMtimeLbl,
        $ModuleWindow->ModuleTabs->ModuleMtimeLbl,
        $ModuleWindow->ModuleTabs->ModuleViewPod,
    );
    if($ModuleWindow->ModuleTabs->SelectedItem == 0) {
        foreach $control (@controls) {
            $control->Show();
        }
        $ModuleWindow->ModuleTabs->ModuleDump->Hide();
    } else {
        foreach $control (@controls) {
            $control->Hide();
        }
        DoModuleDump();
        $ModuleWindow->ModuleTabs->ModuleDump->Show();
    }
}

#====================
sub HelpAbout_Click {
#====================
    $AboutWindow->Show();
    $Window->Disable();
}

#==================
sub AboutOK_Click {
#==================
    $Window->Enable();
    $Window->SetForegroundWindow();
    Window_Activate();
    $AboutWindow->Hide();
    return 1;
}

#==========================
sub AboutWindow_Terminate {
#==========================
    AboutOK_Click();
    return 0;
}

#=================
sub DoModuleDump {
#=================
    no strict 'refs';
    my $name = $ModuleWindow->ModuleTabs->ModuleName->Text();
    print "useing $name..." if $DEBUG;
    my $use = eval("use $name;");
    print "used\n" if $DEBUG;
    if(!$@) {
        my $output = DumpNames(\%{$name.'::'}, $name.'::', $name.'::');
        #my $expr = "use $name; DumpNames(\%".$name."::, '".$name."::', '".$name."::');";
        $ModuleWindow->ModuleTabs->ModuleDump->Text($output);
    } else {
        Win32::GUI::MessageBox(0, $@, "Error using $name", 16);
        $ModuleWindow->ModuleTabs->ModuleDump->Text("");
    }
    return 1;
}

# this code was originally taken
# from a PerlScript sample by ActiveState
#====================
sub DumpNames(\%$$) {
#====================
    no strict 'refs';
    my ($package,$packname,$pname) =  @_;
    my $symname = 0;
    my $value = 0;
    my $key = 0;
    my $i = 0;
    $pname =~ s/main::(.+)/$1/;
    my @found = ();
    my $sym;
    my %sym;
    my @sym;
    my %flags;
    my $spname;

    print "DumpNames called for $packname ($pname) = $package\n" if $DEBUG;

    my $ret = "";

    @found = ();
    foreach $symname (sort keys %$package) {
        push(@found, $symname) if defined %{$pname.$symname} and $symname =~ /::$/;
    }
    if($#found > -1) {
        $ret .= "$pname Packages\r\n";
        foreach $symname (@found) {
            next if $symname eq 'main::';
            $ret .= "\t$symname\r\n";
        }
    }

    if ($packname ne 'main::') {

        @found = ();
        foreach $symname (sort keys %$package) {
            push(@found, $symname) if defined &{$pname.$symname};
        }
        if($#found > -1) {
            $ret .= "$pname Functions\r\n";
            foreach $symname (@found) {
                $ret .= "\t$symname()\r\n";
            }
        }

        @found = ();
        foreach $symname (sort keys %$package) {
            push(@found, $symname) if defined ${$pname.$symname};
        }
        if($#found > -1) {
            $ret .= "$pname Scalars\r\n";
            foreach $symname (@found) {
                $ret .= "\t\$$symname = ".${$pname.$symname}."\r\n";

            }
        }

        @found = ();
        foreach $symname (sort keys %$package) {
            push(@found, $symname) if defined @{$pname.$symname};
        }
        if($#found > -1) {
            $ret .= "$pname Lists\r\n";
            foreach $symname (@found) {
                if($Menu->{ViewExtendedDump}->Checked) {
                    $ret .= "\t\@$symname = (\r\n";
                    foreach (sort @{$$package{$symname}}) {
                        $ret .= "\t\t$_\r\n";
                    }
                    $ret .= "\t);\r\n";
                } else {
                    $ret .= "\t\@$symname\r\n";
                }

            }
        }

        @found = ();
        foreach $symname (sort keys %$package) {
            push(@found, $symname) if defined %{$pname.$symname} and $symname !~ /::$/;
        }
        if($#found > -1) {
            $ret .= "$pname Hashes\r\n";
            foreach $symname (@found) {
                if($Menu->{ViewExtendedDump}->Checked) {
                    $ret .= "\t\%$symname = (\r\n";
                    foreach (sort keys %{$$package{$symname}}) {
                        $ret .= "\t\t$_ => ${$$package{$symname}}{$_}\r\n";
                    }
                    $ret .= "\t);\r\n";
                } else {
                    $ret .= "\t\%$symname\r\n";
                }
            }
        }
    }
    $ret .= "\r\n";

    # if ($packname ne 'main::') {
    #    return;
    # }

    foreach $symname (sort keys %$package) {
        if (defined %{$pname.$symname} and $symname =~ /::$/ and $symname ne 'main::') {
            $spname = $packname . $symname;
            next if $spname =~ /PMX::/ and $flags{'self'} == 0;
            print "Dumping $symname ($spname)...\n" if $DEBUG;
            $ret .= DumpNames(\%{$spname}, $spname, $spname);
        }
    }
    return $ret;
}

#===============
sub ReadConfig {
#===============
    my $key;
    my $val;
    my $name;
    $main::HKEY_LOCAL_MACHINE->Open("SOFTWARE\\dada", $key)
    or $main::HKEY_LOCAL_MACHINE->Create("SOFTWARE\\dada", $key);
    $key->Close();
    undef $key;
    $main::HKEY_LOCAL_MACHINE->Open("SOFTWARE\\dada\\PMX", $key)
    or $main::HKEY_LOCAL_MACHINE->Create("SOFTWARE\\dada\\PMX", $key);
    if($key) {
        $key->GetValues($val);

        #foreach $name (keys %$val) {
        #    print "\t$name = $val->{$name}[2]\n";
        #}

        $PmxWindow_left   = $val->{'left'}[2];
        $PmxWindow_top    = $val->{'top'}[2];
        $PmxWindow_width  = $val->{'width'}[2];
        $PmxWindow_height = $val->{'height'}[2];

        $PmxViewExDump    = $val->{'ViewExDump'}[2];
        $PmxViewScripts   = $val->{'ViewScripts'}[2];

        $PmxSaveSettings  = $val->{'SaveSettings'}[2];

        WriteConfig($key);
        $key->Close();
    } else {
        WriteConfig();
    }
}

#================
sub WriteConfig {
#================
    my($key) = @_;

    # put default values where needed
    $PmxWindow_left = 100 unless defined($PmxWindow_left);
    $PmxWindow_top = 100 unless defined($PmxWindow_top);
    $PmxWindow_width = 400 unless defined($PmxWindow_width);
    $PmxWindow_height = 300 unless defined($PmxWindow_height);
    $PmxViewExDump = 0 unless defined($PmxViewExDump);
    $PmxViewScripts = 0 unless defined($PmxViewScripts);
    $PmxSaveSettings = 1 unless defined($PmxSaveSettings);

    # write in the registry (note: 1 is REG_SZ)
    if($key) {
        $key->SetValueEx("left", 0, 1, $PmxWindow_left);
        $key->SetValueEx("top", 0, 1, $PmxWindow_top);
        $key->SetValueEx("width", 0, 1, $PmxWindow_width);
        $key->SetValueEx("height", 0, 1, $PmxWindow_height);
        $key->SetValueEx("ViewExDump", 0, 1, $PmxViewExDump);
        $key->SetValueEx("ViewScripts", 0, 1, $PmxViewScripts);
        $key->SetValueEx("SaveSettings", 0, 1, $PmxSaveSettings);
    }
}

sub InitBitmaps {

$BMP_UNKFOLDER = new Win32::GUI::BitmapInline( q(
Qk32AAAAAAAAAHYAAAAoAAAAEAAAABAAAAABAAQAAAAAAIAAAAAAAAAAAAAAABAAAAAQAAAAAAAA
AACcnABjzs4A9/f3AJzO/wCc//8Azv//AP///wD///8A////AP///wD///8A////AP///wD///8A
////AHd3d3d3d3d3d3d3d3d3d3dwAAAAAAAABxIiIiIiIiIHFkVFAEVEQgcWVVQAVFRCBxZVVVVF
RUIHFlVVAFRUUgcWVVUAVUVCBxZVVVAEVFIHFlUAVQBVQgcWZgBmAGZSBxIiIAABERF3cTZlUQd3
d3d3EREQd3d3d3d3d3d3d3d3
) );
$BMP_FOLDER = new Win32::GUI::BitmapInline( q(
Qk32AAAAAAAAAHYAAAAoAAAAEAAAABAAAAABAAQAAAAAAIAAAAAAAAAAAAAAABAAAAAQAAAAAAAA
AACcnABjzs4A9/f3AJzO/wCc//8Azv//AP///wD///8A////AP///wD///8A////AP///wD///8A
////AHd3d3d3d3d3d3d3d3d3d3dwAAAAAAAABxIiIiIiIiIHFkVFRUVEQgcWVVRUVFRCBxZVVVVF
RUIHFlVVVFRUUgcWVVVVVUVCBxZVVVVUVFIHFlVVVVVVQgcWZmZmZmZSBxIiIiIRERF3cTZlUQd3
d3d3EREQd3d3d3d3d3d3d3d3
) );
$BMP_MODULE = new Win32::GUI::BitmapInline( q(
Qk32AAAAAAAAAHYAAAAoAAAAEAAAABAAAAABAAQAAAAAAIAAAAAAAAAAAAAAABAAAAAQAAAAAAAA
AAAAgAAAgAAAAICAAIAAAACAAIAAgIAAAICAgADAwMAAAAD/AAD/AAAA//8A/wAAAP8A/wD//wAA
////AP//////////////////////AAAAAAAP//8P/////w///w//D/D/D///D/8P8P8P//8P+AAA
jw///w/wAAAPD///D/AAAP8P//8P8IgP/w///w8A////D///D4D/8AAP//8P///w8P///w////AP
////AAAAAP//////////////
) );
$BMP_DLL = new Win32::GUI::BitmapInline( q(
Qk32AAAAAAAAAHYAAAAoAAAAEAAAABAAAAABAAQAAAAAAIAAAAAAAAAAAAAAABAAAAAQAAAAAAAA
AAAAgAAAgAAAAICAAIAAAACAAIAAgIAAAMDAwACAgIAAAAD/AAD/AAAA//8A/wAAAP8A/wD//wAA
////APAAAAAAAAD/+Hd3d3d3cP/4//////9w//j//////3D/+P//8A//cP/4//8HcP9w//j/+PCI
D3D/+P8HD4D/cP/487CID/9w//j/CzD//3D/+P8zD///cP/4//////9w//j/////AAD/+P////9/
j//4/////3j///iIiIiIj///
) );

}
