#!perl -w

use blib;
use strict;

use Win32::GUI;
use Cwd;

my $VERSION = "0.14.00";
my %objects = ();
my %varobjects = ();

my %TreeStruct;

my $EM_SCROLLCARET = 183;
my $EM_LINESCROLL = 182;
my $EM_SETSEL = 177;
my $EM_EXLINEFROMCHAR = 1078;

my ($DOS) = Win32::GUI::GetPerlWindow();
#Win32::GUI::Hide($DOS);

my $Menu = new Win32::GUI::Menu(
    "&File" => "File",
    "   >   &New" => "FileNew",
    "   >   &Open" => "FileOpen",
    "   >   &Save" => "FileSave",
    "   >   Save &As" => "FileSaveAs",
    "   >   &Close" => "FileClose",
    "   >   -" => 0,
    "   >   &Repride" => "FileRepride",
    "   >   -" => 0,
    "   >   E&xit" => "FileExit",

    "&Edit" => "Edit",
    "   >   &Undo" => "EditUndo",
    "    >    -" => 0,
    "   >   Cu&t" => "EditCut",
    "   >   &Copy" => "EditCopy",
    "   >   &Paste" => "EditPaste",

    "&Program" => "Program",
    "   >   &View Structure" => { -name => "ProgramViewStructure", -checked => 1 },
    "   >   &Rebuild Structure" => "ProgramRebuildStructure",

    "&Run" => "Run",
    "   >   &Execute" => "RunExecute",
    "   >   &Debug" => "RunDebug",

);

my $EditorFont = new Win32::GUI::Font(
    -name => "Courier New", 
    -height => 16,
);

my $EditorClass = new Win32::GUI::Class(
    -name => "PRIDE_${VERSION}_Editor",
    -extends => "RichEdit",
    -widget => "RichEdit",
);

my $Window = new Win32::GUI::Window(
    -name   => "Window",
    -left   => 100,
    -top    => 100,
    -width  => 800,
    -height => 500,
    -title  => "PRIDE version ".$VERSION,
    -menu   => $Menu,
);

$Window->AddStatusBar(
    -name => "Status",
    -text => "PRIDE version $VERSION - Ready",
);

$Window->AddRichEdit(
    -class     => $EditorClass,
    -name      => "Editor",
    -multiline => 1,
    -left      => 150,
    -top       => 28,
    -width     => $Window->ScaleWidth,
    -height    => $Window->ScaleHeight-28-$Window->Status->Height,
    -font      => $EditorFont,
    -exstyle   => WS_EX_CLIENTEDGE,
    -style     => WS_CHILD | WS_VISIBLE | WS_VSCROLL | WS_HSCROLL
		| ES_LEFT | ES_MULTILINE | ES_AUTOHSCROLL | ES_AUTOVSCROLL,
);

$Window->Editor->SendMessage(1093, 0, 1);

$Window->AddTreeView(   
	-name   => "ProgStruct",
	-pos    => [0, 0],
	-size   => [ 150, $Window->ScaleHeight-28-$Window->Status->Height ],
	-lines  => 1,
	-buttons => 1,
	-rootlines => 1,
);

#
#$Window->AddCombobox(
#    -name      => "SelectObj",
#    -left      => 0,
#    -top       => 5,
#    -width     => $Window->ScaleWidth/2,
#    -height    => 300,
#    -style     => Win32::GUI::constant("WS_VISIBLE", 0) | 3 | Win32::GUI::constant("WS_NOTIFY", 0),
#);
#
#$Window->AddCombobox(
#    -name      => "SelectSub",
#    -left      => $Window->ScaleWidth/2,
#    -top       => 5,
#    -width     => $Window->ScaleWidth/2,
#    -height    => 300,
#    -style     => Win32::GUI::constant("WS_VISIBLE", 0) | 3 | Win32::GUI::constant("WS_NOTIFY", 0),
#);
#

my $GotoWindow = new Win32::GUI::DialogBox(
    -name => "GotoWindow",
    -text => "Goto line...",
    -left => 150,
    -top  => 150,
    -width => 200,
    -height => 100,
);

$GotoWindow->AddLabel(
    -name => "GotoLabel",
    -text => "Line:",
    -left => 5,
    -top => 10,
);

$GotoWindow->AddTextfield(
    -name => "GotoLine",
    -left => 5,
    -top => 25,
    -width => 190,
    -height => 22, 
    -tabstop => 1,
);

$GotoWindow->AddButton(
    -name => "GotoOK",
    -text => "OK", 
    -left => 5,
    -top => 50,
    -height => 22,
    -width => 90,
    -tabstop => 1,
    -ok => 1,
    -default => 1,
);

