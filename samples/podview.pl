
use Win32::GUI;
use Win32::Registry;
# use Win32::API;
use lib "p:\\dada\\win32-gui\\samples";
use Pod::RTF;
use FindBin;

$VERSION = "1.30";
$DEBUG = 0;

$NORMAL = Win32::GUI::LoadCursorFromFile("arrow_1.cur");
$HAND = Win32::GUI::LoadCursorFromFile("harrow.cur");

Win32::GUI::SetCursor($NORMAL);

# Minimize the Perl's DOS window
($DOShwnd, $DOShinstance) = Win32::GUI::GetPerlWindow();
#Win32::GUI::CloseWindow($DOShwnd);

# you can eventually...
Win32::GUI::Hide($DOShwnd);

$MRUMAX = 9;

ReadConfig();

@MRUDEF = ();
for $i (1..$MRUMAX) {
    push(@MRUDEF, " > \&$i $MRU{$i}");
    push(@MRUDEF, "MenuMRU$i");
    $subname = "MenuMRU${i}_Click";
    *$subname = eval(qq(
        sub {
            LoadPod(\$MRU{$i}) if \$MRU{$i};
        } 
    )); 
}


$Menu = new Win32::GUI::Menu(
    "&File" => "File",
    "   >   &Open" => "MenuOpen",
    "   >   &Reload" => "MenuReload",
    "   >   &Save RTF" => "MenuSave",
    "   >   -" => 0,
    @MRUDEF,
    "   >   -" => 0,
    "   >   E&xit" => "MenuExit",

    "&View" => "View",
    "   >   Pod s&tructure" => { 
        -name => "ViewStructure", 
        -checked => 1 
    },
    "   >   Structure &depth..." => "ViewDepth",
    "   >   &Source" => "ViewSource",

    "&Tools" => "Tools",
    "   >   E&xplore Perl modules..." => "ToolPmx",

    "&Options" => "Options",
    "   >   Choose &normal font..." => "MenuNormalFont",
    "   >   Choose &fixed font..." => "MenuFixedFont",
    "   >   Choose &heads color..." => "MenuHeadColor",
    "   >   Choose &links color..." => "MenuLinkColor",
    "   >   -", => 0,
    "   >   &Save options" => "MenuSaveConfig",
);


$Window = new Win32::GUI::Window(
    -name => "Window",
    -text => "Perl POD Viewer",
    -width => 640, -height => 480, 
    -left => 100,  -top => 100,
    -menu => $Menu,
);

$Window->AddHeader(
    -name => "Header",
    -left => 0,
    -top  => 0,
    -width => $Window->ScaleWidth/3,
    -height => $Window->ScaleHeight,
);
$Window->Header->InsertItem(
    -index => 0,
    -text => "Structure",
    -width => $Window->ScaleWidth/3,
);

$REC = new Win32::GUI::Class(
    -name => "PodView_RichEdit",
    -extends => "RichEdit",
    -widget => "RichEdit",
);

$POD = $Window->AddRichEdit(
    -name => "POD",
    # -class => $REC, # still testing this...
    -text => "",
    -left => 10, 
    -top => 10,
    -width => 280/3*2, 
    -height => 180,
    -exstyle => WS_EX_CLIENTEDGE,
    -style => WS_CHILD | WS_VISIBLE | WS_VSCROLL 
            | ES_LEFT | ES_MULTILINE | ES_AUTOVSCROLL,
);

$Window->AddTreeView(
    -name => "TOC",
    -text => "",
    -left => 10, 
    -top => 10,
    -width => 280/3, 
    -height => 180,
    -exstyle => WS_EX_CLIENTEDGE,
    -style => WS_CHILD | WS_VISIBLE | WS_VSCROLL 
            | ES_LEFT | ES_MULTILINE | ES_AUTOVSCROLL,
    -lines => 1,
    -rootlines => 1,
    -hottrack => 1,
);

$Window->AddStatusBar(
    -name => "Status",
    -text => "PodView $VERSION Ready"
);

new GUI::ProgressBar(
    $Window->Status,
    -name   => "Progress",
    -width  => 150,
    -height => $Window->Status->Height-3,
    -left   => $Window->Status->Width-150,
    -top    => 2,
);

$NoPOD = $Window->AddLabel( 
    -text    => "No POD found in file.",
    -name    => "NoPOD",
    -visible => 0,
);

