use strict;
use Win32::GUI;
use Win32::GUI::BitmapInline;
use PPM;
use XML::Parser;
use XML::PPMConfig;

my $B_PPMREPO;
my $B_PPMREPC;
my $B_PPMREPN;
my $B_PPMREPF;
my $B_PPMREPI;
my $B_PPMREPL;
my $B_PPMREPA;
my $B_PPMREPR;
DefineBitmaps();

my $VERSION = "0.72";

my %WinPPM;
InitSettings();

my $TT = "";

my $M = new Win32::GUI::Menu(
    "&File"							=> "File",
        " > &Properties"			=> { -name => "Properties", -default => 1 },
		" > &Install"				=> "Install",
        " > &Verify"				=> "Verify",
        " > &Remove"				=> "Remove",
		" > -"						=> 0,
		" > &Search"				=> "Search",
		" > -"						=> 0,
        " > E&xit"					=> "Exit",

    "&View"							=> "View",
        " > &Repositories"			=> "ViewRepos",
        " > Insta&lled packages"	=> "ViewInstd",
		" > -"						=> 0,
		" > PPM &Info..."			=> "PPMInfo",

    "&Settings"						=> "Settings",
        " > PPM &Configuration..."	=> "PPMConfig",
		" > -"						=> 0,
        " > &Autosave config"		=> { -name => "Autosave", -checked => $WinPPM{SAVE} },

    "&Help"							=> "Help",
        " > &About WinPPM..."		=> "About",
);

my $POP = new Win32::GUI::Menu(

    ""						=> "POP_onRepository",
    " > &Open"				=> { -name => "POP_RepOpen", -default => 1 },
    " > &Properties"		=> "POP_RepProp",

    ""						=> "POP_onInstd",
    " > &Properties"		=> { -name => "POP_InstdProp", -default => 1 },
    " > &Verify"			=> "POP_InstdVerify",
    " > &Remove"			=> "POP_InstdRemove",

    ""						=> "POP_onRepoPack",
    " > &Properties"		=> { -name => "POP_Prop", -default => 1 },
    " > &Install"			=> "POP_Install",
	" > &Verify"			=> "POP_Verify",

    ""							=> "POP_onSearchResults",
    " > &Clear Search results"	=> { -name => "POP_ClearSearch", -default => 1 },

);

my $IL = new Win32::GUI::ImageList(16, 16, 24, 10, 10);
my $IL_PPMREPO = $IL->Add($B_PPMREPO);
my $IL_PPMREPC = $IL->Add($B_PPMREPC);
my $IL_PPMREPN = $IL->Add($B_PPMREPN);
my $IL_PPMREPF = $IL->Add($B_PPMREPF);
my $IL_PPMREPI = $IL->Add($B_PPMREPI);
my $IL_PPMREPL = $IL->Add($B_PPMREPL);
my $IL_PPMREPA = $IL->Add($B_PPMREPA);
my $IL_PPMREPR = $IL->Add($B_PPMREPR);

my $W = new Win32::GUI::Window(
    -name   => "W",
    -text   => "WinPPM $VERSION",
    -left   => 100,
    -top    => 100,
    -width  => 400,
    -height => 300,
    -menu   => $M,
);

my $PW = new Win32::GUI::DialogBox(
    -name   => "PW",
    -text   => "Package Properties",
    -left   => 110,
    -top    => 110,
    -width  => 300,
    -height => 400,
);

$PW->AddTextfield(
    -name     => "PPMName",
    -readonly => 1,
    -left     => 10,
    -top      => 10,
    -width    => 200,
    -height   => 22,
    -text     => "I'm a placeholder",
    -prompt   => [ "PPM Name:", 75 ],
);
$PW->AddTextfield(
    -name     => "PPMVersion",
    -readonly => 1,
    -left     => 10,
    -top      => 40,
    -width    => 200,
    -height   => 22,
    -text     => "I'm a placeholder",
    -prompt   => [ "PPM Version:", 75 ],
);
$PW->AddTextfield(
    -name     => "PPMAuthor",
    -readonly => 1,
    -left     => 10,
    -top      => 70,
    -width    => 200,
    -height   => 22,
    -text     => "I'm a placeholder",
    -prompt   => [ "Author:", 75 ],
);
$PW->AddTextfield(
    -name     => "PPMDate",
    -readonly => 1,
    -left     => 10,
    -top      => 100,
    -width    => 200,
    -height   => 22,
    -text     => "I'm a placeholder",
    -prompt   => [ "Installed:", 75 ],
);
$PW->AddTextfield(
    -name      => "PPMAbstract",
#    -readonly  => 1,
    -multiline => 1,
    -left      => 10,
    -top       => 130,
    -width     => 200,
    -height    => 80,
    -text      => "I'm a placeholder",
    -prompt    => [ "Abstract:", 75 ],
);
$PW->AddButton(
    -name     => "Close",
    -left     => 235,
    -top      => 345,
	-text     => "&Close",
    -default  => 1,
	-cancel   => 1,
    -tabstop  => 1,
);
$PW->AddButton(
    -name     => "Operate",
    -left     => 185,
    -top      => 345,
	-text     => "&Install",
    -ok       => 1,
	-cancel   => 1,
    -tabstop  => 1,
);

my $RW = new Win32::GUI::DialogBox(
    -name   => "RW",
    -text   => "Repository Properties",
    -left   => 110,
    -top    => 110,
    -width  => 300,
    -height => 130,
);
$RW->AddTextfield(
    -name      => "Name",
    -left      => 10,
    -top       => 10,
    -width     => 200,
    -height    => 22,
    -text      => "I'm a placeholder",
    -prompt    => [ "Name:", 75 ],
    -tabstop   => 1,
);
$RW->AddTextfield(
    -name      => "Location",
    -left      => 10,
    -top       => 40,
    -width     => 200,
    -height    => 22,
    -text      => "I'm a placeholder",
    -prompt    => [ "Location:", 75 ],
    -tabstop   => 1,
);
$RW->AddButton(
    -name     => "RepOK",
    -left     => 150,
    -top      => 75,
    -width    => 60,
    -text     => "&OK",
    -ok       => 1,
    -default  => 1,
    -tabstop  => 1,
);
$RW->AddButton(
    -name     => "RepClose",
    -left     => 220,
    -top      => 75,
    -width    => 60,
    -text     => "&Cancel",
    -cancel   => 1,
	-tabstop  => 1,
);
$RW->AddLabel(
    -name    => "Editing",
    -visible => 0,
);

