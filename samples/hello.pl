##!perl -w
#
# Simple Win32::GUI script to create a button that prints "Hello, world".
# Click on the button to terminate the program.
#
# (rewritten from Tk's demos/hello)

#use Devel::Leak;
use Win32::GUI;
$MW = new Win32::GUI::Window(
    -title   => 'hello.pl',
    -left    => 100,
    -top     => 100,
    -width   => 150,
    -height  => 100,
    -name    => 'MainWindow',
    -visible => 1,
);
#print "MW=$MW\n";
#print "MW.handle=", $MW->{-handle}, "\n";
#my $count = Devel::Leak::NoteSV($MW);
#print "NoteSV.count = $count\n";
#print "MW=$MW\n";
$hello = $MW->AddButton(
    -text    => 'Hello, world',
    -name    => 'Hello',
    -left    => 25,
    -top     => 25,
);

$rc = Win32::GUI::Dialog(0);

# Devel::Leak::CheckSV($MW);

sub MainWindow_Terminate {
    $MW->PostQuitMessage(1);
    # return -1;
}

sub Hello_Click {
    if($MW->Hello->Text eq "Hello, world") {
        $MW->Hello->{-text} = "OneMoreTime";
    } else {
        print STDOUT "Hello, world\n";
        $MW->PostQuitMessage(0);
    }
}