$GotoWindow->AddButton(
    -name => "GotoCancel",
    -text => "Cancel", 
    -left => 100,
    -top => 50,
    -height => 22,
    -width => 90,
    -tabstop => 1,
    -cancel => 1,
);

$Window->Show();

my $FILE = ($ARGV[0] or $0);
LoadFile($FILE);

$Window->{-dialogui} = 1;

print "DIALOGUI: $Window->{-dialogui}\n";<STDIN>;

Win32::GUI::Dialog();

Win32::GUI::Show($DOS);
print "Bye bye from PRIDE version $VERSION...\n";

sub Window_Terminate {
    if(OkToClose()) {
	return -1;
    } else {
	return 1;
    }
}

sub Window_Resize {
    my $Width = $Window->ScaleWidth;
    my $Height = $Window->ScaleHeight;
    $Window->Editor->Resize($Width, $Height-28-$Window->Status->Height);
    $Window->Status->Resize($Width, $Window->Status->Height);
#    $Window->SelectObj->Resize($Width/2, $Window->SelectObj->Height);
#    $Window->SelectSub->Resize($Width/2, $Window->SelectSub->Height);
#    $Window->SelectSub->Move($Width/2, 5);
    $Window->Status->Move(0, $Window->ScaleHeight-$Window->Status->Height);
}

sub Window_Activate {
    $Window->Editor->SetFocus();
}

