
use Win32::GUI;

$I = new Win32::GUI::Icon("camel.ico");
$C = new Win32::GUI::Bitmap("harrow.cur", 2);

# NOTE: $C should be Win32::GUI::Cursor...

$WC = new Win32::GUI::Class(
    -name => "simply_perl_win32_gui", 
    -cursor => $C,
    -icon => $I,
    -color => 2,
);
if(!$WC) {
    die "Window class creation error: ", Win32::GetLastError(), "\n";
}
$W = new Win32::GUI::Window(
    -name => "Window",
    -font => $F,
    -title => "Win32::GUI::Class test",
    -class => $WC,
    -left => 100, 
    -top => 100,
    -width => 300, 
    -height => 200,
);
if(!$W) {
    die "Window creation error: ", Win32::GetLastError(), "\n";
}
$W->Show();
$W->Dialog();