my $CW = new Win32::GUI::DialogBox(
    -name   => "CW",
    -text   => "PPM Configuration",
    -left   => 110,
    -top    => 110,
    -width  => 300,
    -height => 220,
);
$CW->AddTextfield(
    -name      => "Root",
    -left      => 10,
    -top       => 10,
    -width     => 200,
    -height    => 22,
    -text      => "I'm a placeholder",
    -prompt    => [ "Install root:", 75 ],
    -tabstop   => 1,
);
$CW->AddTextfield(
    -name      => "Build",
    -left      => 10,
    -top       => 40,
    -width     => 200,
    -height    => 22,
    -text      => "I'm a placeholder",
    -prompt    => [ "Build dir:", 75 ],
    -tabstop   => 1,
);
$CW->AddCheckbox(
    -name      => "Case",
    -left      => 10,
    -top       => 70,
    -width     => 200,
    -height    => 22,
    -text      => "Case sensitive search",
    -tabstop   => 1,
);
$CW->AddCheckbox(
    -name      => "Clean",
    -left      => 10,
    -top       => 100,
    -width     => 200,
    -height    => 22,
    -text      => "Clean temporary after build",
    -tabstop   => 1,
);
$CW->AddCheckbox(
    -name      => "Force",
    -left      => 10,
    -top       => 130,
    -width     => 200,
    -height    => 22,
    -text      => "Force install (ignore dependencies)",
    -tabstop   => 1,
);
$CW->AddButton(
    -name     => "ConfOK",
    -left     => 150,
    -top      => $CW->Height-55,
    -width    => 60,
    -text     => "&OK",
    -ok       => 1,
    -default  => 1,
    -tabstop  => 1,
);
$CW->AddButton(
    -name     => "ConfClose",
    -left     => 220,
    -top      => $CW->Height-55,
    -width    => 60,
    -text     => "&Cancel",
    -cancel   => 1,
    -tabstop  => 1,
);

my $SW = new Win32::GUI::DialogBox(
    -name   => "PW",
    -text   => "PPM Search",
    -left   => 110,
    -top    => 110,
    -width  => 300,
    -height => 400,
);
$SW->AddTextfield(
	-name    => "What",
	-left    => 10,
	-top     => 10,
	-width   => 200,
    -height  => 22,
	-prompt  => [ "Regexp:", 75 ],
	-tabstop => 1,
);
$SW->AddLabel(
	-name    => "WhereLabel",
	-left    => 10,
	-top     => 44,
	-text    => "Search in:",
);
$SW->AddComboboxEx(
	-name      => "Where",
	-left      => 85,
	-top       => 40,
	-tabstop   => 1,
	-width     => 200,
	-height    => 200,
	-tabstop   => 1,
    -style     => WS_VISIBLE | 2,
	-imagelist => $IL,
);
$SW->AddButton(
    -name      => "GroupWhat",
    -left      => 10,
    -top       => 70,
    -width     => 275,
    -height    => 100,
    -text      => "What to search",
	-style     => BS_GROUPBOX,
	-visible   => 1,
);
$SW->AddRadioButton(
    -name      => "SearchName",
    -left      => 20,
    -top       => 90,
    -width     => 170,
    -height    => 22,
    -text      => "Package name",
    -tabstop   => 1,
);
$SW->AddRadioButton(
    -name      => "SearchAuthor",
    -left      => 20,
    -top       => 115,
    -width     => 170,
    -height    => 22,
    -text      => "Author",
    -tabstop   => 1,
);
$SW->AddRadioButton(
    -name      => "SearchAbstract",
    -left      => 20,
    -top       => 140,
    -width     => 170,
    -height    => 22,
    -text      => "Abstract",
    -tabstop   => 1,
);
$SW->AddCheckbox(
    -name      => "SearchCase",
    -left      => 10,
    -top       => 180,
    -width     => 200,
    -height    => 22,
    -text      => "Case sensitive search",
    -tabstop   => 1,
);
$SW->AddButton(
	-name    => "SearchOK",
	-text    => "&OK",
	-left    => $SW->Width-145,
	-top     => $SW->Height-55,
	-width   => 60,
	-ok      => 1,
	-tabstop => 1,
);
$SW->AddButton(
	-name    => "SearchCancel",
	-text    => "Cancel",
	-left    => $SW->Width-75,
	-top     => $SW->Height-55,
	-width   => 60,
	-cancel  => 1,
	-tabstop => 1,
);


$W->AddTreeView(
    -name      => "Tree",
    -imagelist => $IL,
    -tabstop   => 1,
	-lines     => 1,
	-rootlines => 1,
	-buttons   => 1,
);
$W->AddStatusBar(
    -name   => "Status",
);

$W->Tree->InsertItem(
    -text  => "Installed packages",
    -image => $IL_PPMREPL,
);

my %Instd = ();

my %Repos = ();

%Repos = PPM::ListOfRepositories();
foreach my $r (keys %Repos) {
    $W->Tree->InsertItem(
		-text => $r,
		-image => $IL_PPMREPF,
		-index => $W->Tree->Count,
	);
}
$W->Tree->InsertItem(
	-text => "Add new repository...",
	-image => $IL_PPMREPN,
	-index => $W->Tree->Count,
);

$W->Show();

my $exitcode = Win32::GUI::Dialog();
WriteSettings();

#================
sub W_Terminate {
#================
    return -1;
}

#=============
sub W_Resize {
#=============
    $W->Tree->Move(2, 2);
    $W->Tree->Resize($W->ScaleWidth-4, $W->ScaleHeight-2-$W->Status->Height);
    $W->Status->Move(0, $W->ScaleHeight-$W->Status->Height);
    $W->Status->Resize($W->ScaleWidth, $W->Status->Height);
    return 1;
}