LoadPod($ARGV[0] or $0);

$Window->Show();
$Window->Show(); # twice to avoid being preset by a 'start minimized' shortcut

Win32::GUI::Dialog();

# Restore the DOS window 
GUI::Show($DOShwnd);


######################################################################
# SUBROUTINES
#

sub rgb {
    my($color) = @_;
    $color = sprintf("%06X", $color);
    $color =~ /(..)(..)(..)/;
    return hex($3), hex($2), hex($1);
}

sub LoadPod {
    my $ticks = Win32::GetTickCount();
    my($file, $blind) = @_;
    $POD->SetRedraw(0);
    $file = $PODFILE unless $file;
    $Window->Status->Text("Loading $file...");
    $Window->Status->Update;
    Pod::RTF::set_head_color(rgb($HEAD_COLOR));
    Pod::RTF::set_link_color(rgb($L_COLOR));
    if(-f $file) {
        if(open(TMP, ">podview.rtf")) {
            binmode(TMP);
            @Pod::RTF::heads = ();
            Pod::RTF::pod2rtf($file, *TMP);
            close(TMP);
            $POD->Load("podview.rtf");
            unlink("podview.rtf");
            if(length($POD->Text) > 1) {
                $Window->POD->Show;
                if($Menu->{ViewStructure}->Checked) {
                    $Window->Header->Show;
                    $Window->TOC->Show;
                }
                $Window->NoPOD->Hide;
                my $elapsed = Win32::GetTickCount();
                $elapsed -= $ticks;
                $Window->Status->Text("$file loaded in " . ($elapsed/1000) . " seconds.");
                # $SHAddToRecentDocs->Call(2, $file);
                
                my($lvl, $pos); 
                my %lastnode = ();
                my %itemdata = ();
                %TOCRef = ();
                $TOC_CanExpand = 1;
                $Window->TOC->Clear();
                for (@Pod::RTF::heads) {
                    %itemdata = ();
                    ($lvl, $pos, $itemdata{-text}) = split(/;/);
                    # printf "%3d. (%d) %-30s\n", $lvl, $pos, $itemdata{-text} if $lvl > $MAX_STRUCT_LEVEL;
                    next if $lvl > $MAX_STRUCT_LEVEL;
                    $itemdata{-text} =~ s/\{\S+ ([^}]*)\}/$1/g;
                    if($lastnode{$lvl-1}) { 
                        # print "node has a parent at level ", $lvl-1, ": $lastnode{$lvl-1}\n";
                        $itemdata{-parent} = $lastnode{$lvl-1};
                    }
                    $itemdata{-item} = $lastnode{$lvl};
                    $lastnode{$lvl} = $Window->TOC->InsertItem(
                        %itemdata,
                        # -text => $name,
                        # -parent => $parent,
                        # -item => $lastnode{$lvl},
                    );
                    $TOCRef{$lastnode{$lvl}} = $pos;
                    $Window->TOC->Expand($itemdata{-parent}) if exists($itemdata{-parent});
                    # print $_,"\n";
                }
                $TOC_CanExpand = 0;
            } else {
                $Window->Status->Text("PodView $VERSION Ready");
                $Window->POD->Hide;
                $Window->Header->Hide;
                $Window->TOC->Hide;
                $Window->NoPOD->Show;
            }
        } else {
            Win32::GUI::MessageBox("Can't create temporary file!\n");
            $Window->Status->Text("PodView $VERSION Ready");
        }
        $PODFILE = $file;
        $POD->SetFocus();
        if(not $blind) {
            $POD->SetRedraw(1);
            $POD->InvalidateRect(1);
            #$POD->Update;
        }
        return length($Window->POD->Text);
    } else {
        Win32::GUI::MessageBox($dummy, "Can't open file '$file'\n");
        $Window->Status->Text("PodView $VERSION Ready");
        if(not $blind) {
            $POD->SetRedraw(1);
            $POD->InvalidateRect(1);
            #$POD->Update;
        }
        return 0;
    }
}

