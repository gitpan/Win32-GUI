use Win32::GUI;

$Window = new Win32::GUI::Window(
    -name   => "Window",
    -left   => 100, 
    -top    => 100,
    -width  => 300, 
    -height => 300,
    -text   => "Win32::GUI TEST - Combobox",
);

$CBsimplelbl = $Window->AddLabel(
    -text   => "Simple Combobox:",
    -left   => 10,
    -top    => 10,
);

$CBsimple = $Window->AddCombobox(
    -name   => "Simple",
    -left   => 10, 
    -top    => 30,
    -width  => 250, 
    -height => 100,
);
$CBsimple->InsertItem("item 1");
$CBsimple->InsertItem("item 2");
$CBsimple->InsertItem("item 3");

$CBdropdownlbl = $Window->AddLabel(
    -text   => "Dropdown Combobox:",
    -left   => 10,
    -top    => 160,
);


$CBdropdown = $Window->AddCombobox( 
    -name   => "Dropdown",
    -left   => 10, 
    -top    => 180,
    -width  => 250, 
    -height => 100,
    -style  => WS_VISIBLE | 2 | WS_NOTIFY,
);
$CBdropdown->InsertItem("item 1");
$CBdropdown->InsertItem("item 2");
$CBdropdown->InsertItem("item 3");

$Status = $Window->AddStatusBar(
    -name => "Status",
    -text => "Win32::GUI Combobox sample",
);

$Window->Show();
Win32::GUI::Dialog();

#=====================
sub Window_Terminate {
#=====================
    return -1;
}

#==================
sub Simple_Change {
#==================
    $Status->Text("Simple: ".$CBsimple->GetString($CBsimple->SelectedItem));
    
}

#====================
sub Dropdown_Change {
#====================
	my $s = $CBdropdown->SelectedItem;
    $Status->Text("Dropdown: ".$CBdropdown->GetString($s));
}

#=====================
sub Simple_Anonymous {
#=====================
    my($code) = @_;
    print "Anonymous code:$code\n";
    if($code == 6) {
        $simplechanged = 1;
    } elsif($code == 9) {
        if($simplechanged) {
            $CBsimple->InsertItem($CBsimple->Text());
        }
    }
}