#===================
sub Tree_NodeClick {
#===================
    my($node) = @_;
	my %i;
	my $v;
	my $p;
	my $pp;
    my %n = $W->Tree->GetItem($node);
    if($n{-image} == $IL_PPMREPO) {
		%i = %{$Instd{$n{-text}}};
		$PW->Operate->Text("&Remove");
		$M->{Install}->Enabled(0);
		$M->{Remove}->Enabled(1);
        $v = $i{VERSION};
        $p = $i{NAME};
        #$pp = $p;
        #$pp =~ s@-@/@g;
        #my $i;
        #foreach $i (@INC) {
        #    if(-f "$i/$pp.pm") {
        #        my $vv = ExtUtils::MM_Unix::parse_version(0, "$i/$pp.pm");
        #        $v .= " ($vv)" if $vv;
        #        $p = $pp;
        #        $p =~ s@/@::@g;
        #    }
        #}
        $W->Status->Text("$p $v");
	} elsif($n{-image} == $IL_PPMREPC) {
		my $parent = $W->Tree->GetParent($node);
		my %r = $W->Tree->GetItem($parent);
		%i = PPM::RepositoryPackageProperties(
			"package" => $n{-text},
			"location" => $Repos{$r{-text}},
		);
		$M->{Install}->Enabled(1);
		$M->{Remove}->Enabled(0);
		$PW->Operate->Text("&Install");
        my $v = $i{VERSION};
        my $p = $i{NAME};
        $W->Status->Text("$p $v");
	} elsif($n{-image} == $IL_PPMREPF) {
		$W->Status->Text($Repos{$n{-text}});
	} elsif($n{-image} eq $IL_PPMREPN) {
        $W->Status->Text("Creates a new repository");
    }
}

#==================
sub Tree_DblClick {
#==================
    my($X, $Y) = Win32::GUI::GetCursorPos();
	my $c = 0;
    my $node = $W->Tree->HitTest(
        $X - ($W->Left + $W->Tree->Left) - 2,
        $Y - ($W->Top  + $W->Tree->Top ) - 2,
    );
    $node = $W->Tree->SelectedItem();
	if($node) {
        $W->Tree->Select($node);
        my %n = $W->Tree->GetItem($node);
		if($n{-image} == $IL_PPMREPF) {
			if($W->Tree->GetNextVisible($node) == $W->Tree->GetChild($node)) {
				$W->Tree->Expand($node, 0);
			} else {
				if(not exists $WinPPM{R}{$n{-text}}) {
					$W->Tree->Clear($node);
					my %p = PPM::RepositoryPackages("location" => $Repos{$n{-text}});
					my $p;
					foreach $p (@{$p{$Repos{$n{-text}}}}) {
						$W->Tree->InsertItem(
							-text => $p,
							-index => $W->Tree->Count(),
							-image => $IL_PPMREPC,
							-parent => $node,
						);
						$c++;
					}
					$WinPPM{R}{$n{-text}} = 1;
				}
				$W->Tree->Expand($node, 1);
				$W->Status->Text("$c package" . ( ($c > 1) ? "s" : "") );
			}
			# $W->Tree->EnsureVisible($W->Tree->GetChild($node));
			# $W->Tree->Select($W->Tree->GetChild($node));
		} elsif($n{-image} == $IL_PPMREPO or $n{-image} == $IL_PPMREPC) {
			ShowProperties();
		} elsif($n{-image} == $IL_PPMREPL) {
			if($W->Tree->GetNextVisible($node) == $W->Tree->GetChild($node)) {
				$W->Tree->Expand($node, 0);
			} else {
				$W->Tree->Clear($node);
				%Instd = PPM::InstalledPackageProperties();
				foreach my $i (sort keys %Instd) {
					$W->Tree->InsertItem(
						-text => $i,
						-index => $W->Tree->Count(),
						-image => $IL_PPMREPO,
						-parent => $node,
					);
					$c++;
				}
				$W->Tree->Expand($node, 1);
				$W->Status->Text("$c package" . ( ($c > 1) ? "s" : "") );
			}
			# $W->Tree->EnsureVisible($W->Tree->GetChild($node));
			# $W->Tree->Select($W->Tree->GetChild($node));
		} elsif($n{-image} == $IL_PPMREPN) {
			my $node = $W->Tree->SelectedItem();
			my %n = $W->Tree->GetItem($node);
			$W->Disable();
			$RW->Editing->Text("");
			$RW->Name->Text("");
			$RW->Location->Text("");
			$RW->Text("Add new repository...");
			$RW->Name->SetFocus();
			$RW->Move(
				$W->Left + ($W->Width  - $RW->Width )/2,
				$W->Top  + ($W->Height - $RW->Height)/2,
			);
			$RW->Show();
		} else {
			Win32::GUI::MessageBox(0, "unknown image!");
		}
	} else {
		Win32::GUI::MessageBox(0, "nothing selected!");
	}
	return 0;
}

#====================
sub Tree_RightClick {
#====================
    my($X, $Y) = Win32::GUI::GetCursorPos();
    my $node = $W->Tree->HitTest(
        $X-$W->Tree->Left-2,
        $Y-$W->Tree->Top-2,
    );
    if($node) {
        $W->Tree->Select($node);
        my %n = $W->Tree->GetItem($node);
        if($n{-image} == $IL_PPMREPF) {
            $W->TrackPopupMenu($POP->{POP_onRepository}, $X, $Y);
        } elsif($n{-image} == $IL_PPMREPC) {
			$W->TrackPopupMenu($POP->{POP_onRepoPack}, $X, $Y);
		} elsif($n{-image} == $IL_PPMREPO) {
			$W->TrackPopupMenu($POP->{POP_onInstd}, $X, $Y);
		} elsif($n{-image} == $IL_PPMREPR) {
			$W->TrackPopupMenu($POP->{POP_onSearchResults}, $X, $Y);
		}
    }
    return 1;
}

#======================
sub POP_RepProp_Click {
#======================
    my $node = $W->Tree->SelectedItem();
    my %n = $W->Tree->GetItem($node);
    $W->Disable();
    $RW->Editing->Text($n{-text});
    $RW->Name->Text($n{-text});
    $RW->Location->Text($Repos{$n{-text}});
    $RW->Text("Repository Properties");
    $RW->Name->SetFocus();
    $RW->Move(
        $W->Left + ($W->Width  - $RW->Width )/2,
        $W->Top  + ($W->Height - $RW->Height)/2,
    );
    $RW->Show();
}

#========================
sub POP_InstdProp_Click {
#========================
	ShowProperties();
}

#=================
sub Remove_Click {
#=================
	my $node = $W->Tree->SelectedItem();
    my %n = $W->Tree->GetItem($node);
	RemovePackage($n{-text});

}
#==========================
sub POP_InstdRemove_Click {
#==========================
	Remove_Click();
}

#===================
sub POP_Prop_Click {
#===================
	ShowProperties();
}

#=====================
sub Properties_Click {
#=====================
	ShowProperties();
}