# not used, see Pod::RTF
sub OldLoadPod {
    my $ticks = Win32::GetTickCount();
    my($file) = @_;
    $file = $PODFILE unless $file;
    $size = -s $file;

    $NoPOD->Hide;
    $Window->POD->Show;
	$Window->Header->Show;
	$Window->TOC->Show;
    $POD->Update;

    undef %normal;
    $normal{-autocolor} = 1;
    $normal{-height} = 240;
    $normal{-name} = $NORMAL_FONT_NAME;
    $normal{-bold} = 0;
    $normal{-italic} = 0;
    $normal{-underline} = 0;

    if(open(FILE, $file)) {

        # clear the text box and don't update it
        $POD->Text("");
        $POD->SetRedraw(0);

        # starts with normal format
        $POD->SendMessage(177, -1, 0);
        $POD->SetCharFormat(%normal);

        $Window->Status->Progress->SetPos(0);
        $Window->Status->Progress->Show;
        $Window->Status->Text("Loading $file...");
        $Window->Status->Update;

        $podfound = 0;
        $pod = 0;
        while(<FILE>) {
            next unless($pod or /^=head(\d)/);
            chomp;
            if($pod == 0) {
                # print "OUTSIDE POD\n";
                if(/^=head(\d)\s+(.*)$/) {
                    $n = $1;
                    $name = $2;
                    $pod = 1;
                    $podfound = 1;
                    undef %format;
                    $format{-color} = $HEAD_COLOR;
                    $format{-height} = 240+(7-$n)*20;
                    $format{-bold} = 1 if $n == 1;
                    PodAddText($name, %format);
                    # $POD->SendMessage(177, -1, 0);            
                    # $POD->SetCharFormat(%format);
                    # $POD->ReplaceSel($name);
                    # print ">!> $name\n";
                    $POD->SendMessage(177, -1, 0);
                    $POD->SetCharFormat(%normal);
                }
            } else {
                if(/^$/) {
                    if($over and not $item) {
                        # undef $atext;
                        # $atext = $POD->Text();
                        # $parastart = rindex($atext, "\n", length($atext)-1)+1;
                        # $POD->SendMessage(177, $parastart, length($atext)+2);
                        # print "--- Indenting ($parastart, ", length($atext)+2, "):\n", join("\n", split(/[\r\n]+/, substr($atext, $parastart, length($atext)+2))), "\n";

                        $POD->SendMessage(177, $para, length($POD->Text));

                        undef %format;
                        $format{-offset} = 0;
                        $format{-startindent} = $over*100;
                        $POD->SetParaFormat(%format);
                    }
                    $POD->SendMessage(177, -1, 0);                
                    if(!$item) {
                        $POD->ReplaceSel("\r\n\r\n");
                    } else {
                        $POD->ReplaceSel("\r\n");
                    }
                    $POD->SendMessage(177, -1, 0);                
                    $item = 0;
                } elsif(/^=cut/) {
                    $pod = 0;
                } elsif(/^=head(\d)\s+(.*)$/) {
                    $n = $1;
                    $name = $2;
                    undef %format;
                    $format{-color} = $HEAD_COLOR;
                    $format{-height} = 240+(7-$n)*20;
                    $format{-bold} = 1 if $n == 1;
                    # $POD->SendMessage(177, -1, 0);
                    # $POD->SetCharFormat(%format);
                    # $POD->SendMessage(177, -1, 0);
                    # $POD->ReplaceSel($name);
                    PodAddText($name, %format);
                    $POD->SendMessage(177, -1, 0);
                    $POD->SetCharFormat(%normal);
                    # print ">!> $name\n";
                } elsif(/^=over\s*(\d*)/) {
                    $over = ($1 or 4);
                    #undef %format;
                    #$format{-offset} = $over*100;
                    #$format{-startindent} = $over*100;
                    #$POD->SetParaFormat(%format);
                    #print "Paraformatting ", $n*100, "\n";
                    $item = 1;
                    # print "got over=$over, item=$item\n";
                    $para = length($POD->Text);
                } elsif(/^=back/) {
                    # print "got back\n";
                    undef %format;
                    $format{-offset} = 0;
                    $format{-startindent} = 0;
                    $POD->SetParaFormat(%format);
                    $over = 0;
                    $item = 0;
                } elsif(/^=item\s*(.*)$/) {
                    $item = $1;
                    if($item) {
                        undef %format;
                        $format{-bold} = 1;
                        $pitem = PodAddText($item, %format);
                        $atext = $POD->Text();
                        $POD->SendMessage(177, length($atext)-length($pitem), length($atext)+2);
                        undef %format;
                        $format{-offset} = 0;
                        $format{-startindent} = 0;
                        $POD->SetParaFormat(%format);
                        $POD->SendMessage(177, -1, 0);
                        # $POD->SendMessage(183, 0, 0);
                        $POD->SetCharFormat(%normal);
                    }
                    $item = 1;
                } elsif(/^\s+/) {
                    undef %format;
                    $format{-name} = $FIXED_FONT_NAME;
                    $format{-height} = 200;
                    $POD->SendMessage(177, -1, 0);
                    $POD->SetCharFormat(%format);
                    $POD->ReplaceSel($_."\r\n");
                    $POD->SendMessage(177, -1, 0);
                    $POD->SetCharFormat(%normal);
                    $item = 0;
                    # $para = length($POD->Text);
                } else {
                    $atext = $POD->Text();
                    $POD->SendMessage(177, -1, 0);
                    $POD->ReplaceSel(" ") unless $atext =~ /\s$/;
                    PodAddText($_, %normal);
                    $item = 0;
                }
            }
            $Window->Status->Progress->SetPos(tell(FILE)*100/$size);
            $Window->Status->Progress->Update;
        }
        close(FILE);

        $Window->Status->Progress->Hide;

        $POD->SetCharFormat(%normal);
        $POD->SendMessage(177, 1, 2);
        $POD->SendMessage(177, -1, 1);
        
        # repaint the text box
        if(not $blind) {
            $POD->SetRedraw(1);
            $POD->InvalidateRect(1);
            #$POD->Update;
        }
        
        $Window->Caption("Perl POD Viewer - $file");
        $PODFILE = $file;
        
        my $elapsed = Win32::GetTickCount();
        $elapsed -= $ticks;
        $Window->Status->Text("$file loaded in " . ($elapsed/1000) . " seconds.");
    } else {
        Win32::GUI::MessageBox("Cant open file '$file'\n");
    }        
    if(not $podfound) {
        $Window->POD->Hide;
		$Window->TOC->Hide;
		$Window->Header->Hide;
        $NoPOD->Show;
    }
}

