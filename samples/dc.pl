
use Win32::GUI;

$Font = new Win32::GUI::Font(
    -name => "Times New Roman",
    -size => 10,
    -bold => 1,
    -italic => 1,
);

$Win = new Win32::GUI::Window(
    -left => 100,
    -top => 100,
    -width => 300,
    -height => 300,
    -name => "Window",
    -text => "DC Drawing Test",
);

$Win->Show();

Win32::GUI::Dialog();

sub Window_Resize {
    Paint();
}

sub Window_Activate {
    Paint();
}

sub Window_Terminate {
    return -1;
}

sub Paint {
    my $W = $Win->ScaleWidth;
    my $H = $Win->ScaleHeight;
    $Win->BeginPaint();
    $Win->LineTo(0, 0);
    $Win->LineTo($W, $H);
    $Win->Circle(0, 0, $W, $H);
    $Win->SetBkMode(1);
    Win32::GUI::SelectObject($Win->{DC}, $Font);
    $Win->SetTextColor([0, 0, 255]);
    ($TW, $TH) = $Win->GetTextExtentPoint32("$W x $H");
    $Win->TextOut($W/2-$TW/2, $H/2-$TH/2, "$W x $H");
    $Win->EndPaint();
}

