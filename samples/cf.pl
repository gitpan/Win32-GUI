

use Win32::GUI;

@ret = Win32::GUI::ChooseFont(
    -name => "Courier New", 
    -height => 14, 
    -size => 180,
    -italic => 1,
    -ttonly => 1,
    -fixedonly => 1,
    -script => 0,
    -effects => 1,
);

if($#ret > 0) {
    print "ChooseFont returned:\n";
    %ret = @ret;
    foreach $key (keys(%ret)) {
        print "\t$key => $ret{$key}\n";
    }

    $F = new Win32::GUI::Font(%ret);

    %ariret = $F->Info();

    print "Info returned:\n";

    foreach $key (keys(%ariret)) {
        print "\t$key => $ariret{$key}\n";
    }


} else {
    if(Win32::GUI::CommDlgExtendedError()) {
        print "ERROR. CommDlgExtendedError is: ", Win32::GUI::CommDlgExtendedError(), "\n";    
    } else {
        print "You cancelled.\n";
    }
}