sub PodAddText {
    my($text, %origformat) = @_;
    my($before, $after, $podcmd, $inside);
    my %format;
    my $parsedtext = "";
    while ($text =~ /^(.*?)([BICFL])<([^>]*)>(.*)$/) {
        $before = $1;
        $podcmd = $2;
        $inside = $3;
        $after  = $4;
        # print "Adding:\n\t$before\n";
        $POD->SendMessage(177, -1, 0);
        $POD->SetCharFormat(%origformat);
        $POD->ReplaceSel($before);
        $parsedtext .= $before;
        %format = %origformat;
        $format{-bold} = 1 if $podcmd eq "B";
        $format{-italic} = 1 if $podcmd eq "I";
        if($podcmd eq "C" or $podcmd eq "F") {
            $format{-name} = $FIXED_FONT_NAME;
            # $format{-height} = 200 unless $format{-height};
            #if($format{-height}) {
            #    $format{-height} -= 40; # ???
            #} else {
            #    $format{-height} = 200;
            #}
        }
        if($podcmd eq "L") {
            $format{-color} = $L_COLOR;
            $format{-autocolor} = 0;
            $format{-underline} = 1;
        }
        $POD->SendMessage(177, -1, 0);
        $POD->SetCharFormat(%format);
        $POD->SendMessage(177, -1, 0);
        $POD->ReplaceSel($inside);
        #print "adding ($inside) with: \n";
        #foreach $k (keys(%format)) {
        #    print "\t$k=$format{$k}\n";
        #}
        
        $parsedtext .= $inside;
        # print "Adding($podcmd):\n\t$inside\n";
        $POD->SendMessage(177, -1, 0);
        $POD->SetCharFormat(%normal);
        $text = $after;
    }
    $POD->SendMessage(177, -1, 0);
    $POD->SetCharFormat(%origformat);
    $POD->ReplaceSel($text);
    $parsedtext .= $text;
    return $parsedtext;
}    

