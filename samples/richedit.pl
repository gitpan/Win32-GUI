
use Win32::GUI;

$Font = new Win32::GUI::Font(
    -name => "Courier New", 
    -height => 16,
);

$Menu = Win32::GUI::MakeMenu(
    "&File"    => "File",
    ">  &Load" => "FileLoad",
    ">  &Save" => "FileSave",
);

$Window = new Win32::GUI::Window(
    -name   => "Window",
    -text   => "Win32::GUI TEST - RichEdit",
    -width  => 500,
    -height => 400, 
    -left   => 100, 
    -top    => 100,
    -font   => $Font,
    -menu   => $Menu,
);


$Textbox = $Window->AddRichEdit(
    -name    => "Text",
    -text    => $text,
    -left    => 5, 
    -top     => 5,
    -width   => $Window->ScaleWidth-10, 
    -height  => $Window->ScaleHeight-10,
    -style   => WS_CHILD | WS_VISIBLE | WS_VSCROLL 
              | ES_LEFT | ES_MULTILINE | ES_AUTOVSCROLL,
    -exstyle => WS_EX_CLIENTEDGE,
);

$file = ($ARGV[0] or "richedit.t");
open(FILE, $file) or die "No file found $file\n";

while(<FILE>) {
    chomp;
    if(/^#/) {
        $Textbox->SetCharFormat(-color => hex("006400"));
    } else {
        $Textbox->SetCharFormat(-color => hex("000000"));
    }
    $Textbox->ReplaceSel($_."\r\n");
}
close(FILE);

$Window->Show();

Win32::GUI::Dialog();

sub Window_Resize {
    ($width, $height) = ($Window->GetClientRect)[2..3];
    $Textbox->Resize($width-10, $height-10);
}

sub FileSave_Click {
    $Textbox->Save("richedit.rtf");
}

sub FileLoad_Click {
    $Textbox->Load("richedit.rtf");
}

sub Window_Terminate {
    return -1;
}
