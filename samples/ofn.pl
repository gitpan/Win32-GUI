

use Win32::GUI;

$file = "\0" . " " x 256;

$ret = GUI::GetOpenFileName(
    -title  => "Win32::GUI::GetOpenFileName test",
    -file   => "\0" . " " x 256,
    -filter => [
        "Text documents (*.txt)" => "*.txt", 
        "Perl stuff (*.pl, *.pm)" => "*.pl;*.pm", 
        "All files", "*.*",
    ],
);

if($ret) {
    print "GetOpenFileName returned: '$ret'\n";
} else {
    if(GUI::CommDlgExtendedError()) {
        print "ERROR. CommDlgExtendedError is: ", GUI::CommDlgExtendedError(), "\n";    
    } else {
        print "You cancelled.\n";
    }
}