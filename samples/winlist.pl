
use Win32::GUI;

foreach $ARG (@ARGV) {
    $all=1 if $ARG=~m|[-/]a|i;
    $min=1 if $ARG=~m|[-/]m|i;

    if($ARG =~ m|[-/]h|i) {
        $desktop = GUI::GetDesktopWindow();
        $window = GUI::GetWindow($desktop, GW_CHILD);
        while($window) {
            $title = GUI::Text($window);
            if(!GUI::IsVisible($window)) {
                printf("%16d: %s\n", $window, $title);
                GUI::Show($window) if $title =~ /emula/i;
            }
            $window = GUI::GetWindow($window, GW_HWNDNEXT);
        }  
        exit(0);
    }

}

$desktop = GUI::GetDesktopWindow();
print "Desktop Window: $desktop\n" if $all;

$window = GUI::GetWindow($desktop, GW_CHILD);
while($window) {
    $title = GUI::Text($window);
    if($all or ($title)) { # and GUI::IsVisible($window))) {
        printf("%16d: %s\n", $window, $title);
        GUI::Show($window, 6) if $min and $title ne "Program Manager";
    }
    $window = GUI::GetWindow($window, GW_HWNDNEXT);
    # print $window;
}  