#==========================
sub POP_ClearSearch_Click {
#==========================
	my $node = $W->Tree->GetChild(0);
	my %i = $W->Tree->GetItem($node);
	my $done = 0;
	while($node and not $done) {
		if($i{-image} == $IL_PPMREPR) {
			$W->Tree->Clear($node);
			$W->Tree->DeleteItem($node);
			$done = 1;
		}
		$node = $W->Tree->GetNextSibling($node);
	}
}
#==================
sub Install_Click {
#==================
    my $node = $W->Tree->SelectedItem();
    my %n = $W->Tree->GetItem($node);
	my $parent = $W->Tree->GetParent($node);
	my %r = $W->Tree->GetItem($parent);
	InstallPackage($n{-text}, $Repos{$r{-text}});
}
#======================
sub POP_Install_Click {
#======================
	Install_Click();
}

#================
sub Close_Click {
#================
    $PW->Hide();
    $W->Enable();
    $W->SetForegroundWindow();
    $W->Tree->SetFocus();
}

#=================
sub PW_Terminate {
#=================
    Close_Click();
    return 0;
}

#================
sub RepOK_Click {
#================
    my %r = (
        "repository" => $RW->Name->Text(),
        "location"   => $RW->Location->Text(),
    );
    $r{save} = 1 if $WinPPM{SAVE};
    my $ok = 1;
    if(not $r{repository}) {
        $RW->MessageBox(
			"Repository name not valid",
			"ERROR",
			MB_ICONERROR,
		);
        return 0;
    } elsif(not $r{location}) {
		$RW->MessageBox(
			"Repository location not valid",
			"ERROR",
			MB_ICONERROR,
		);
        return 0;
    }
    if($RW->Editing->Text) {
        my @s = ();
        @s = ("save" => 1) if $WinPPM{SAVE};
        PPM::RemoveRepository("repository" => $RW->Editing->Text, @s);
    }
    PPM::AddRepository(%r);
	RepClose_Click();
	return 1;
}

#===================
sub RepClose_Click {
#===================
    $RW->Hide();
    $W->Enable();
    $W->SetForegroundWindow();
    $W->Tree->SetFocus();
	return 1;
}

#=================
sub RW_Terminate {
#=================
    RepClose_Click();
    return 0;
}

#====================
sub PPMConfig_Click {
#====================
    $W->Disable();
    my %o = PPM::GetPPMOptions();
    $CW->Root->Text($o{ROOT});
    $CW->Build->Text($o{BUILDDIR});
    $CW->Case->Checked(
        ($o{IGNORECASE} =~ /yes/i) ? 1 : 0
    );
    $CW->Clean->Checked(
        ($o{CLEAN} =~ /yes/i) ? 1 : 0
    );
    $CW->Force->Checked(
        ($o{FORCE_INSTALL} =~ /yes/i) ? 1 : 0
    );
    $CW->Move(
        $W->Left + ($W->Width  - $CW->Width )/2,
        $W->Top  + ($W->Height - $CW->Height)/2,
    );
    $CW->Show();
}

#====================
sub ConfClose_Click {
#====================
    $CW->Hide();
    $W->Enable();
    $W->SetForegroundWindow();
    $W->Tree->SetFocus();
}

#=================
sub CW_Terminate {
#=================
    ConfClose_Click();
    return 0;
}

#==================
sub PPMInfo_Click {
#==================
    my $p = XML::Parser->new( Style => 'Objects', Pkg => 'XML::PPMConfig' );
    my @parsed = @{ $p->parsefile($PPM::PPMdat) };
    my %parsed = %{$parsed[0]};
    my $elem;
    my $PPM_ver;
    my $CPU;
    my $OS_VALUE;
    my $OS_VERSION;
    my $LANGUAGE;
    foreach $elem (@{$parsed{Kids}}) {
        my $subelem = ref $elem;
        $subelem =~ s/.*:://;
        # print "$elem => $subelem\n";
        next if ($subelem eq 'Characters');
        if ($subelem eq 'PPMVER') {
            # Get the value out of our _only_ character data element.
            $PPM_ver = $elem->{Kids}[0]{Text};
        } elsif ($subelem eq 'PLATFORM') {
            # Get values out of our attributes
            $CPU        = $elem->{CPU};
            $OS_VALUE   = $elem->{OSVALUE};
            $OS_VERSION = $elem->{OSVERSION};
            $LANGUAGE   = $elem->{LANGUAGE};
        }
    }

    Win32::GUI::MessageBox(
        0,
        "This is PPM, version $PPM_ver.\r\n".
        "Platform: $OS_VALUE-$CPU $OS_VERSION $LANGUAGE",
        "PPM Info",
        MB_ICONINFORMATION | MB_OK,
    );
}

#===============
sub Exit_Click {
#===============
    return -1;
}

#=================
sub Verify_Click {
#=================
    my $node = $W->Tree->SelectedItem();
    my %n = $W->Tree->GetItem($node);
    my $parent = $W->Tree->GetParent($node);
    my %r = $W->Tree->GetItem($parent);
    $PPM::PPMERR = "";
    my $v;
	if($r{-image} == $IL_PPMREPF) {
		$v = PPM::VerifyPackage(
	        "package" => $n{-text},
	        "location" => $Repos{$r{-text}},
	    );
	} else {
		$v = PPM::VerifyPackage(
	        "package" => $n{-text},
		);
	}
    if(not defined $v) {
        Win32::GUI::MessageBox(0, $PPM::PPMERR, "ERROR", MB_ICONERROR);
    } else {
        if($v == 0) {
            $W->MessageBox(
                "Package $n{-text} is up-to-date",
                "Verify",
                MB_ICONINFORMATION
            );
        } else {
            my $now = $W->MessageBox(
                "Upgrade available!\r\nDo you want to upgrade now?",
                "Verify",
                MB_ICONEXCLAMATION | MB_YESNO
            );
			if($now == 6) {
				if($r{-image} == $IL_PPMREPF) {
					$v = PPM::VerifyPackage(
						"package" => $n{-text},
						"location" => $Repos{$r{-text}},
						"upgrade" => 1,
					);
				} else {
					$v = PPM::VerifyPackage(
						"package" => $n{-text},
						"upgrade" => 1,
					);
				}
			}
		}
    }
}
#=====================
sub POP_Verify_Click {
#=====================
	Verify_Click();
}
#==========================
sub POP_InstdVerify_Click {
#==========================
	Verify_Click();
}

#====================
sub ViewRepos_Click {
#====================
	SelectTab(0);
}

#====================
sub ViewInstd_Click {
#====================
	SelectTab(1);
}

#===================
sub Autosave_Click {
#===================
	$M->{Autosave}->Checked(not $M->{Autosave}->Checked);
	$WinPPM{SAVE} = $M->{Autosave}->Checked;
}

