
use Win32::GUI;

$W = new GUI::Window(
    -left => 100,
    -top => 100,
    -width => 400,
    -height => 400,
    -title => "EMF Creator",
    -name => "Window",
);

print "About to show...\n";

$W->Show();

Win32::GUI::Dialog();

sub Window_Terminate {
    return -1;
}

sub Window_Resize {
	if($W) {
	    $METAFILE = $W->CreateEnhMetaFile("prova.emf");
	    print "CreateEnhMetaFile returned $DC\n";
	    Draw($METAFILE);
	    $META = Win32::GUI::CloseEnhMetaFile($METAFILE);
	    print "CloseEnhMetaFile returned $META\n";
	    $rc = Win32::GUI::DeleteEnhMetaFile($META);
	    print "DeleteEnhMetaFile returned $rc\n";
	    Draw($W->GetDC);
	}
}

sub Draw {
	my($DC) = @_;
    $X = $W->ScaleWidth;
    $Y = $W->ScaleHeight;
    $r = 0;
    $g = 0;
    $b = 0;
    if($X > 500) {
        $DC->MoveTo(0, $Y/2);
        $DC->LineTo($X, $Y/2);
        $r = 255;
    }
    if($Y > 500) {
        $DC->MoveTo(X/2, 0);
        $DC->LineTo($X/2, $Y);
        $g = 255;
    }
  
    $DC->LineTo(0, 0);
    $DC->LineTo($X, $Y);
    $DC->LineTo($X, 0);
    $DC->LineTo(0, $Y);
    $DC->Circle(0, 0, $X, $Y);
    $DC->SetTextColor($r, $g, $b);
    $DC->SetBkMode(1);
    ($TW, $TH) = $DC->GetTextExtentPoint32("$X x $Y");
    $DC->TextOut($X/2-$TW/2, $Y/2-$TH/2, "$X x $Y");
}
