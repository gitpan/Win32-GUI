#!perl -w
use strict;
use Win32::GUI;

my $Window = new Win32::GUI::Window(
    -name   => "Window",
    -left   => 100,
    -top    => 100,
    -width  => 250,
    -height => 150,
    -title  => "Win32::GUI::Timer test",
);

$Window->AddLabel(
    -name   => "CurrentTime",
    -text   => scalar(localtime),
    -left   => 10,
    -top    => 10,
    -notify => 1,
    -align  => 'left',
);

my $BigFont = new Win32::GUI::Font(
    -name   => "Arial",
    -height => 25,
    -weight => 900,
);

$Window->AddLabel(
    -name   => "Dot",
    -text   => "-",
    -left   => 0,
    -top    => 50,
    -font   => $BigFont,
);

$Window->AddButton(
    -name   => "ToggleDot",
    -text   => "HI",
    -left   => 10,
    -top    => 75,
);
$Window->AddButton(
    -name   => "KillDot",
    -text   => "Stop",
    -left   => 80,
    -top    => 75,
);

my $Timer1 = $Window->AddTimer("Timer1", 1000);
my $Timer2 = $Window->AddTimer("Timer2", 10);

my $incr = 5;
my $x = 0;
$Window->Show();
Win32::GUI::Dialog();

sub Window_Terminate {
    return -1;
}

sub Timer1_Timer {
    $Window->CurrentTime->Text(scalar(localtime));
}

sub Timer2_Timer {
    $x += $incr;
    if($x > $Window->ScaleWidth) { $x = 0; }
    $Window->Dot->Move($x, 50);
}

sub ToggleDot_Click {
    if($Timer2->Interval == 10) {
    $Timer2->Interval(100);
    $incr = 1;
    $Window->ToggleDot->Text("LO");
    } else {
    $Timer2->Interval(10);
    $incr = 5;
    $Window->ToggleDot->Text("HI");
    }
}

sub KillDot_Click {
    if($Window->KillDot->Text eq "Stop") {
    $Timer2->Kill();
    $Window->ToggleDot->Disable();
    $Window->KillDot->Text("Go");
    } else {
    if($incr == 5) {
        $Timer2->Interval(10);
    } else {
        $Timer2->Interval(100);
    }
    $Window->ToggleDot->Enable();
    $Window->KillDot->Text("Stop");
    }
}

sub CurrentTime_Click {
    print "got!\n";
}