#=================
sub Search_Click {
#=================
    $W->Disable();
	if(not exists $WinPPM{SW_Init}) {
		my %o = PPM::GetPPMOptions();
		$SW->SearchCase->Checked(
			($o{IGNORECASE} =~ /yes/i) ? 1 : 0
		);
	}
	$SW->Where->Clear();
	$SW->Where->InsertItem(
		-text => "All repositories",
		-image => $IL_PPMREPA,
		-selectedimage => $IL_PPMREPA,
	);
	my $node = $W->Tree->GetChild(0);
	my %i = $W->Tree->GetItem($node);
	$SW->Where->InsertItem(
		-text => $i{-text},
		-image => $i{-image},
		-selectedimage => $i{-image},
	);
	while($node = $W->Tree->GetNextSibling($node)) {
		%i = $W->Tree->GetItem($node);
		next if $i{-image} == $IL_PPMREPN;
		$SW->Where->InsertItem(
			-text => $i{-text},
			-image => $i{-image},
			-selectedimage => $i{-image},
		);
	}
	if(not exists $WinPPM{SW_Init}) {
		$SW->SearchName->Checked(1);
		$SW->Where->Select(0);
		$WinPPM{SW_Init} = 1;
	}
	$SW->Move(
        $W->Left + ($W->Width  - $SW->Width )/2,
        $W->Top  + ($W->Height - $SW->Height)/2,
    );
    $SW->Show();
}
#===================
sub SearchOK_Click {
#===================
    $SW->Hide();
    $W->Enable();
    $W->SetForegroundWindow();
    $W->Tree->SetFocus();

	POP_ClearSearch_Click();

	my %sp;
	my %f;
	if($SW->SearchCase->Checked) {
		$sp{"ignorecase"} = "No";
	} else {
		$sp{"ignorecase"} = "Yes";
	}
	if($SW->SearchName->Checked) {
		$sp{"searchtag"} = "title";
	} elsif($SW->SearchAuthor->Checked) {
		$sp{"searchtag"} = "author";
	} elsif($SW->SearchAbstract->Checked) {
		$sp{"searchtag"} = "abstract";
	}
	$sp{"searchRE"} = $SW->What->Text;
	if($SW->Where->Text eq "Installed packages") {
		%f = PPM::QueryInstalledPackages(%sp);
		if(%f) {
			my $r = $W->Tree->InsertItem(
				-text => "Search results",
				-image => $IL_PPMREPR,
			);
			my $f;
			foreach $f (sort keys %f) {
				$W->Tree->InsertItem(
					-text => $f,
					-image => $IL_PPMREPO,
					-parent => $r,
				);
			}
			$W->Tree->Expand($r);
			$W->Status->Text(scalar(keys %f)." packages found");
		} else {
			$W->MessageBox(
				"No packages found",
				"PPM Search",
				MB_ICONEXCLAMATION,
			);
			$W->Status->Text("0 packages found");
		}
	} else {
		if($SW->Where->Text ne "All repositories") {
			$sp{"location"} = $Repos{$SW->Where->Text};
			$sp{"repository"} = $SW->Where->Text;
			%f = SearchAtLocation(%sp);
		} else {
			my %sf;
			my @f;
			%Repos = PPM::ListOfRepositories();
			foreach my $r (sort keys %Repos) {
				$sp{"location"} = $Repos{$r};
				$sp{"repository"} = $r;
				%sf = SearchAtLocation(%sp);
				push(@f, %sf);
			}
			%f = @f;
		}
		if(%f) {
			POP_ClearSearch_Click();
			my $r = $W->Tree->InsertItem(
				-text => "Search results",
				-image => $IL_PPMREPR,
			);
			my $f;
			foreach $f (sort keys %f) {
				$W->Tree->InsertItem(
					-text => $f,
					-image => $IL_PPMREPC,
					-parent => $r,
				);
			}
			$W->Tree->Expand($r);
			$W->Status->Text(scalar(keys %f)." packages found");
		} else {
			$W->MessageBox(
				"No packages found",
				"PPM Search",
				MB_ICONEXCLAMATION,
			);
			$W->Status->Text("0 packages found");
		}

	}
	return 1;
}

#=====================
sub SearchAtLocation {
#=====================
    my(%sp) = @_;
	my %f = ();
	my %p = PPM::RepositoryPackages("location" => $sp{"location"});
	foreach (keys %sp) {
		print "SP: $_ = $sp{$_}\n";
	}
	foreach my $p (@{$p{$sp{"location"}}}) {
		print "checking $p...";
		my $string = PPM::QueryPPD("package" => $p, %sp);
		if($string) {
			$f{$p." ($sp{repository})"} = $sp{"location"};
			print "match!\n";
		} elsif(not defined $string) {
			print "ERROR: $PPM::PPMERR\n";
		} elsif($string eq "") {
			print "no good\n";
		}
	}
	return %f;
}

#=======================
sub SearchCancel_Click {
#=======================
    $SW->Hide();
    $W->Enable();
    $W->SetForegroundWindow();
    $W->Tree->SetFocus();
}

#==================
sub Operate_Click {
#==================
	if($PW->Operate->Text eq "&Remove") {
		RemovePackage($PW->PPMName->Text);
		PW_Terminate();
	} else {
		my $node = $W->Tree->SelectedItem();
		my $parent = $W->Tree->GetParent($node);
		my %r = $W->Tree->GetItem($parent);
		InstallPackage($PW->PPMName->Text, $Repos{$r{-text}});
		PW_Terminate();
	}
}

#===================
sub ShowProperties {
#===================
    my $node = $W->Tree->SelectedItem();
    my %n = $W->Tree->GetItem($node);
	my $parent = $W->Tree->GetParent($node);
	my %r = $W->Tree->GetItem($parent);
	my %i;
	if($r{-image} eq $IL_PPMREPF) {
		%i = PPM::RepositoryPackageProperties(
			"package" => $n{-text},
			"location" => $Repos{$r{-text}},
		);
		$PW->Operate->Text("&Install");
	} elsif($r{-image} eq $IL_PPMREPR) {
		if($n{-image} eq $IL_PPMREPC) {
			my($package, $repository) = split(/\s*[()]/, $n{-text});
			%i = PPM::RepositoryPackageProperties(
				"package" => $package,
				"location" => $Repos{$repository},
			);
		} else {
			%i = %{$Instd{$n{-text}}};
		}
	} else {
		%i = %{$Instd{$n{-text}}};
		$PW->Operate->Text("&Remove");
	}
	$W->Disable();
	$PW->PPMName->Text($i{NAME});
	$PW->PPMVersion->Text($i{VERSION});
	$PW->PPMAuthor->Text($i{AUTHOR});
	$PW->PPMAbstract->Text($i{ABSTRACT});
	$PW->PPMDate->Text($i{DATE});
	$PW->Move(
		$W->Left + ($W->Width  - $PW->Width )/2,
		$W->Top  + ($W->Height - $PW->Height)/2,
	);
	$PW->Show();
}