sub ReadConfig {
    my $key;
    $HKEY_LOCAL_MACHINE->Open("SOFTWARE\\dada", $key)
    or 
    $HKEY_LOCAL_MACHINE->Create("SOFTWARE\\dada", $key);
    $key->Close();
    undef $key;
    $HKEY_LOCAL_MACHINE->Open("SOFTWARE\\dada\\PodView", $key)
    or 
    $HKEY_LOCAL_MACHINE->Create("SOFTWARE\\dada\\PodView", $key);
    if($key) {
        my($val, $name);
        $key->GetValues($val);
        
        #foreach $name (keys %$val) {
        #    print "\t$name = $val->{$name}[2]\n";
        #}
        
        $L_COLOR = $val->{'L_COLOR'}[2];
        $HEAD_COLOR = $val->{'HEAD_COLOR'}[2];
        $NORMAL_FONT_NAME = $val->{'NORMAL_FONT_NAME'}[2];
        $FIXED_FONT_NAME = $val->{'FIXED_FONT_NAME'}[2];
        $MAX_STRUCT_LEVEL = $val->{'MAX_STRUCT_LEVEL'}[2];

        for $i (1..$MRUMAX) {
            $MRU{$i} = $val->{'MRU'.$i}[2];
            $MRU{$i} =~ s/\0//g;

            # there are still some problems with SetMenuItemInfo()

            # $MRU{$i} = "ciao mamma";
            # print "Setting MenuMRU$i to \&$i $MRU{$i}\n";
            # print "MenuMRU$i = ", $Menu->{'MenuMRU'.$i}, "\n";
            # $Menu->{'MenuMRU'.$i}->SetMenuItemInfo(-text => "\&$i ".$MRU{$i});
            # $Menu->{'MenuMRU'.$i}->SetMenuItemInfo(-text => $MRU{$i});
        }

        DefaultConfig($key);
        $key->Close();
    } else {
        DefaultConfig();
    }        

    # $SHAddToRecentDocs = new Win32::API("shell32", "SHAddToRecentDocs", [N, P], N);

}

sub DefaultConfig {
    my($key) = @_;
    
    if(!$L_COLOR) {
        $L_COLOR = hex("FF0000");
        $key->SetValueEx("L_COLOR", 0, REG_SZ, $L_COLOR) if $key;
    }
    if(!$HEAD_COLOR) {
        $HEAD_COLOR = hex("008000");
        $key->SetValueEx("HEAD_COLOR", 0, REG_SZ, $HEAD_COLOR) if $key;
    }
    if(!$NORMAL_FONT_NAME) {
        $NORMAL_FONT_NAME = "Times New Roman";
        $key->SetValueEx("NORMAL_FONT_NAME", 0, REG_SZ, $NORMAL_FONT_NAME) if $key;
    }
    if(!$FIXED_FONT_NAME) {
        $FIXED_FONT_NAME = "Courier New";
        $key->SetValueEx("FIXED_FONT_NAME", 0, REG_SZ, $FIXED_FONT_NAME) if $key;
    }
    if(!$MAX_STRUCT_LEVEL) {
        $MAX_STRUCT_LEVEL = "2";
        $key->SetValueEx("MAX_STRUCT_LEVEL", 0, REG_SZ, $MAX_STRUCT_LEVEL) if $key;
    }
}

sub AddToMRU {
    my($file) = @_;
    my $key;

    foreach $k (keys %MRU) {
        return if $MRU{$k} eq $file;
    }

    for $i (reverse 2..$MRUMAX) {
        $MRU{$i} = $MRU{$i-1};
    }
    $MRU{1} = $file;
    WriteMRU();    
}

sub WriteMRU {
    my $key;
    my $U;
    $HKEY_LOCAL_MACHINE->Open("SOFTWARE\\dada", $key)
    or 
    $HKEY_LOCAL_MACHINE->Create("SOFTWARE\\dada", $key);
    $key->Close();
    undef $key;
    $HKEY_LOCAL_MACHINE->Open("SOFTWARE\\dada\\PodView", $key)
    or 
    $HKEY_LOCAL_MACHINE->Create("SOFTWARE\\dada\\PodView", $key);
    if($key) {
        foreach $U (1..$MRUMAX) {
            $key->SetValueEx("MRU$U", 0, REG_SZ, $MRU{$U});
            $Menu->{'MenuMRU'.$U}->Change(
                -text => "&$U ".$MRU{$U}
            );
        }
        $key->Close();
    }        
    return 1;
}
    

