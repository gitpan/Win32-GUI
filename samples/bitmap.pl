
use Win32::GUI;

$M = Win32::GUI::MakeMenu(
    "&File"     => "File",
    " > &Open"  => "Open",
    " > E&xit"  => "Exit",
    "&Bitmap"   => "Bitmap",
    " > &Info"  => "Info",
    " > &Resize window to bitmap" => "Resize",
);

$W = new Win32::GUI::Window(
    -title    => "Win32::GUI::Bitmap test",
    -left     => 100, 
    -top      => 100, 
    -width    => 400, 
    -height   => 400,
    -style    => WS_OVERLAPPEDWINDOW,
    -menu     => $M,
    -name     => "Window",
) or print_and_die("new Window");

$B = new Win32::GUI::Bitmap('zapotec.bmp') or print_and_die("new Bitmap");

($width, $height) = ($W->GetClientRect)[2..3];

$BITMAP = $W->AddLabel(
    -left => 0, 
    -top => 0,
    -width => $width, 
    -height => $height,
    -style => 14,
    -name => "Bitmap",
    -visible => 1,
    -text => "ouch",
);

$BITMAP->SetImage($B);
$BITMAP->Resize($width, $height);

$I = new Win32::GUI::DialogBox(
    -title  => "Bitmap info",
    -left   => 110,
    -top    => 110,
    -width => 300,
    -height => 200,
    -name => "InfoWindow",
);

$ttop = 10;
$I_Width  = MakeInfoControls("Width", "Width:");
$I_Height = MakeInfoControls("Height", "Height:");
$I_Depth  = MakeInfoControls("Depth", "Color depth:");
$I_Compr  = MakeInfoControls("Compr", "Compression:");
$I_Size   = MakeInfoControls("Size", "Image size:");

sub MakeInfoControls {
    my($name, $text) = @_;
    my $Lbl = $I->AddLabel(
        -text => $text,
        -left => 10,
        -top => $ttop,
        -name => $name."_Label",
    );
    my $Ctrl = $I->AddLabel(
        -text => "I'm a placeholder",
        -left => 110,
        -top => $ttop,
        -name => $name,
    );
    $ttop += 22;
    return $Ctrl;
}

$I_Close = $I->AddButton(
    -text   => "Close",
    -left   => $I->ScaleWidth-70,
    -top    => $I->ScaleHeight-35,
    -width  => 60,
    -height => 25,
    -name   => "InfoClose",
);


$W->Show;

Win32::GUI::Dialog();

sub Window_Resize {
    $BITMAP->Resize($W->ScaleWidth, $W->ScaleHeight);
}

sub Window_Terminate {
    $W->PostQuitMessage(0);
}

sub Open_Click {
    my $file = "*.bmp\0" . " " x 260;
    $file = GUI::GetOpenFileName(-file => $file);
    print $file, "\n";
    undef $B;
    $B = new GUI::Bitmap($file);
    if($B) {
        $BITMAP->SetImage($B);
        Window_Resize();
    }
}

sub Info_Click {
    $W->Disable();
    my ($x, $y, $depth, $compr, $size) = $B->Info();

    my @compr = qw( Uncompressed RLE-8bit RLE-4bit Uncompressed );
    print "X = $x\nI_Width = $I_Width\n";
    $I_Width->Text($x);
    $I_Height->Text($y);
    $I_Depth->Text($depth);
    $I_Compr->Text($compr[$compr]);
    $I_Size->Text($size);
    $I->Show();
}

sub InfoWindow_Terminate {
    $W->Enable();
    $W->SetForegroundWindow();
    $I->Hide();
    return 0;
}

sub InfoClose_Click {
    InfoWindow_Terminate();
}
sub Resize_Click {
    my ($x, $y) = $B->Info();
    my $ax = $W->Width - $W->ScaleWidth;
    my $ay = $W->Height - $W->ScaleHeight;
    if($x and $y) {
        print "Bitmap size is $x x $y\n";
        $W->Resize($x+$ax, $y+$ay);
    } else {
        print "Can't get bitmap size...\n";
        print "LastError=", Win32::GetLastError(), "\n";
    }
}

sub Exit_Click {
    $W->PostQuitMessage(0);
}

sub print_and_die {
    my($text) = @_;
    my $err = Win32::GetLastError();
    die "$text: Error $err\n";
}