#==================
sub RemovePackage {
#==================
	my($package) = @_;
    my $sure = $W->MessageBox(
        "Are you sure you want to remove $package?",
        "Remove",
        MB_ICONEXCLAMATION | MB_YESNO
    );
    print "sure: $sure\n";
    if($sure == 6) {
        $PPM::PPMERR = "";
        $W->Status->Text("Removing '$package'...");
        my $v = PPM::RemovePackage(
            "package" => $package,
        );
		if($v == 1) {
			$W->Status->Text("Package '$package' successfully removed.");
		} else {
			Win32::GUI::MessageBox($W, $PPM::PPMERR, "ERROR", MB_ICONERROR);
        }
    }
}

#===================
sub InstallPackage {
#===================
	my($package, $location) = @_;
	$PPM::PPMERR = "";
	$W->Status->Text("Installing '$package'...");
	my $v = PPM::InstallPackage(
		"package" => $package,
		"location" => $location,
	);
	if($v == 1) {
		Win32::GUI::MessageBox($W, "Package '$package' successfully installed.", "WinPPM", MB_ICONINFORMATION);
	} else {
		Win32::GUI::MessageBox($W, $PPM::PPMERR, "ERROR", MB_ICONERROR);
	}
}

#==================
sub DefineBitmaps {
#==================
$B_PPMREPO = new Win32::GUI::BitmapInline( q(
Qk02AwAAAAAAADYAAAAoAAAAEAAAABAAAAABABgAAAAAAAADAAAAAAAAAAAAAAAAAAAAAAAAzOLj
zOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLj
zOLjzOLjAE/fAD+/AAC/AACAzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjAE/fT3D/
AAC/AAC/AACAAACAzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjAE/fAD+/AAC/AAC/AAC/AACA
AABwAABwzOLjzOLjzOLjzOLjzOLjzOLjzOLjAADfAADfAAC/AAC/AAC/AD+/ADCQAABwAABwAABw
zOLjzOLjzOLjzOLjzOLjAADfAADfAD+/AAC/AAC/IFD/T3D/T3D/AACAAABwAABwAABwzOLjzOLj
zOLjsLD/AADfAADfAAC/AAC/IFD/T3D/AAAAT3D/T3D/AABwAABwAB9QAE9wzOLjzOLjT0//AAC/
AAC/AD+/b4//T3D/AAAAAL+/AFBQT3D/T3D/AABQAB9QAB9QzOLjzOLjAAC/AD+/b4//T3D/Dw8P
AAAAAL+/AP//AP//AAAAADCQT3D/ACBwAB9QzOLjzOLjT3D/T3D/ADCQAB9QAB9QDw8PAP//AP//
AP//AB9QAABQAD+/IFD/AABQzOLjzOLjzOLjT3D/AB9QAB9QAB9QAB9QAFBQAL+/AFBQAB9QAABQ
AABQAD+/AE/fzOLjzOLjzOLjzOLjT3D/AB9QAB9QAB9QAB9QAB9QAB9QAABQAABQAABQADCQAE/f
zOLjzOLjzOLjzOLjzOLjT3D/AB9QDw8PAB9QAB9QAB9QAABQACBwIFD/T0//zOLjzOLjzOLjzOLj
zOLjzOLjzOLjIFD/AB9QAB9QAABQAB9QAE/fAE/fzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLj
zOLjzOLjACBwAD+/T0//zOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLj
zOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLj
) );

$B_PPMREPN = new Win32::GUI::BitmapInline( q(
Qk02AwAAAAAAADYAAAAoAAAAEAAAABAAAAABABgAAAAAAAADAAAAAAAAAAAAAAAAAAAAAAAAzOLj
zOLjzOLjgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAAAAAzOLjzOLjzOLjzOLjgICAwMDA
gICAwMDAgICAwMDAgICAwMDAgICAwMDAgICAgICAAAAAzOLjzOLjgICAwMDAwMDAwMDAwMDAwMDA
wMDAwMDAwMDAwMDAwMDAwMDAgICAAAAAzOLjzOLjgICA////////////////////////////////
////////////wMDAAAAAzOLjzOLjzOLjgICA////////////////f6Pnf3/P////////////////
wMDAAAAAzOLjzOLjzOLjgICA////////////P3ffExzPAACfPz+X////////////wMDAAAAAzOLj
zOLjzOLjgICA////////Pz/nAA/HCBTPJ1PTAAB0Pz+T////////wMDAAAAAzOLjzOLjzOLjgICA
////v7//AADPGzPPL0y/E1+DO1TbAA9Yf5uv////wMDAAAAAzOLjzOLjzOLjgICA////k5vvL1vT
Fy9rA3NzAP//ABNMG0fLf4en////wMDAAAAAzOLjzOLjzOLjgICA////////Z3/TAB9QACtQAFNr
AAdQABt7f6fv////wMDAAAAAzOLjzOLjzOLjgICA////////////W3fTAxs/ABdQAC+fm6f/////
////wMDAAAAAzOLjzOLjzOLjgICA////////////////v8fbk6Pv////////////////wMDAAAAA
zOLjzOLjzOLjgICA////////////////////////////////////////wMDAAAAAzOLjzOLjzOLj
AICAAICAAICAAICAAICAAICAAICAAICAAICAAICAAICAwMDAAAAAzOLjzOLjzOLjAICAAP//AP//
AP//AP//AP//AP//AP//AP//AP//AP//AICAAAAAzOLjzOLjzOLjzOLjAICAAICAAICAAICAAICA
AICAAICAAICAAICAAICAAICAAAAAzOLj
) );

$B_PPMREPF = new Win32::GUI::BitmapInline( q(
Qk02AwAAAAAAADYAAAAoAAAAEAAAABAAAAABABgAAAAAAAADAAAAAAAAAAAAAAAAAAAAAAAAzOLj
zOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLj
zOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAzOLjAJ+fYM/PYM/PYM/PYM/PYM/PYM/PYM/PYM/P
YM/PYM/PYM/PYM/PYM/PAAAAzOLjAJ+fz///n8//n///n8//n///T6PnT3/Pn8//n///n8//n8//
n8//YM/PAAAAzOLjAJ+fz///n///n///n///J3ffExzPAACfJz+Xn8//n///n8//n8//YM/PAAAA
zOLjAJ+fz///n///n///Jz/nAA/HCBTPJ1PTAAB0Jz+Tn8//n///n8//YM/PAAAAzOLjAJ+fz///
n///j7//AADPGzPPL0y/E1+DO1TbAA9YT5uvn8//n///YM/PAAAAzOLjAJ+fz///n///Y5vvL1vT
Fy9rA3NzAP//ABNMG0fLT4enn///n8//YM/PAAAAzOLjAJ+fz///n///n///T3/TAB9QACtQAFNr
AAdQABt7T6fvn8//n///YM/PAAAAzOLjAJ+fz///n///n///n///Q3fTAxs/ABdQAC+fa6f/n///
n///n8//YM/PAAAAzOLjAJ+fz///z///z///z///z///d8fbY6Pvz///z///z///z///n///YM/P
AAAAzOLjAJ+fYM/PYM/PYM/PYM/PYM/PYM/PYM/PAJ+fAJ+fAJ+fAJ+fAJ+fAJ+fzOLjzOLjzOLj
AJ+f8PDwz///z///n///n///AJ+fAAAAzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjAJ+fAJ+f
AJ+fAJ+fAJ+fAAAAzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLj
zOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLj
) );

$B_PPMREPI = new Win32::GUI::BitmapInline( q(
Qk02AwAAAAAAADYAAAAoAAAAEAAAABAAAAABABgAAAAAAAADAAAAAAAAAAAAAAAAAAAAAAAAzOLj
zOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLj
zOLjzOLjAE/fAD+/AAC/AACAzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjAE/fT3D/
AAC/AAC/AACAAACAzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjAE/fAD+/AAC/AAC/AAC/AACA
AABwAABwzOLjzOLjzOLjzOLjzOLjzOLjzOLjAADfAADfAAC/AAC/AAC/AD+/ADCQAABwAABwAABw
zOLjzOLjzOLjzOLjzOLjAADfAADfAD+/AAC/AAC/IFD/T3D/T3D/AACAAABwAABwAABwzOLjzOLj
zOLjsLD/AADfAADfAAC/AAC/IFD/T3D/AAAAT3D/T3D/AABwAABwAB9QAE9wzOLjzOLjT0//AAC/
AAC/AD+/b4//T3D/AAAAAL+/AFBQT3D/T3D/AABQAB9QAB9QzOLjzOLjAAC/AD+/b4//T3D/Dw8P
AAAAAL+/AP//AP//AAAAADCQT3D/k5iYUFBQmamqzOLjT3D/T3D/ADCQAB9QAB9QDw8PAP//g4eH
aHBwaHBwaHBwaHBwk5eXv7+/UFBQzOLjzOLjT3D/AB9QAB9QAB9QAB9QAFBQwNHSW19fW19fW19f
W19fV1dXj4+Pg4iIzOLjzOLjzOLjT3D/AB9QAB9QAB9QAB9QAB9QtsHBkJCQkJCQkJCQkJCQmJiY
ZnFxzOLjzOLjzOLjzOLjT3D/AB9QDw8PAB9QAB9QprGxuKCgx3h4r2B4oKCgODg4ucnKzOLjzOLj
zOLjzOLjzOLjIFD/AB9QAB9QAABQprGxqHBw85t7wyQwoKCgMDAwzOLjzOLjzOLjzOLjzOLjzOLj
zOLjzOLjACBwAD+/prGxtLSomIhwmIhwoKCgMDAwzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLj
zOLjzOLjo6iooKCgoKCgoKCga3BwzOLj
) );

$B_PPMREPL = new Win32::GUI::BitmapInline( q(
Qk02AwAAAAAAADYAAAAoAAAAEAAAABAAAAABABgAAAAAAAADAAAAAAAAAAAAAAAAAAAAAAAAzOLj
zOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLj
zOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAzOLjAJycY87OY87OY87OY87OY87OY87OY87OY87O
Y87OY87OY87OY87OY87OAAAAzOLjAJyczv//nM7/nP//nM7/nP//nM7/nP//k5iYUFBQmamqnM7/
nM7/Y87OAAAAzOLjAJyczv//nP//g4eHaHBwaHBwaHBwaHBwk5eXv7+/UFBQnM7/nM7/Y87OAAAA
zOLjAJyczv//nP//wNHSW19fW19fW19fW19fV1dXj4+Pg4iInP//nM7/Y87OAAAAzOLjAJyczv//
nP//nP//tsHBkJCQkJCQkJCQkJCQmJiYZnFxnM7/nP//Y87OAAAAzOLjAJyczv//nP//nP//prGx
uKCgx3h4r2B4oKCgODg4ucnKnP//nM7/Y87OAAAAzOLjAJyczv//nP//nP//prGxqHBw85t7wyQw
oKCgMDAwnP//nM7/nP//Y87OAAAAzOLjAJyczv//nP//nP//prGxtLSomIhwmIhwoKCgMDAwnP//
nP//nM7/Y87OAAAAzOLjAJyczv//zv//zv//zv//o6iooKCgoKCgoKCga3Bwzv//zv//nP//Y87O
AAAAzOLjAJycY87OY87OY87OY87OY87OY87OY87OAJycAJycAJycAJycAJycAJyczOLjzOLjzOLj
AJyc9/f3zv//zv//nP//nP//AJycAAAAzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjAJycAJyc
AJycAJycAJycAAAAzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLj
zOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLj
) );

$B_PPMREPC = new Win32::GUI::BitmapInline( q(
Qk02AwAAAAAAADYAAAAoAAAAEAAAABAAAAABABgAAAAAAAADAAAAAAAAAAAAAAAAAAAAAAAAzOLj
zOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLj
zOLjzOLjAE/fAD+/AAC/AACAzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjAE/fT3D/
AAC/AAC/AACAAACAzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjAE/fAD+/AAC/AAC/AAC/AACA
AABwAABwzOLjzOLjzOLjzOLjzOLjzOLjzOLjAADfAADfAAC/AAC/AAC/AD+/ADCQAABwAABwAABw
zOLjzOLjzOLjzOLjzOLjAADfAADfAD+/AAC/AAC/IFD/T3D/T3D/AACAAABwAABwAABwzOLjzOLj
zOLjsLD/AADfAADfAAC/AAC/IFD/T3D/AAC/T3D/T3D/AABwAABwAB9QAE9wzOLjzOLjT0//AAC/
AAC/AD+/b4//T3D/AAC/AAC/AAC/T3D/T3D/AABQAB9QAB9QzOLjzOLjAAC/AD+/b4//T3D/AAC/
AAC/AAC/AAC/AAC/AAC/ADCQT3D/ACBwAB9QzOLjzOLjT3D/T3D/ADCQAAC/AAC/AAC/AAC/AAC/
AAC/AAC/AAC/AD+/IFD/AABQzOLjzOLjzOLjT3D/AAC/AAC/AAC/AAC/AAC/AAC/AAC/AAC/AAC/
AAC/AD+/AE/fzOLjzOLjzOLjzOLjT3D/AAC/AAC/AAC/AAC/AAC/AAC/AAC/AAC/AAC/ADCQAE/f
zOLjzOLjzOLjzOLjzOLjT3D/AAC/AAC/AAC/AAC/AAC/AAC/ACBwIFD/T0//zOLjzOLjzOLjzOLj
zOLjzOLjzOLjIFD/AAC/AAC/AAC/AAC/AE/fAE/fzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLj
zOLjzOLjAAC/AD+/T0//zOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLj
zOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLj
) );

$B_PPMREPA = new Win32::GUI::BitmapInline( q(
Qk02AwAAAAAAADYAAAAoAAAAEAAAABAAAAABABgAAAAAAAADAAAAAAAAAAAAAAAAAAAAAAAAzOLj
zOLjAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAzOLjAJ+fYM/PYM/P
YM/PYM/PYM/PYM/PYM/PYM/PYM/PYM/PYM/PYM/PYM/PAAAAzOLjAJ+fz///n8//n///n8//n///
T6PnT3/Pn8//n///n8//n8//n8//YM/PAAAAzOLjAJ+fz///n///n///n///J3ffExzPAACfJz+X
n8//n///n8//n8//YM/PAAAAAJ+fAJ+fz///n///n///Jz/nAA/HCBTPJ1PTAAB0Jz+Tn8//n///
n8//YM/PAAAAAJ+fAJ+fz///n///j7//AADPGzPPL0y/E1+DO1TbAA9YT5uvn8//n///YM/PAAAA
AJ+fAJ+fz///n///Y5vvL1vTFy9rA3NzAP//ABNMG0fLT4enn///n8//YM/PAAAAAJ+fAJ+fz///
n///n///T3/TAB9QACtQAFNrAAdQABt7T6fvn8//n///YM/PAAAAAJ+fAJ+fz///n///n///n///
Q3fTAxs/ABdQAC+fa6f/n///n///n8//YM/PAAAAAJ+fAJ+fz///z///z///z///z///d8fbY6Pv
z///z///z///z///n///YM/PAAAAAJ+fAJ+fYM/PYM/PYM/PYM/PYM/PYM/PYM/PAJ+fAJ+fAJ+f
AJ+fAJ+fAJ+fzOLjAJ+fz///AJ+f8PDwz///z///n///n///AJ+fAAAAn///n///n8//YM/PAAAA
zOLjAJ+fz///z///AJ+fAJ+fAJ+fAJ+fAJ+fAAAAz///z///z///n///YM/PAAAAzOLjAJ+fYM/P
YM/PYM/PYM/PYM/PYM/PYM/PAJ+fAJ+fAJ+fAJ+fAJ+fAJ+fzOLjzOLjzOLjAJ+f8PDwz///z///
n///n///AJ+fAAAAzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLjAJ+fAJ+fAJ+fAJ+fAJ+fAAAA
zOLjzOLjzOLjzOLjzOLjzOLjzOLjzOLj
) );

$B_PPMREPR = new Win32::GUI::BitmapInline( q(
Qk02AwAAAAAAADYAAAAoAAAAEAAAABAAAAABABgAAAAAAAADAAAAAAAAAAAAAAAAAAAAAAAAzOLj
zOLjzOLjgICAgICAgICAgICAgICAgICAgICAgICAAAAAAAAAAAAAzOLjzOLjzOLjzOLjgICAwMDA
gICAwMDAgICAwMDAgICAwMDAgAAA//8A/wAAAAAAAAAAzOLjzOLjgICAwMDAwMDAwMDAwMDAwMDA
wMDAwMDAgAAA//8A/wAA/wAAAAAAAAAAzOLjzOLjgICA////////////////////////gAAA//8A
/wAA/wAAwMDAwMDAAAAAzOLjzOLjzOLjgICA////////////////gAAA//8A/wAA/wAAwMDA////
wMDAAAAAzOLjzOLjzOLjgICAgICAAAAAAAAAgICAwMDA/wAA/wAAwMDA////////wMDAAAAAzOLj
zOLjzOLjgICAwMDA//8AwMDAAAAAgICAgICAwMDAPz+T////////wMDAAAAAzOLjzOLjgICA////
//8AwMDA//8AwMDAAAAAwMDAO1TbAA9Yf5uv////wMDAAAAAzOLjzOLjgICA//8A//////8AwMDA
//8AAAAAwMDAABNMG0fLf4en////wMDAAAAAzOLjzOLjgICA//////8A//////8AwMDAAAAAwMDA
AAdQABt7f6fv////wMDAAAAAzOLjzOLjzOLjgICA//////8A////AAAAwMDAABdQAC+fm6f/////
////wMDAAAAAzOLjzOLjzOLjgICAgICAgICAAAAAwMDAv8fbk6Pv////////////////wMDAAAAA
zOLjzOLjzOLjgICA////////////////////////////////AAAAAAAAAAAAAAAAzOLjzOLjzOLj
gICA////////////////////////////////wMDA////gICAzOLjzOLjzOLjzOLjgICA////////
////////////////////////wMDAgICAzOLjzOLjzOLjzOLjzOLjgICAgICAgICAgICAgICAgICA
gICAgICAgICAgICAzOLjzOLjzOLjzOLj
) );

}

#=================
sub InitSettings {
#=================
	if(open(INI, "winppm.ini")) {
		$WinPPM{SAVE} = <INI>;
		close(INI);
	} else {
		$WinPPM{SAVE} = 0;
	}
}

#==================
sub WriteSettings {
#==================
	if(open(INI, ">winppm.ini")) {
		print INI $WinPPM{SAVE}, "\n";
		close(INI);
	} else {
		$WinPPM{SAVE} = 0;
	}
}