sub SearchHead {
    my($pos, $where, $headwanted) = @_;
    my $opos = $pos;
    my $found = 0;  
    my %format = ();
    my $stop = 0;
    my $another = 0;
    my $max_another = 3;
    if($where > 0) { 
        $stop = length($Window->POD->Text()); 
    }
    while(not $found) {
        $pos += $where;
        $found = 2 if $stop == 0 and $pos == 0;
        $found = 2 if $stop > 0 and $pos == $stop;      
        $Window->POD->Select($pos, $pos);
        %format = $Window->POD->GetCharFormat(1);
        #if($format{-color} == $HEAD_COLOR) {
        if($format{-bold}) {
            my $headtext = substr($Window->POD->Text, $pos, 1);
            $tpos = $pos;
            $char = "x";
            #while($format{-color} == $HEAD_COLOR) {
            while($format{-bold} and $char ne "\n") {
                $tpos += 1;
                $char = substr($Window->POD->Text, $tpos, 1);
                $headtext .= $char;
                $Window->POD->Select($tpos, $tpos);
                %format = $Window->POD->GetCharFormat(1);
                # print "${char}[$format{-bold}]";
            }
            # print "\n";
            $tpos = $pos;
            # $format{-color} = $HEAD_COLOR;
            $format{-bold} = 1;
            $char = "x";
            # while($format{-color} == $HEAD_COLOR) {
            while($format{-bold} and $char ne "\n") {
                $tpos -= 1;
                $char = substr($Window->POD->Text, $tpos, 1);
                $headtext = $char . $headtext;
                $Window->POD->Select($tpos, $tpos);
                %format = $Window->POD->GetCharFormat(1);
                # print "$char";
            }
            #print "\n";
            # $headtext = strreverse($headtext) if $where < 0;
            $headtext =~ s/[\r\n]//g;
            #print "SearchHead: ($where,$pos) found '$headtext', wanted '$headwanted'\n";
            if($headtext eq $headwanted) {
                # $pos -= length($headtext) if $where > 0;
                $pos = $tpos;
                $found = 1;
            } else {
                $pos = ( ($where > 0) ? $pos+length($headtext)+1 : $tpos );
                $another++; # banged on another head
                $found = 2 if $another > $max_another; 
            }
        }
    }
    return wantarray ? ($opos, 0) : $opos if $found == 2;        
    return wantarray ? ($pos,  1) : $pos;
}

sub strreverse {
    my($string) = @_;
    my $new = "";
    for my $i (reverse 0..length($string)) {
        $new .= substr($string, $i, 1);
    }
    return $new;
}

######################################################################
# EVENTS :-)
#

sub Window_Resize {
	if(defined $Window) {
		($width, $height) = ($Window->GetClientRect)[2..3];
		$TOCwidth = ( $Window->Header->ItemRect(0) )[2];
		$Window->Header->Resize($TOCwidth, 22);
		if($Menu->{ViewStructure}->Checked) {
			$Window->TOC->Move(0, 22);
			$Window->TOC->Resize($TOCwidth, $height-22-$Window->Status->Height);
			$Window->POD->Move($TOCwidth, 0);
			$Window->POD->Resize($width-$TOCwidth, $height-$Window->Status->Height);
		} else {
			$Window->POD->Move(0, 0);
			$Window->POD->Resize($width, $height-$Window->Status->Height);
		}
		$Window->Status->Resize($width, $height);
		#if($Window->Status->Progress) {
		#    $Window->Status->Progress->Move($Window->Status->Width-150, 2);
		#}
		$NoPOD->Move($width/2-$NoPOD->Width/2, $height/2-$NoPOD->Height/2);
	}
}

sub Header_EndTrack {
    my($item, $TOCwidth) = @_;
    my($width, $height) = ($Window->GetClientRect)[2..3];
    if($TOCwidth < 16) {
        $Window->Header->ChangeItem(0, -width => 16);
        $TOCwidth = 16;
    }
    $Window->Header->Resize($TOCwidth, 22);
    $Window->TOC->Resize($TOCwidth, $height-22-$Window->Status->Height);
    $Window->POD->Move($TOCwidth, 0);
    $Window->POD->Resize($width-$TOCwidth, $height-$Window->Status->Height);
    $Window->TOC->SetForegroundWindow();
}

sub Header_Track {
    my($item, $width) = @_;
    return 0 if $width < 16;
    return 1;
}

