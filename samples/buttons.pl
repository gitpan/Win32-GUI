
use Win32::GUI;

$F = new Win32::GUI::Font(
	-name => "Arial",
	-size => 14,
	-bold => 1,
);

$W = new Win32::GUI::Window(
    -title  => "Win32::GUI::Button (and variants) test",
    -left   => 100, 
    -top    => 100, 
    -width  => 280, 
    -height => 260,
    -name   => "Window",
	-font   => $F,
);

$W->{-dialogui} = 1;

$W->AddButton(
    -name    => "Simple",
    -left    => 5,
    -top     => 5,
	-text    => "Click button",
	-tabstop => 1,
);

$Timer = $W->AddTimer("SimpleTimer", 0);

$W->AddLabel(
	-name   => "SimpleLabel",
	-left   => 120,
	-top    => 10,
	-width  => 150,
	-height => 22,
);

$W->AddGroupbox(
	-name   => "CheckGroup",
	-left   => 2,
	-top    => 35,
	-width  => 115,
	-height => 85,
	-text   => "Checkboxes",
);

$W->AddCheckbox(
    -name    => "Check1",
    -left    => 8,
    -top     => 50,
	-text    => "Checkbox 1",
	-tabstop => 1,
);

$W->AddCheckbox(
    -name    => "Check2",
    -left    => 8,
    -top     => 70,
	-text    => "Checkbox 2",
	-tabstop => 1,
);

$W->AddCheckbox(
    -name    => "Check3",
    -left    => 8,
    -top     => 90,
	-text    => "Checkbox 3",
	-tabstop => 1,
);

$W->AddLabel(
	-name   => "CheckLabel",
	-left   => 120,
	-top    => 55,
	-width  => 150,
	-height => 44,
);

$W->AddGroupbox(
	-name   => "RadioGroup",
	-left   => 2,
	-top    => 120,
	-width  => 115,
	-height => 85,
	-text   => "Radiobuttons",
);

$W->AddRadioButton(
    -name    => "Radio1",
    -left    => 8,
    -top     => 135,
	-text    => "Radiobutton 1",
	-tabstop => 1,
);

$W->AddRadioButton(
    -name    => "Radio2",
    -left    => 8,
    -top     => 155,
	-text    => "Radiobutton 2",
	-tabstop => 1,
);

$W->AddRadioButton(
    -name    => "Radio3",
    -left    => 8,
    -top     => 175,
	-text    => "Radiobutton 3",
	-tabstop => 1,
);

$W->AddLabel(
	-name   => "RadioLabel",
	-left   => 120,
	-top    => 140,
	-width  => 150,
	-height => 22,
);

$W->AddButton(
	-name    => "Close",
	-left    => 150, 
	-top     => 210, 
	-width   => 100,
	-text    => "Close", 
	-cancel  => 1,
	-default => 1,
	-tabstop => 1,
);

$W->Show;

Win32::GUI::Dialog();

sub Window_Terminate {
    return -1;
}

sub Close_Click {
    Window_Terminate();
}

sub Simple_Click {
	$W->SimpleLabel->Text("Got a click");
	$Timer->Interval(1000);
}

sub SimpleTimer_Timer {
	$W->SimpleLabel->Text("");
	$Timer->Kill();
}

sub Check1_Click {
	my $text = "";
	if($W->Check1->Checked()) {
		$text .= (($text)? ", " : "")."Checkbox 1";
	}
	if($W->Check2->Checked()) {
		$text .= (($text)? ", " : "")."Checkbox 2";
	}
	if($W->Check3->Checked()) {
		$text .= (($text)? ", " : "")."Checkbox 3";
	}
	$W->CheckLabel->Text($text);
}
sub Check2_Click { Check1_Click(); }
sub Check3_Click { Check1_Click(); }


sub Radio1_Click {
	my $text = "";
	if($W->Radio1->Checked()) {
		$text = "Radiobutton 1";
	} elsif($W->Radio2->Checked()) {
		$text = "Radiobutton 2";
	} elsif($W->Radio3->Checked()) {
		$text = "Radiobutton 3";
	}
	$W->RadioLabel->Text($text);
}
sub Radio2_Click { Radio1_Click(); }
sub Radio3_Click { Radio1_Click(); }
