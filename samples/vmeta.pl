
use Win32::GUI;

$W = new GUI::Window(
    -left => 100,
    -top => 100,
    -width => 400,
    -height => 400,
    -title => "EMF Viewer",
    -name => "Window",
);

$W->Show();

$W->BeginPaint();

# $result = $W->PlayEnhMetaFile("p:\\perl5\\win32gui-alpha\\testing\\hilogo.WMF");
# $result = $W->PlayEnhMetaFile("p:\\perl5\\win32gui-alpha\\testing\\hilogo.WMF\0");
# $result = $W->PlayEnhMetaFile("hilogo.WMF");

# $result = $W->PlayWinMetaFile(".\\GLOBO.WMF");

$result = $W->PlayEnhMetaFile("prova.emf");
print "PlayMetaFile returned $result (LastError = ", Win32::GetLastError(),")\n";

$W->EndPaint();

Win32::GUI::Dialog();

sub Window_Terminate {
    return -1;
}

sub Window_Resize {
    $W->InvalidateRect(1);
    Paint();
}   

sub Window_Activate {
    $W->InvalidateRect(1);
    Paint();
}

sub Paint {
	my $DC = $W->GetDC();
    $result = $W->PlayEnhMetaFile("prova.emf");
    print "PlayMetaFile returned $result (LastError = ", Win32::GetLastError(),")\n";
}