sub Window_Terminate {
    #WriteMRU();
    return -1;
}

sub Window_Activate {
    $POD->SetFocus;
}

sub TOC_Click {
    my $EM_SCROLLCARET = 183;
    my $EM_LINESCROLL = 182;
    my $EM_SETSEL = 177;
    my $EM_EXLINEFROMCHAR = 1078;
    my($x, $y) = Win32::GUI::GetCursorPos();
    $x -= $Window->TOC->Left;
    $y -= $Window->TOC->Top;
    my $node = $Window->TOC->HitTest($x, $y);
    # print "LoadPod: DblClick on node($node)\n";
    if($node) {
        my %node = $Window->TOC->GetItem($node);
        my $char;
        my $found;
        if($TOCRef{$node} < 0) {
            $char = -$TOCRef{$node};
        } else {
            $Window->Status->Text("Searching '$node{-text}'...");
            ($char, $found) = SearchHead($TOCRef{$node}, -1, $node{-text});
            if($found == 0) {
                ($char, $found) = SearchHead($TOCRef{$node}, 1, $node{-text});
                if($found == 0) {
                    $Window->Status->Text("WARNING: '$node{-text}' not found!");
                } else {
                    $Window->Status->Text("PodView $VERSION Ready");
                }
            } else {
                $Window->Status->Text("PodView $VERSION Ready");
                
            }
            $TOCRef{$node} = -$char if $found;
        }
        my $fvl = $Window->POD->FirstVisibleLine;
        my $diff = ($Window->POD->LineFromChar($char)) - $fvl;
        #print 
        #    "Scrolling to line: ", 
        #    $Window->POD->LineFromChar($char), 
        #    " (char $char)\n";
        $Window->POD->SendMessage($EM_LINESCROLL, 0, $diff);
        my ($ci, $li) = $Window->POD->CharFromPos(1, 1);
        $Window->POD->Select($ci, $ci);
        $Window->POD->SendMessage($EM_SCROLLCARET, 0, 0);
        #if($Window->TOC->GetChild($node)) {
        #    $Window->TOC->Expand($node, 1);
        #}
    }
    return 0;
}

sub TOC_Collapsing {
    return ($TOC_CanExpand) ? 1 : 0;
}
sub TOC_Expanding {
    return ($TOC_CanExpand) ? 1 : 0;
}

#sub TOC_Click {
    # print "FVL=", $Window->POD->FirstVisibleLine, "\n";
    # print "LINE=", 
    #    $Window->POD->LineFromChar(($Window->POD->Selection)[0]), 
    #    " (char=",
    #    ($Window->POD->Selection)[0],
    #    "\n";
#}

sub TOC_Collapse {
#   $Window->TOC->Expand(shift);
    return 0;
}

sub MenuExit_Click {
    #WriteMRU();
    return -1;
}

sub MenuSave_Click {
    if($PODFILE) {
        $POD->Save($PODFILE.".rtf");
    }
}

sub MenuReload_Click {
    my($place) = $Window->POD->CharFromPos(1, 1);
    my $line   = $Window->POD->LineFromChar($place);
    LoadPod(undef, 1);
    my $EM_LINESCROLL = 182;    
    my $EM_SCROLLCARET = 183;   
    my $fvl = $Window->POD->FirstVisibleLine;
    print "li=$line ci=$place\n";
    $Window->POD->SendMessage($EM_LINESCROLL, 0, $line);    
    $Window->POD->Select($place, $place);
    $Window->POD->SendMessage($EM_SCROLLCARET, 0, 0);   
    $Window->POD->SetRedraw(1);
    $Window->POD->InvalidateRect(1);
    
}

sub MenuOpen_Click {
    my $file = GUI::GetOpenFileName();
    if($DEBUG) {
        print "GetOpenFileName returned $ret\n";
        print "CommDlgExtendedError is ", GUI::CommDlgExtendedError(), "\n";
        print "LastError is ", Win32::GetLastError(), "\n";
    }
    if($file) {
        if(LoadPod($file)) {
            AddToMRU($file);
        }
    }
}

sub MenuHeadColor_Click {
    my $c = GUI::ChooseColor(-color => $HEAD_COLOR);
    $HEAD_COLOR = $c if $c;
}

