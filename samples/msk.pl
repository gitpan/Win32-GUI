
use Win32::GUI;

$file = ($ARGV[0] or "test.msk");

$dummyWin = new Win32::GUI::Window();
($OCW, $OCH) = $dummyWin->GetTextExtentPoint32("_");
# $OCH = $OCH*1.2;
$LH = $OCH*1.5;
print "OneChar = ($OCW x $OCH)\n";
undef $dummyWin;
open(MSK, $file) or die "Can't open $file: $!\n";

$layout = 0;
$lineindex = 0;
while(<MSK>) {
    chomp;
    if(/\[BEGIN\]/) {
        $Msk = new Win32::GUI::Window(
            -name => "Msk", 
            -text => "Msk", 
            -left => 100, 
            -top => 100,
            -font => $Font,
        );
        $layout = 1;
        $maxlength = 0;
    } elsif(/\[END\]/) {
        $layout = 0;
    } else {
        if($layout == 1) {
            $line = $_;
            $maxlength = length($line) if length($line) > $maxlength;
            $doing = "";
            %this = ();
            for $i (0..length($line)) {
                $c = substr($line, $i, 1);
                if($doing eq "Textfield") {
                    if($c eq "_") {
                        $this{length}++;
                    } else {
                        # end of a Textfield, we create it.
                        $width = $this{length}*$OCW;
                        $left = $this{start}*$OCW;
                        $top = $lineindex*$LH-2;
                        $height = $OCH+4;
                        $field = $Msk->AddTextfield(
                            -text   => "",
                            -left   => $left,
                            -top    => $top,
                            -width  => $width,
                            -height => $height,
                        );
                        $doing = "";
                    }
                } elsif($doing eq "Button") {
                    if($c eq "}") {
                        # end of a Button, we create it.
                        $this{length}++;
                        $width = $this{length}*$OCW;
                        $left = $this{start}*$OCW;
                        $top = $lineindex*$LH-2;
                        $height = $OCH+4;
                        $field = $Msk->AddButton(
                            -text   => $this{text},
                            -left   => $left,
                            -top    => $top,
                            -width  => $width,
                            -height => $height,
                        );
                        $doing = "";
                    } else {
                        $this{text} .= $c;
                        $this{length}++;
                    }
                } elsif($doing eq "Label") {
                    if($c eq "{") {
                        # end of a Label, start of a Button.
                        $width = $this{length}*$OCW;
                        $left = $this{start}*$OCW;
                        $top = $lineindex*$LH-2;
                        $height = $OCH+4;
                        $field = $Msk->AddLabel(
                            -text   => $this{text},
                            -left   => $left,
                            -top    => $top,
                            -width  => $width,
                            -height => $height,
                        );
                        %this = ();
                        $this{start} = $i;
                        $this{length} = 1;
                        $doing = "Button";
                    } elsif($c eq "_") {
                        # end of a Label, start of a Textfield.
                        $width = $this{length}*$OCW;
                        $left = $this{start}*$OCW;
                        $top = $lineindex*$LH-2;
                        $height = $OCH+4;
                        $field = $Msk->AddLabel(
                            -text   => $this{text},
                            -left   => $left,
                            -top    => $top,
                            -width  => $width,
                            -height => $height,
                        );
                        %this = ();
                        $this{start} = $i;
                        $this{length} = 1;
                        $doing = "Textfield";
                    } else {
                        $this{text} .= $c;
                        $this{length}++;
                    }

                } elsif($doing eq "") {
                    if($c eq "_") {
                        %this = ();
                        $this{start} = $i;
                        $this{length} = 1;
                        $doing = "Textfield";
                    } elsif($c eq "{") {
                        %this = ();
                        $this{start} = $i;
                        $this{length} = 1;
                        $doing = "Button";
                    } elsif($c ne " ") {
                        %this = ();
                        $this{start} = $i;
                        $this{length} = 1;
                        $this{text} = $c;
                        $doing = "Label";
                    }
                }
            }
            $lineindex++;
        } else {
            ;
        }
    }
}
close(MSK);

$W = $maxlength*$OCW;
$H = $lineindex*$LH;
$Msk->Resize($W, $H);
while($Msk->ScaleWidth < $W) {
    $Msk->Width($Msk->Width+1);
}
while($Msk->ScaleHeight < $H) {
    $Msk->Height($Msk->Height+1);
}

$Msk->Show();

Win32::GUI::Dialog();

sub Msk_Terminate {
    return -1;
}


# OLD STUFF
#            $stayhere = 1;
#            while($stayhere == 1) {
#                $start = index($line, "{", $end);
#                if($start > 0) {
#                    $start++;
#                    print "start = $start\n";
#                    $end = index($line, "}", $start);
#                    $end--;
#                    print "end = $end\n";
#                    $text = substr($line, $start, $end-$start);
#                    print "text = $text\n";
#                    $width = ($end - $start)*$OCW;
#                    $left = $start*$OCW;
#                    $top = $lineindex*$OCH-2;
#                    $height = $OCH+4;
#                    $button = $Msk->AddButton(
#                        -text => $text,
#                        -left => $left,
#                        -top    => $top,
#                        -width  => $width,
#                        -height => $height,
#                    );
#                    #$start--;
#                    #$end++;
#                    $line = substr($line, 0, $start) . (" " x ($end-$start)) . substr($line, $end);
#                } else {
#                    $stayhere = 0;
#                }
#            }
#            $stayhere = 1;
#            $start = 0;
#            $end = 0;
#            while($stayhere == 1) {
#                $start = index($line, "_", $end);
#                if($start > 0) {
#                    print "start = $start\n";
#                    $end = $start;
#                    $end++ while(substr($line, $end, 1) eq "_");
#                    print "end = $end\n";
#                    $text = substr($line, $start, $end-$start);
#                    print "text = $text\n";
#                    $width = ($end - $start)*$OCW;
#                    $left = $start*$OCW;
#                    $top = $lineindex*$OCH-2;
#                    $height = $OCH+4;
#                    $field = $Msk->AddTextfield(
#                        -text => "",
#                        -left => $left,
#                        -top    => $top,
#                        -width  => $width,
#                        -height => $height,
#                    );
#                    $line = substr($line, 0, $start) . (" " x ($end-$start)) . substr($line, $end);
#                } else {
#                    $stayhere = 0;
#                }
#            }
#
#            $start = 0;
#            $end = 0;
#            while($stayhere == 1) {
#                $start = index($line, "_", $end);
#                if($start > 0) {
#                    print "start = $start\n";
#                    $end = $start;
#                    $end++ while(substr($line, $end, 1) eq "_");
#                    print "end = $end\n";
#                    $text = substr($line, $start, $end-$start);
#                    print "text = $text\n";
#                    $width = ($end - $start)*$OCW;
#                    $left = $start*$OCW;
#                    $top = $lineindex*$OCH-2;
#                    $height = $OCH+4;
#                    $field = $Msk->AddTextfield(
#                        -text => "",
#                        -left => $left,
#                        -top    => $top,
#                        -width  => $width,
#                        -height => $height,
#                    );
#                } else {
#                    $stayhere = 0;
#                }
#            }
