#!perl -w
use strict;

my $file = shift or die "No file specified";

my $twip = shift;

frm2pl($file, $twip);

sub frm2pl {
    my($file, $twip) = @_;
    my $doing = "nothing";
    my @words;
    my ($one, $two, $three);
    my $FormName;
    my $LINE;
    $twip = 15 unless $twip;
    
    print "\nuse Win32::GUI;\n\n";

    if(open(FRM, $file)) {
        while($LINE = <FRM>) {
            chomp $LINE;
            $LINE =~ s/^\s*//;
            $LINE =~ s/\s*$//;
            ($one, $two, $three) = split(/\s+/, $LINE, 3);
            if($one =~ /^BEGIN$/i) {
                if($two =~ /^VB\.FORM$/i) {
                    $FormName = $three;
                    print "\$$FormName = new Win32::GUI::Window(\n";
                    print "\t-name => \"$FormName\",\n";            
                    $doing = "form";
                } elsif($two =~ /^VB\.COMMANDBUTTON$/i) {
                    print_ctl("Button");
                } elsif($two =~ /^VB\.TEXTBOX$/i) {
                    print_ctl("Textfield");
                } elsif($two =~ /^VB\.CHECKBOX$/i) {
                    print_ctl("Checkbox");
                } elsif($two =~ /^VB\.LABEL$/i) {
                    print_ctl("Label");
                } elsif($two =~ /^VB\.LISTBOX$/i) {
                    print_ctl("Listbox");
                } elsif($two =~ /^VB\.OPTIONBUTTON$/i) {
                    print_ctl("RadioButton");
                } elsif($two =~ /^COMCTLLIB\.TREEVIEW$/i) {
                    print_ctl("TreeView");
                } elsif($two =~ /^COMCTLLIB\.IMAGELIST/i) {
                    print_ctl("ImageList");
                } elsif($two =~ /^COMCTLLIB\.STATUSBAR/i) {
                    print_ctl("StatusBar");
                } else {
                    print ");\n" if $doing ne "nothing";
                    $doing = "nothing";
                }
            } else {
                if($doing ne "nothing") {
                    if($one =~ /^END$/i) {
                        print ");\n";
                        $doing = "nothing";
                    } elsif(index("_LEFTTOPWIDTHHEIGHT", uc($one)) > 0 and $two eq "=") {
                        print "\t-", lc($one), " => ", int($three / $twip), ",\n";
                    } elsif(index("_VISIBLE", uc($one)) > 0 and $two eq "=") {
                        print "\t-visible => ", $three, ",\n";
                    } elsif(uc($one) eq "CAPTION" and $two eq "=") {
                        print "\t-text => quoteforperl((split(/\s*=\s*/, $LINE, 2))[1]),\n";
                    }
                }
            }

        }
        close(FRM);
        if($FormName) {
            print "\n\$$FormName->Show;\n";
            print "Win32::GUI::Dialog();\n\n";
        }

        print <<_END_;

sub ${FormName}_Terminate {
    return -1;
}

_END_

    } else {
        warn "Can't open file $file: $!\n";
        return 0;
    }
    return 1;

sub print_ctl {
    my($ctl) = @_;
    print ");\n" if $doing eq "form";
    print "\$three = \$$FormName->Add$ctl(\n";
    print "\t-name => \"$three\",\n";
    $doing = $ctl;
}


}

sub quoteforperl {
    my($what) = @_;
    $what =~ s/\$/\\\$/g;
    $what =~ s/\@/\\\@/g;
    $what =~ s/\%/\\\%/g;
    return $what;
}


