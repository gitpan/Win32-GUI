
use Win32::GUI;

@tics = (
    "nothing",
    "almost nothing",
    "something more than nothing",
    "very few",
    "few",
    "so and so",
    "much",
    "very much",
    "more than much",
    "almost everything",
    "everything",
);
  

$Window = new GUI::Window(
    -title    => "Win32::GUI::Slider test",
    -left     => 100, 
    -top      => 100, 
    -width    => 300, 
    -height   => 100,
    -name     => "Window",
);

$Window->AddSlider(
    -left   => 10,
    -top    => 10,
    -height => 150,
    -width  => 150,
    -name   => "Slider",
);
                                 
$Window->AddLabel(
    -name  => "Label",
    -left  => 10,
    -top   => 50,
    -width => 250,
    -text  => "this is a placeholder",
);

$Window->Slider->Min(0);
$Window->Slider->Max(10);
$Window->Slider->Pos(0);

Slider_Scroll();

$Window->Show;

Win32::GUI::Dialog();

sub Window_Terminate {
    return -1;
}

sub Slider_Scroll {
    $Window->Label->Text(
        $Window->Slider->Pos ."/". $Window->Slider->Max ." ".
        $tics[$Window->Slider->Pos]);
}
