#!perl -w
use Win32::GUI;
use strict;

my $W = new GUI::Window(
    -title    => "Win32::GUI::TabStrip test",
    -left     => 100, 
    -top      => 100, 
    -width    => 300, 
    -height   => 200,
    -name     => "Window",
);

my $IL = new GUI::ImageList(16, 16, 8, 3, 10);
my $IMG_ONE   = $IL->Add("one.bmp");
my $IMG_TWO   = $IL->Add("two.bmp");
my $IMG_THREE = $IL->Add("three.bmp");

$W->AddTabStrip(
    -name   => "Tab",
    -left   => 0,   
    -top    => 0, 
    -width  => $W->ScaleWidth, 
    -height => $W->ScaleHeight,
    -imagelist => $IL,
);

$W->Tab->InsertItem(
    -text => "First", 
    -image => $IMG_ONE,
);
$W->Tab->InsertItem(
    -text => "Second", 
    -image => $IMG_TWO,
);
$W->Tab->InsertItem(
    -text => "Third",
    -image => $IMG_THREE,
);

$W->AddLabel(
    -name  => "Selection",
    -text  => "Click a tab...",
    -left  => 5,
    -top   => 50,
);

$W->Show;

$W->Dialog();

sub Window_Resize {
    $W->Tab->Resize($W->ScaleWidth, $W->ScaleHeight);
}

sub Tab_Click {
    my @tabs = ("First page", "Second page", "Third page");
    $W->Selection->Text($tabs[$W->Tab->SelectedItem()]);
}