sub LoadFile {
    ($FILE) = @_;
    my $DEBUG = 1;
    print "FILE: $FILE\n" if $DEBUG;
    open(FILE, $FILE) or return 0;
    my $file = "";
    my $object;
    my $parent;
    my $sub;
    my $defo;
    my $var;  
    my $what;
	my $name;
    my $c = 1;

    %objects = ("<perl>" => []);
    %varobjects = ();
#    $Window->SelectObj->Clear();
#    $Window->SelectSub->Clear();
#    $Window->SelectObj->AddString("<perl>");

	$Window->ProgStruct->Clear();

	$TreeStruct{"<perl>"} = $Window->ProgStruct->InsertItem(-text => "<perl>");

    while(<FILE>) {
	chomp;
	# converts tabs in 4 spaces
	s/\t/    /g;

		if(/^\s*#/) {
			$file .= $_."\r\n";
		} else {

			if(/\$(.+)\s*=\s*new (Win32::)?GUI::/) {
				$var = $1;
				$var =~ s/^\s*//;
				$var =~ s/\s*$//;
				print "Found variable: [$var]\n" if $DEBUG;
				$object = "[TBD]";
				$what = "X";
				$defo = length($file);
			}

			#    $Window->SelectObj->AddString($object);
			#    $Window->SelectObj->Text($object);
			#    if(exists($objects{$object})) {
			#        push(@{$objects{$object}}, "<definition>;".length($file));
			#    } else {
			#        $objects{$object} = [ "<definition>;".length($file) ];
			#    }
			#}

			if(/\s*\$(\S+)->Add/) {
				$parent = $1;
				$parent =~ s/^\s*//;
				$parent =~ s/\s*$//;
				print "Found child of [$parent]\n" if $DEBUG;
				print "varobjects(parent): $varobjects{$parent}\n" if $DEBUG;
				if(exists($varobjects{$parent})) {
					$object = "[TBD]";
					$what = "";
					$defo = length($file);
				} else {
					print "Skipping because [$parent] doesn't exists...\n" if $DEBUG;
				}
			}
			if(/-name\s*=>\s*["']?([^,"']+)["']?,?/ and $object eq "[TBD]") {
				$object = $1;
				$object =~ s/^\s*//;
				$object =~ s/\s*$//;
				print "Found name: [$object]\n" if $DEBUG;
				if(exists($objects{$object})) {
					push(@{$objects{$object}}, "<definition>;".$defo);
				} else {
					$objects{$object} = [ "<definition>;".$defo ];
				}
				if($var) {
					#$Window->SelectObj->AddString($object." (\$".$var.")");
					#$Window->SelectObj->Text($object." (\$".$var.")");

					$TreeStruct{$object} = $Window->ProgStruct->InsertItem(
						-text => "$object (\$$var)",
					);
					$varobjects{$var} = $object;
				} else {
					$TreeStruct{$object} = $Window->ProgStruct->InsertItem(
						-text => "$object",
					);
					#$Window->SelectObj->AddString($object);
					#$Window->SelectObj->Text($object);
				}            
				$object = "";
				$var = "";
				$what = "";
			}
			if(/\$(.+)\s*=\s*\$(.+)->Add/) {
				$object = $1;
				$parent = $2;
				$object =~ s/^\s*//;
				$object =~ s/\s*$//;
				$parent =~ s/^\s*//;
				$parent =~ s/\s*$//;
				print "Found object: [$object] (parent: [$parent])\n" if $DEBUG;
				print "objects(parent): $objects{$parent}\n" if $DEBUG;
				#if(exists($objects{$parent})) {
				#    $Window->SelectObj->AddString($object);
				#    $Window->SelectObj->Text($object);
				#    push(@{$objects{$object}}, "<definition>;".length($file));
				#}
				if(exists($varobjects{$parent})) {
					$object = "[TBD]";
					$what = "";
					$defo = length($file);
				} else {
					print "Skipping because [$parent] doesn't exists...\n" if $DEBUG;
				}

			}
			if(/^\s*sub ([^\s{]+)_([^\s{]+)/) {
				$parent = $1;
				$sub    = $2;
				if(exists($objects{$parent})) {
					push(@{$objects{$parent}}, $sub.";".length($file));
				} else {
					$parent = "<perl>";
					$sub    = $1."_".$2;
					if(exists($objects{$parent})) {
						push(@{$objects{$parent}}, $sub.";".length($file));
					}               
				}               
			} else {
				if(/^\s*sub ([^\s{]+)/) {
					$parent = "<perl>";
					$sub    = $1;
					if(exists($objects{$parent})) {
						push(@{$objects{$parent}}, $sub.";".length($file));
					}               
				}
			}
			# $file .= $c++." ".$_."\r\n";
			$file .= $_."\r\n";
		}               
    }
    close(FILE);

	foreach $object (keys %objects) {
		foreach $sub (@{$objects{$object}}) {
			($name, undef) = split(/;/, $sub, 2);
			$TreeStruct{$object."-".$name} = $Window->ProgStruct->InsertItem(
				-text => $name, 
				-parent => $TreeStruct{$object},
			);
		}
	}


    $Window->Editor->Text($file);
    $Window->Caption("PRIDE Version $VERSION - $FILE");
    $Window->Editor->SetFocus();
    return 1;
}

sub SelectObj_Change {
    my $object = $Window->SelectObj->GetString($Window->SelectObj->SelectedItem);
    $object =~ s/ \(\$.*\)$//;
    print "Selected object: $object\n";
    $Window->SelectSub->Clear();
    my $sub;
    my $name;
    foreach $sub (@{$objects{$object}}) {
	($name, undef) = split(/;/, $sub, 2);
	$Window->SelectSub->AddString($name);
    }
    $Window->SelectSub->Select(0);
    SelectSub_Change();
}

sub SelectSub_Change {
    my $object;
    my $ssub;
    my $issub = $Window->SelectSub->SelectedItem;
    my $isobject = $Window->SelectObj->SelectedItem;
    if($isobject >= 0) {
	$object = $Window->SelectObj->GetString($Window->SelectObj->SelectedItem);
	$object =~ s/ \(\$.*\)$//;
    } else {
	return 1;
    }
    if($issub >= 0) {
	$ssub = $Window->SelectSub->GetString($Window->SelectSub->SelectedItem);
    } else {
	return 1;
    }
    my $sub;
    my $name;
    my $pos;
    foreach $sub (@{$objects{$object}}) {
	($name, $pos) = split(/;/, $sub, 2);
	if($name eq $ssub) {

	    GotoLine($Window->Editor->LineFromChar($pos));

	    #print "Object: $object / Sub: $ssub / Pos: $pos\n";
	    ## $Window->Editor->Select($pos-1, $pos+1);
	    #$Window->Editor->SendMessage($EM_SETSEL, $pos, $pos);
	    #$Window->Editor->SendMessage($EM_SCROLLCARET, 0, 0);
	    
	    $Window->Editor->Update();
	    $Window->Editor->SetFocus();
	}
    }
}

sub FileRepride_Click {
    # system("perl $0");
    if(OkToClose()) {

	system("start /min perl $0");

	#my $pid = 0;
	#my $file;
	#if($FILE !~ /^[a-z]:\\/i) {
	#    $file = Win32::GetCwd."\\".$FILE;
	#} else {
	#    $file = $FILE;
	#}
	#print "Executing p:\\perl5\\bin\\perl.exe $file ...\n";
	#my $r = Win32::Spawn("perl", "$file", $pid);
	#my $err = Win32::GetLastError();
	#print "Repride r=$r err=$err pid=$pid\n";
	return -1;
    } else {
	return 1;
    }
}


sub FileExit_Click {
    if(OkToClose()) {
	return -1;
    } else {
	return 1;
    }
}

sub FileSave_Click {
    # make a backup copy
    open(BAKFILE, ">$FILE.bak");
    open(OLDFILE, "<$FILE");
    while(<OLDFILE>) { print <BAKFILE>; }
    close(BAKFILE);
    close(OLDFILE);

    open(FILE, ">$FILE");
    my $text = $Window->Editor->Text();
    $text =~ s/\r\n/\n/g;
    print FILE $text;
    close(FILE);
    $text = $Window->Text();
    if($text =~ s/ \*$//) {
	$Window->Text($text);
    }
}


sub FileClose_Click {
    if(OkToClose()) {
	$Window->Editor->Text("");
	$FILE = "untitled.pl";
	$Window->Text("PRIDE version $VERSION - untitled.pl");
    }
}

sub FileNew_Click {
    if(OkToClose()) {
	$Window->Editor->Text("");
	$FILE = "untitled.pl";
	$Window->Text("PRIDE version $VERSION - untitled.pl");
    }
}

sub FileOpen_Click {
    my $file = GUI::GetOpenFileName(-directory => Win32::GetCwd());
    if($file) {
	LoadFile($file);
    }
}

sub Editor_KeyPress {
    my($key) = @_;

    if($key == 7) {
	$GotoWindow->Move(
	    $Window->Left+($Window->ScaleWidth-$GotoWindow->Width)/2,
	    $Window->Top+($Window->ScaleHeight-$GotoWindow->Height)/2,
	);
	$GotoWindow->Show();
	$GotoWindow->GotoLine->SetFocus();
	$Window->Disable();
	return 0;
    } else {
	print "Editor_KeyPress got $key\n";
	my($pos, undef) = $Window->Editor->Selection();
	my $line = 1 + $Window->Editor->LineFromChar($pos);
	$Window->Status->Text("on line $line");
	return 1;
    }
}

sub GotoWindow_Terminate {
    GotoCancel_Click();
}

sub GotoCancel_Click {
    $GotoWindow->Hide();
    $Window->Enable();
    $Window->SetForegroundWindow();
    return 1;
}

sub GotoOK_Click {
    $GotoWindow->Hide();
    $Window->Enable();
    GotoLine($GotoWindow->GotoLine->Text);
    return 1;
}

sub GotoLine {
    my($line) = @_;
    print "Line=$line\n";
    my $fvl = $Window->Editor->FirstVisibleLine;
    print "FVL=$fvl\n";
    my $diff = ($line-1) - $fvl;
    print "DIFF=$diff\n";
    $Window->Editor->SendMessage($EM_LINESCROLL, 0, $diff);
    my ($ci, $li) = $Window->Editor->CharFromPos(1, 1);
    print "CI=$ci\n";
    $Window->Editor->Select($ci, $ci);
    $Window->Editor->SendMessage($EM_SCROLLCARET, 0, 0);
    $Window->Editor->SetFocus();
}

sub Editor_Change {
    my $text = $Window->Text;
    if($text !~ /\*$/) {
	$Window->Text($text." *");
    }
    return 1;
}

sub OkToClose {
    # if($Window->Editor->Modified()) {
    if($Window->Text =~ /\*$/) {
	my $answer = $Window->MessageBox("Save changes to $FILE ?", "PRIDE", 3+48);
	if($answer == 3) { # IDCANCEL
	    return 0;
	} elsif($answer == 6) {
	    FileSave_Click();
	    return 1;
	} elsif($answer == 7) {
	    return 1;
	}
    } else {
	return 1;
    }
    return 0;
}

#=======================
sub ProgStruct_KeyDown {
#=======================
	my($key) = @_;
	if($key == 13) {
		ProgStruct_DblClick();
	}
}
#========================
sub ProgStruct_DblClick {
#========================
	my $sub = $Window->ProgStruct->SelectedItem;
	print "ProgStruct_DblClick: sub=$sub\n";
    my %sub = $Window->ProgStruct->GetItem($sub);
	my $obj = $Window->ProgStruct->GetParent($sub);
	print "ProgStruct_DblClick: obj=$obj\n";
	my %obj = $Window->ProgStruct->GetItem($obj);

	$obj{-text} =~ s/\s\(.*\)$//;

	if(exists $TreeStruct{$obj{-text}."-".$sub{-text}}) {
		foreach my $o (@{$objects{$obj{-text}}}) {
			my ($name, $pos) = split(/;/, $o, 2);
			if($name eq $sub{-text}) {
				GotoLine($Window->Editor->LineFromChar($pos));

				$Window->Editor->Update();
				$Window->Editor->SetFocus();
			}
		}
	} else {
		print "not a child: $obj{-text}-$sub{-text}\n";
	}
    return 0;
}

