
use Win32::GUI;

$M = new Win32::GUI::Menu(
	"&Orientation"   => "Orientation",
	" > &Horizontal" => "Horizontal",
	" > &Vertical"   => { -name => "Vertical", -checked => 1 },
);

$W = new Win32::GUI::Window(
    -title    => "Win32::GUI::Splitter test",
    -pos      => [ 100, 100 ],
    -size     => [ 400, 150 ],
    -name     => "Window",
	-menu     => $M,
);


$W->AddSplitter(
    -name   => "Splitter",
	-pos    => [ $W->ScaleWidth/2-2, 0 ],
	-size   => [ 4, $W->ScaleHeight ],
	-horizontal => 0,
);

$W->Splitter->{-min} = 50;
$W->Splitter->{-max} = 350;

$W->AddLabel(
	-name => "LabelLeft",
	-pos  => [0, 0],
	-size => [ $W->ScaleWidth/2-2, $W->ScaleHeight ],
	-text => "LEFT",
        -background => "#FF5201",
);

$W->AddLabel(
	-name => "LabelRite",
	-pos  => [ $W->ScaleWidth/2+2, 0 ],
	-size => [ $W->ScaleWidth/2-2, $W->ScaleHeight ],
	-text => "RIGHT",
        -background => "#78FFFF",
);

$W->Show();

Win32::GUI::Dialog();

sub Window_Terminate {
    return -1;
}

sub Header_BeginTrack {
    print "got BeginTrack\n";
}

sub Header_EndTrack {
    print "got EndTrack\n";
}

sub Splitter_Release {
	print "Splitter released at: $_[0]\n";
	if($W->Splitter->{-horizontal}) {
		$W->LabelLeft->Resize($W->LabelLeft->Width, $_[0]);
		$W->LabelRite->Move(0, $_[0]+4);
		$W->LabelRite->Resize($W->LabelRite->Width, $W->ScaleHeight-$_[0]-2);
	} else {
		$W->LabelLeft->Resize($_[0], $W->LabelLeft->Height);
		$W->LabelRite->Move($_[0]+4, 0);
		$W->LabelRite->Resize($W->ScaleWidth-$_[0]-2, $W->LabelRite->Height);
	}
	$W->InvalidateRect(1);
}


sub Horizontal_Click {
	$M->{Horizontal}->Checked(not $M->{Horizontal}->Checked);
	$M->{Vertical}->Checked(not $M->{Vertical}->Checked);
	Win32::GUI::DestroyWindow($W->Splitter);
	undef $W->{Splitter};
	$W->AddSplitter(
		-name   => "Splitter",
		-left   => 0,
		-top    => $W->ScaleHeight/2-2,
		-width  => $W->ScaleWidth,
		-height => 4,
		-horizontal => 1,
	);
	$W->LabelLeft->Text( "UP" );
	$W->LabelRite->Text( "DOWN" );
	$W->LabelLeft->Width( $W->ScaleWidth );
	$W->LabelRite->Width( $W->ScaleWidth );
	Splitter_Release($W->ScaleHeight/2-2);
}

sub Vertical_Click {
	$M->{Horizontal}->Checked(not $M->{Horizontal}->Checked);
	$M->{Vertical}->Checked(not $M->{Vertical}->Checked);
	Win32::GUI::DestroyWindow($W->Splitter);
	undef $W->{Splitter};
	$W->AddSplitter(
		-name   => "Splitter",
		-text   => "Helluva!",
		-left   => $W->ScaleWidth/2-2,
		-top    => 0,
		-width  => 4,
		-height => $W->ScaleHeight,
		-horizontal => 0,
	);
	$W->LabelLeft->Text( "LEFT" );
	$W->LabelRite->Text( "RIGHT" );
	$W->LabelLeft->Height( $W->ScaleHeight );
	$W->LabelRite->Height( $W->ScaleHeight );
	Splitter_Release($W->ScaleWidth/2-2);
}
