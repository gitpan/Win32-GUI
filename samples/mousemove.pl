use Win32::GUI;

$W = new Win32::GUI::Window(
    -name => "Window",
    -title => "Mouse tracking sample",
    -left => 100,
    -top => 100,
    -width => 300,
    -height => 300,
);

$Status = $W->AddStatusBar(
    -name => "Status",
);

$LC = new Win32::GUI::Class(
    -name => "dadasListBoxClass",
    -extends => "LISTBOX",
    -widget => "Listbox",
);

$L = $W->AddListbox(
    -class => $LC,
    -name => "List",
    -left => 0,
    -top => 0,
    -width => $W->ScaleWidth,
    -height => $W->ScaleHeight-$Status->Height,
);

$comment = <<EOC;
$W = new Win32::GUI::Window(
    -name => "Window",
    -title => "Mouse tracking sample",
    -left => 100,
    -top => 100,
    -width => 300,
    -height => 300,
);

$Status = $W->AddStatusBar(
    -name => "Status",
);

$LC = new Win32::GUI::Class(
    -name => "PodView_RichEdit",
    -extends => "RichEdit",
    -widget => "RichEdit",
);

$L = $W->AddRichEdit(
    -class => $LC,
    -name => "List",
    -left => 0,
    -top => 0,
    -width => $W->ScaleWidth,
    -height => $W->ScaleHeight-$Status->Height,
    -text => "hello, I'm a RichEdit!!!\r\ndadada",
);
EOC

$W->Show();
Win32::GUI::Dialog();

exit(0);



sub Window_Terminate {
    return -1;
}

sub Window_Resize {
    $L->Resize($W->ScaleWidth, $W->ScaleHeight-$Status->Height);
    $Status->Move(0, $W->ScaleHeight-$Status->Height);
    $Status->Resize($W->ScaleWidth, $Status->Height);
}

sub List_MouseMove {
    my($mx, $my) = Win32::GUI::GetCursorPos();
    my $Lx = $L->Left;
    my $Ly = $L->Top;
    $Status->Text(($mx-$Lx).", ".($my-$Ly));
}
