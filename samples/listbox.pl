
use Win32::GUI;
use Win32::Sound;

# $class = new GUI::Class("GUIPERL") or print_and_die("new Class");

$CUR = GUI::LoadCursorFromFile("harrow.cur");
# print "CUR = $CUR\n";
# $OLDCUR = GUI::SetCursor($CUR);

$W = new GUI::Window(
    -title    => "Win32::GUI::Listbox text",
    -left     => 100, 
    -top      => 100, 
    -width    => 360, 
    -height   => 210,
    -style    => 1024 | WS_BORDER | WS_CAPTION | WS_SYSMENU,
    -name     => "Window",
) or print_and_die("new Window");

$List1 = $W->AddListbox(
    -name => "List1",
    # -style => WS_CHILD | WS_VISIBLE | 1,
    -left => 5,
    -top  => 5,
    -height => 120,
    -menu => 1,
    -tabstop => 1,
    -group => 1,
    -width => 100,
    -foreground => [255, 255, 255],
    -background => [64, 64, 64],
    -style => WS_VSCROLL | WS_VISIBLE | WS_CHILD,
) or print_and_die("new Listbox");

$List1->SendMessage(0x0195, 201, 0);

$List1->AddString("Item 1 veryveryvery long");
$List1->AddString("Item 2");
$List1->AddString("Item 3");
$List1->AddString("Item 4");
$List1->AddString("Item 5");
$List1->AddString("Item 2");
$List1->AddString("Item 3");
$List1->AddString("Item 4");
$List1->AddString("Item 5");
$List1->AddString("Item 2");
$List1->AddString("Item 3");
$List1->AddString("Item 4");
$List1->AddString("Item 5");
$List1->AddString("Item 2");
$List1->AddString("Item 3");
$List1->AddString("Item 4");
$List1->AddString("Item 5");
$List1->Select(0);

$List2 = $W->AddListbox(
    -name => "List2",
    -addstyle => WS_CHILD | WS_VISIBLE | 1,
    -left => 250,
    -top  => 5,
    -height => 120,
    -menu => 2,
    -tabstop => 1,
    -group => 1, 
    -width => 100,
    -multisel => 1,
    -vscroll => 1,
);


$B = new Win32::GUI::Brush([0, 0, 128]);

$Add = $W->AddButton(
    -text  => "Add >",
    -left  => 125,
    -top   => 5,
    -width => 100,
    -menu  => 3,
    -tabstop => 1,
    -group => 1,
    -name  => "Add",
    -foreground => [255, 255, 255],
    -background => $B->{-handle},
);

$AddAll   = $W->AddButton(-text  => "All >>",
                          -left  => 125,
                          -top   => 35,
                          -width => 100,
                          -menu => 4,
                          -tabstop => 1,
                          -name  => "AddAll") or print_and_die("new Button");

$Remove = $W->AddButton(-text  => "< Remove",
                        -left  => 125,
                        -top   => 65,
                        -width => 100,
                        -menu  => 5,
                        -name  => "Remove") or print_and_die("new Button");

$RemoveAll = $W->AddButton(-text  => "<< All",
                           -left  => 125,
                           -top   => 95,
                           -width => 100,
                           -menu  => 6,
                           -name  => "RemoveAll") or print_and_die("new Button");


$Up = $W->AddButton(-text  => "Up",
                    -left  => 5,
                    -top   => 150,
                    -width => 45,
                    -menu => 7,
                    -tabstop => 1,
                    -group => 1,
                    -name  => "Up") or print_and_die("new Button");

$Down = $W->AddButton(-text  => "Down",
                      -left  => 55,
                      -top   => 150,
                      -width => 45,
                      -menu => 8,
                      -tabstop => 1,
                      -group => 1,
                      -name  => "Down") or print_and_die("new Button");
                              
$Close = $W->AddButton(-text  => "Close", 
                       -left  => 250, 
                       -top   => 150, 
                       -width => 100,
                       -name  => "Close") or print_and_die("new Button");

