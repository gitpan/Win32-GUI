use Win32::GUI;

my $VERSION = "1.01";

my %output;

foreach ("handles", "titles", "classes", "sizes", "styles") {
    $output{$_} = 1;
}

print STDERR "Type '$0 -h' for help.\n";
print STDERR "Move the mouse over a window and press ENTER:";

my $enter = <STDIN>;
print "\n";

my ($x, $y) = Win32::GUI::GetCursorPos();
print "Window at ($x, $y):\n";
my $HWND = Win32::GUI::WindowFromPoint($x, $y);

Win32::GUI::Resize($HWND, $ARGV[0], $ARGV[1]);


#=================
sub GetClassName {
#=================
    my($hwnd) = @_;
    my $name = " " x 1024;
    my $nameLen = 1024;
    my $result = $GetClassName->Call($hwnd, $name, $nameLen);
    if($result) {
        return substr($name, 0, $result);
    } else {
        return "";
    }
}

#=================
sub GetCursorPos {
#=================
    my $POINT = pack("LL", 0, 0);
    $GetCursorPos->Call($POINT);
    return wantarray ? unpack("LL", $POINT) : $POINT;
}

#====================
sub WindowFromPoint {
#====================
    my($x, $y) = @_;
    my $POINT = pack("LL", $x, $y);
    return $WindowFromPoint->Call($x, $y);
}

#==================
sub GetWindowText {
#==================
    my($hwnd) = @_;
    my $title = " " x 1024;
    my $titleLen = 1024;
    my $result = $GetWindowText->Call($hwnd, $title, $titleLen);
    if($result) {
        return substr($title, 0, $result);
    } else {
        return "";
    }
}

#==================
sub GetWindowRect {
#==================
    my($hwnd) = @_;
    my $RECT = pack("iiii", 0, 0);
    $GetWindowRect->Call($hwnd, $RECT);
    return wantarray ? unpack("iiii", $RECT) : $RECT;
}

#==================
sub OutputWinInfo {
#==================
    my($HWND, $level) = @_;
#    print "OutputWinInfo.level = $level\n";
    print "\t" x $level;
    if($output{"handles"}) {
        if ($output{"hex"}) {
            printf("(%x) ", $HWND);
        } else {
            print "($HWND) ";
        }
    }
    if($output{"titles"}) {
        my $title = GetWindowText($HWND);
        print " \"$title\"" if $title;
    }
    print "\n";
    if($output{"classes"}) {
        my $class = GetClassName($HWND);
        print "\t" x $level;
        print "\tClass: $class\n" if $class;
    }
    if($output{"sizes"}) {
        my ($left, $top, $right, $bottom) = GetWindowRect($HWND);
        print "\t" x $level;
        print "\tPosition: ($left, $top)\n";
        my $width = $right-$left;
        my $height = $bottom-$top;
        print "\t" x $level;
        print "\tSize: ($width x $height)\n";
    }
    if($output{"styles"}) {
        my $style = $GetWindowLong->Call($HWND, -16);
        print "\t" x $level;
        printf("\tStyle: %X\n", $style);
        my $exstyle = $GetWindowLong->Call($HWND, -20);
        print "\t" x $level;
        printf("\tExtended Style: %X\n", $exstyle);
    }
}

#===============
sub FindChilds {
#===============
    my($parent, $hwnd, $level) = @_;
    my $Child;
    my $NextChild;
    my $left;
    my $right;
    my $top;
    my $bottom;
    my $height;
    my $width;
    my $class;
    my $text;
    my $style;
    my $args;
    my $child;
    my $header;

    $Child = $GetWindow->Call($hwnd, 5);
    $level++;
    $header = "\t" x $level."Child windows:\n";
    while($Child != 0) {
        if($header) {
            print $header;
            undef $header;
        }
        OutputWinInfo($Child, $level);
        FindChilds(\$child, $Child, $level);
        $NextChild = $GetWindow->Call($Child, 2);
        $Child = $NextChild;
    }
}


#=========
sub help {
#=========
    print <<END_OF_HELP;

WinInfo version $VERSION
by Aldo Calpini <dada\@divinf.it>

Usage: perl $0 [options]

Options:
    -o:[flags]: output the following informations:
        h: window handles
        t: window titles
        c: window classes
        s: window sizes
        y: window styles
        Default is '-o:htcsy' (all of them)

    -r: recurse child windows       

    -x: show handles in hexadecimal format

END_OF_HELP
}