sub MenuLinkColor_Click {
    my $c = GUI::ChooseColor(-color => $L_COLOR);
    $L_COLOR = $c if $c;
}

sub MenuNormalFont_Click {
    my @f = GUI::ChooseFont(-name => $NORMAL_FONT_NAME, -noscript => 1);
    if($f[0]) {
        my %f = @f;
        $NORMAL_FONT_NAME = $f{-name};
    }
}

sub MenuFixedFont_Click {
    my @f = GUI::ChooseFont(-name => $FIXED_FONT_NAME, -noscript => 1, -fixedonly => 1);
    if($f[0]) {
        my %f = @f;
        $FIXED_FONT_NAME = $f{-name};
    }
}

sub MenuSaveConfig_Click {
    my $key;
    $HKEY_LOCAL_MACHINE->Open("SOFTWARE\\dada\\PodView", $key);
    if($key) {
        $key->SetValueEx("L_COLOR", 0, REG_SZ, $L_COLOR);
        $key->SetValueEx("HEAD_COLOR", 0, REG_SZ, $HEAD_COLOR);
        $key->SetValueEx("NORMAL_FONT_NAME", 0, REG_SZ, $NORMAL_FONT_NAME);
        $key->SetValueEx("FIXED_FONT_NAME", 0, REG_SZ, $FIXED_FONT_NAME);
        $key->Close();
    } else {
        Win32::GUI::MessageBox("ERROR: Unable to save config...");
    }
}

sub ViewStructure_Click {
    $Menu->{ViewStructure}->Checked(
        not $Menu->{ViewStructure}->Checked
    );
    if($Menu->{ViewStructure}->Checked) {
        $Window->Header->Show();
        $Window->TOC->Show();
    } else {
        $Window->Header->Hide();
        $Window->TOC->Hide();
    }
    Window_Resize();
}

sub ViewSource_Click {
    system("start notepad $PODFILE");
}

sub ToolPmx_Click {
    my $path = $FindBin::Bin;
    $path =~ s(/)(\\)g;
    $Window->Hide();
    system("perl $path\\pmx.pl");
    $Window->Show();
}

#===============================================================================
# still testing this...

$IBEAM = 32513;
$ARROW = 32512;

sub POD_MouseMove {
    # print "Got POD_MouseMove\n";
    my($shifts, $x, $y) = @_;
    my $Cursor;
    ($ci, $li) = $POD->CharFromPos($x, $y);
    if($ci) {
        # 11 == WM_SETREDRAW
        $POD->SendMessage(11, 0, 0);
        $POD->Disable();
        my($ss, $se) = $POD->Selection();
        $POD->Select($ci, $ci);
        my %format = $POD->GetCharFormat();
        $Cursor = ($se <= $ci and $ci >= $ss) ? $ARROW : $IBEAM;
        $POD->Select($ss, $se);
        $POD->SendMessage(11, 1, 0);
        $POD->Enable();
        $POD->InvalidateRect(0);
        if($format{-color} == $L_COLOR) {
            GUI::SetCursor($HAND); # if GUI::GetCursor() != $HAND;
        } else {
            GUI::SetCursor($Cursor);
        }
    #} else {
    #    GUI::SetCursor(32513);
    }
    while ($POD->PeekMessage(512, 512)) {
        $POD->GetMessage();
    }
    return 1;

}


sub POD_LButtonDown {
    my($shifts, $x, $y) = @_;
    my $ci;
    my $li;
    ($ci, $li) = $POD->CharFromPos($x, $y);
    if($ci) {
        $POD->Select($ci, $ci) if $ci;
        my %format = $POD->GetCharFormat();
        if($format{-color} == $L_COLOR) {
            $Window->Status->Text("that's a link");
        } elsif($format{-color} == $HEAD_COLOR) {
            $Window->Status->Text("YUPPI! it's a head!");
        } else {
            $Window->Status->Text("nopi, it's text.");
        }
    } else {
        $Window->Status->Text("nothing selected.");
    }
    return 1;

}
#===============================================================================


######################################################################
# POD - also "About PodView..." :-)
#

=head1 NAME

PodView - Plain Old Documentation Viewer

=head1 SYNOPSIS

    perl podview.pl [filename]

=head1 DESCRIPTION

This was done to test the Win32::GUI module.

=head1 AUTHOR

Aldo Calpini ( I<dada@divinf.it> )

=cut