$Edit1 = $W->AddTextfield(
    -text => "ciao",
    -name => "Edit1",
    -left => 5,
    -top  => 115,
    -height => 20,
    -style => WS_TABSTOP | WS_CHILD | WS_BORDER | WS_VISIBLE | ES_LEFT | DS_3DLOOK,
    -width => 100,
    -foreground => [255, 255, 255],
    -background => [64, 64, 64],
) or print_and_die("new Textfield");

$Edit2 = $W->AddTextfield(
    -text => "ciao",
    -name => "Edit2",
    -left => 250,
    -top  => 115,
    -height => 20,
    -style => WS_TABSTOP | WS_CHILD | WS_BORDER | WS_VISIBLE | ES_LEFT | DS_3DLOOK,
    -width => 100,
) or print_and_die("new Textfield");


$W->Show;

$return = $W->Dialog();

sub List1_Click {
    my $sel = $List1->SelectedItem();
    if($sel != -1) {
        $Edit1->Text($List1->GetString($sel));
    }
}

sub List1_DblClick {
    Add_Click();
}

sub List2_Click {
    my $sel = $List2->SelectedItem();
    if($sel != -1) {
        $Edit2->Text($List2->GetString($sel));
    }
    return 1;
}

sub List2_DblClick {
    Remove_Click();
}

sub Add_Click {
    my $sel = $List1->SelectedItem();
    if($sel != -1) {
        my $new = $List2->InsertItem($List1->GetString($sel));
        $List2->Select($new);
        $Edit2->Text($List2->GetString($List2->SelectedItem));
    } else {
        Win32::Sound::Play("SystemDefault", SND_ASYNC);
    }
    return 1;    
}

sub Remove_Click {
    my $sel = $List2->SelectedItem();
    if($sel != -1) {
        $List2->RemoveItem($sel);
        $Edit2->Text("");
        if($List2->Count > 0) {
            if($sel >= $List2->Count) {
                $List2->Select($List2->Count-1);
            } else {
                $List2->Select($sel);
            }
            $Edit2->Text($List2->GetString($List2->SelectedItem));
        }
    } else {
        Win32::Sound::Play("SystemDefault", SND_ASYNC);
    }
    return 1;    
}

sub AddAll_Click {
    for $i (0..$List1->Count-1) {
        $List2->InsertItem($List1->GetString($i));
    }
    $List2->Select($List2->Count-1);
    $Edit2->Text($List2->GetString($List2->SelectedItem));
    return 1;
}

sub RemoveAll_Click {
    if($List2->Count > 0) {
        $List2->Clear;
        $Edit2->Text("");
    } else {
        Win32::Sound::Play("SystemDefault", SND_ASYNC);
    }
    return 1;
}

sub Edit1_Change {
    my $sel = $List1->SelectedItem();
    if($sel != -1) {
        $List1->RemoveItem($sel);
        $List1->InsertItem($Edit1->Text, $sel);
        $List1->Select($sel);
    }
    return 1;
}

sub Edit2_Change {
    my $sel = $List2->SelectedItem();
    if($sel != -1) {
        $List2->RemoveItem($sel);
        $List2->InsertItem($Edit2->Text, $sel);
        $List2->Select($sel);
    }
    return 1;    
}


sub Up_Click {
    my $sel = $List1->SelectedItem();
    if($sel > 0) {
        my $string = $List1->GetString($sel);
        $List1->RemoveItem($sel);
        $List1->InsertItem($string, $sel-1);
        $List1->Select($sel-1);
    } else {
        Win32::Sound::Play("SystemDefault", SND_ASYNC);
    }
    return 1;    
}

sub Down_Click {
    my $sel = $List1->SelectedItem();
    if($sel < $List1->Count-1) {
        my $string = $List1->GetString($sel);
        $List1->RemoveItem($sel);
        $List1->InsertItem($string, $sel+1);
        $List1->Select($sel+1);
    } else {
        Win32::Sound::Play("SystemDefault", SND_ASYNC);
    }
    return 1;    
}

sub Close_Click {
    return -1;
}

sub print_and_die {
    my($text) = @_;
    my $err = Win32::GetLastError();
    die "$text: Error $err\n";
}
