
use Win32::GUI;

$Menu = Win32::GUI::MakeMenu(
    "&Options"   => "Options",
    " > Set &indent..."  => "Indent",
    " > Choose &font..."  => "Font",
    " > &Lines"  => { -name => "HasLines", -checked => 1 },
    " > &Root lines"  => { -name => "HasRootLines", -checked => 1 },
    " > &Buttons"  => { -name => "HasButtons", -checked => 1 },
    " > I&mage"  => { -name => "HasImages", -checked => 1 },
    " > -"       => 0,
    " > E&xit"   => "Exit",
);

$Window = new GUI::Window(
    -name   => "Window",
    -text   => "Win32::GUI TEST - TreeView",
    -height => 200, 
    -width  => 300,
    -left   => 100, 
    -top    => 100,
    -menu   => $Menu,
);

$C = new Win32::GUI::Cursor("harrow.cur");

Win32::GUI::SetCursor($C);

$B1 = new Win32::GUI::Bitmap("node.bmp");
$B2 = new Win32::GUI::Bitmap("node_sel.bmp");

$IL = new Win32::GUI::ImageList(16, 16, 0, 2, 10);
$IL->Add($B1, 0);
$IL->Add($B2, 0);

$TV = $Window->AddTreeView(
    -name      => "Tree",
    -text      => "hello world!",
    -width     => $Window->ScaleWidth, 
    -height    => $Window->ScaleHeight,
    -left      => 0, 
    -top       => 0,
    -lines     => 1, 
    -rootlines => 1,
    -buttons   => 1,
    -visible   => 1,
    -imagelist => $IL,
#    -checkboxes => 1,
#    -hottrack  => 1,
);

$IndentWin = new GUI::Window(
    -text   => "Treeview Indent",
    -name   => "IndentWin",
    -width  => 200,
    -height => 100, 
    -left   => 110, 
    -top    => 110,
);

$IndentVal = $IndentWin->AddLabel(
    -text => "Indent value = ".$TV->Indent(),
    -name => "IndentVal",
    -left => 10, 
    -top  => 10,
);

$IndentNew = $IndentWin->AddTextfield(
    -text   =>  $TV->Indent(),
    -name   =>  "IndentNew",
    -left   =>  10, 
    -top    => 40,
    -width  => 100, 
    -height => 25,
);

$IndentSet = $IndentWin->AddButton(
    -text => "Set", 
    -name => "IndentSet",
    -left => 130, 
    -top  => 40
);
                            
$TV1 = $TV->InsertItem(
    -text          => "ROOT", 
    -image         => 0, 
    -selectedimage => 1,
);

$TV3 = $TV->InsertItem(
    -parent        => $TV1, 
    -text          => "SUB 1", 
    -image         => 0, 
    -selectedimage => 1
	-selected      => 1,
);

$TV2 = $TV->InsertItem(
    -parent        => $TV1, 
    -text          => "SUB 2", 
    -image         => 0, 
    -selectedimage => 1
	-bold          => 1,
);

$Window->Show();

my $dblclick = 0;

Win32::GUI::Dialog();

sub Window_Terminate {
    $Window->PostQuitMessage(0);
}

sub Window_Resize {
    $TV->Resize($Window->ScaleWidth, $Window->ScaleHeight);
}

sub Tree_NodeClick {
    my %node = $TV->GetItem($_[0]);
    print "Click on node '$node{-text}' ".
          "(checkbox is ", ($TV->ItemCheck($_[0]) ? "on" : "off"), ")\n";
    return 1;
}

sub Tree_Expand {
    my %node = $TV->GetItem($_[0]);
    print "Expanded node '$node{-text}'\n";
    $dblclick = 1;
    return 1;
}

sub Tree_Collapse {
    my %node = $TV->GetItem($_[0]);
    print "Collapsed node '$node{-text}'\n";
    $dblclick = 1;
    return 1;
}

sub Tree_DblClick {
    if(!$dblclick) {
        my($x, $y) = Win32::GUI::GetCursorPos();
        print "Double click at $x, $y\n";
        my $node = $TV->SelectedItem();
        if($node) {
            $TV->ItemCheck($node, !$TV->ItemCheck($node));
            my %t = $TV->getItem($node);
            foreach my $k (keys %t) {
                print "$k => $t{$k}\n";
            }

        }
    } else {
        "got Collapse/Expand, ignoring DblClick\n";
        $dblclick = 0;
    }
    return 1;
}

sub Indent_Click {
    $Window->Disable();    
    $IndentVal->Text("Indent value = ".$TV->Indent());
    $IndentNew->Text($TV->Indent());
    $IndentWin->Show();
    $IndentNew->SetFocus();
    $IndentNew->Select(0, length($IndentNew->Text()));
    return 1;
}

sub IndentSet_Click {
    $TV->Indent($IndentNew->Text());
    $IndentWin->Hide();
    $Window->Enable();
    $Window->SetForegroundWindow();
}

sub IndentWin_Terminate {
    $IndentWin->Hide();
    $Window->Enable();
    $Window->SetForegroundWindow();
}

sub Font_Click {
    $Window->Disable();
    my @font = GUI::ChooseFont();
    if($font[0] eq "-name") {
        undef $TreeviewFont;
        $TreeviewFont = new GUI::Font(@font);
        $TV->SetFont($TreeviewFont);
        # $TV->Change(-font => $TreeviewFont);
    }
    $Window->Enable();
    $Window->SetForegroundWindow();
}

sub Exit_Click {
    $Window->PostQuitMessage(0);
}

sub HasLines_Click {
    my $checked = !$Menu->{HasLines}->Checked;
    printf "TV.Style is: %08X\n", $TV->GetWindowLong(-16);
    $TV->Change(-lines => $checked);
    printf "TV.Style after -lines => %d is: %08X\n", $checked, $TV->GetWindowLong(-16);
    $Menu->{HasLines}->Checked($checked);
}

sub HasRootLines_Click {
    my $checked = !$Menu->{HasRootLines}->Checked;
    printf "TV.Style is: %08X\n", $TV->GetWindowLong(-16);
    $TV->Change(-rootlines => $checked);
    printf "TV.Style after -rootlines => %d is: %08X\n", $checked, $TV->GetWindowLong(-16);
    $Menu->{HasRootLines}->Checked($checked);
}

sub HasButtons_Click {
    my $checked = !$Menu->{HasButtons}->Checked;
    printf "TV.Style is: %08X\n", $TV->GetWindowLong(-16);
    $TV->Change(-buttons => $checked);
    printf "TV.Style after -buttons => %d is: %08X\n", $checked, $TV->GetWindowLong(-16);
    $Menu->{HasButtons}->Checked($checked);
}

sub HasImages_Click {
    if($Menu->{HasImages}->Checked) {
        $Menu->{HasImages}->Checked(0);
        $TV->SetImageList(0);
    } else {
        $Menu->{HasImages}->Checked(1);
        $TV->SetImageList($IL);
    }
}
