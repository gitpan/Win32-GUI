package Pod::RTF;
=head1 NAME

Pod::RTF - convert POD data to Rich Text Format

=head1 SYNOPSIS

    use Pod::RTF;

    pod2rtf("perlfunc.pod");

=head1 DESCRIPTION

Pod::RTF is a module that can convert documentation in the POD format (such
as can be found throughout the Perl distribution) into Rich Text Format.

=head1 METHODS

The base method is C<pod2rtf>, which does the actual POD to RTF conversion.
Additional settings can be changed before this step with the following
methods:

    set_normal_color(RED, GREEN, BLUE);
    
This sets the normal text font color (black by default).

    set_head_color(RED, GREEN, BLUE);
    
This sets the head font color (green by default).

    set_link_color(RED, GREEN, BLUE);

This sets the link font color (blue by default).

All color components (RED, GREEN and BLUE) are in the range 0-255.

=head1 AUTHOR

Martin Hosken E<lt>F<Martin_Hosken@sil.org>E<gt>.
Based on Pod::Text by Tom Christiansen.
Additional coding by Aldo Calpini E<lt>F<dada@divinf.it>E<gt>.

=head1 TODO

A lot of cleanup work, support user defined fonts and colors, and maybe 
learn something more on Rich Text Format.

=cut

$baseindent = 4;
$fntnorm = "swiss Arial";
$fntone = "roman Times New Roman";
$fnttwo = "charset2 Symbol";
$fntlit = "modern Courier New";
@clrnorm = (  0,   0,   0); # black
@clrhead = (  0, 128,   0); # green
@clrlink = (  0,   0, 255); # blue
$parhd = "\n" . '\pard\plain';              # hand hold double-spacing
$parhd = '\pard\plain';
$head[1] = '\par\f0\cf1\fs28\b ';
$head[2] = '\par\f0\cf1\fs24\b ';
$head[3] = '\par\f0\cf1\fs20\b ';
$head[4] = '\par\f0\cf1\fs20\b ';
$head[5] = '\par\f0\cf1\fs20\b ';
$head[6] = '\par\f0\cf1\fs20\b ';
$lithd = '\par\f3\fs18 ';
$normconthd = '\f0\fs20 ';
$normhd = '\par\f0\fs20 ';
$itemhd = '\f0\fs20\b';
# $itemhd = '\f0\fs20\b ';
@heads = ();

sub pod2rtf {
    @_ = ("<&STDIN") unless @_;
    local($file,*OUTFILE) = @_;
    *OUTFILE = *STDOUT if @_<2;

    open(INFILE, "$file") || die "Unable to open $file";
    
    my $f0 = "\\f0\\fswiss $fzeroname";
    my $c0 = "\\red$clrnorm[0]\\green$clrnorm[1]\\blue$clrnorm[2]";
    my $c1 = "\\red$clrhead[0]\\green$clrhead[1]\\blue$clrhead[2]";
    my $c2 = "\\red$clrlink[0]\\green$clrlink[1]\\blue$clrlink[2]";
    
    print OUTFILE qq(
{\\rtf1\\ansi\\deff0\\deftab720{\\fonttbl{\\f0\\fswiss
Arial;}{\\f1\\froman Times New Roman;}
{\\f2\\froman\\fcharset2 Symbol;}{\\f3\\fmodern Courier
New;}}{\\colortbl$c0;$c1;$c2;}\\deflang1033
);
    $podlength = 0;
    $head = 0;
    @heads = ();
    @indent = ();
    $state = "hunt1";
    $indent = $baseindent;
    $/ = "\n";
main:    
    while (<INFILE>) {
        if ($state eq "hunt1") {
            if (m/^=(head1|head2|pod|item|begin|end|for|back|over)\s+/oi) { 
                $state = "sop"; 
            } elsif (m/^\s*$/oi) { 
                next main; 
            } else { 
                $state = "hunt"; 
                next main; 
            }
        } elsif ($state eq "hunt") {
            $state = "hunt1" if (m/^\s*$/oi);
            next main;
        }

        1 while s/^(.*?)(\t+)(.*)$/$1 . (' ' x (length($2)*8 - length($1)%8)) . $3/me;
        s/([\\\{\}])/\\$1/oig;

        if (m/^\s+$/oi) {
            #print OUTFILE "@";
            endpar(0); 
        } elsif (m/^=(\S+)/oi and $state eq "sop") {
            $cmd = $1;
            $parm = $';
            endpar(0);
            if ($cmd =~ m/^head(\d).*?$/oi) {
                $head = $1;
                $tag = "";
                $_ = $parm;
                s/^\s*//oi;
                $state = "head";
                redo main;
            } elsif ($cmd =~ m/^for/oi) {
                if ($parm =~ /^text$/oi) {
                    print OUTFILE $parhd . '\li' . ($indent * 90) . $lithd;
                    $podlength += 2;
                    $state = "litpar";
                } else { 
                    $state = "dump"; 
                }
            } elsif ($cmd =~ /^begin/oi) {
                if ($parm =~ /^text$/oi) {
                    print OUTFILE $parhd . '\li' . ($indent * 90) . $lithd;
                    $podlength += 2;
                    $state = "litgrp";
                } else { 
                    $state = "dump"; 
                }
            } elsif ($cmd =~ /^end/oi) {
                $state = "sop";
            } elsif ($cmd =~ /^over/oi) {
                $parm = 4 unless $parm =~ /\d/;
                push (@indent, $indent);
                $indent += $parm;
                $state = "sop";
            } elsif ($cmd =~ /^back/oi) {
                $indent = pop(@indent) or $baseindent;
                $state = "sop";
            } elsif ($cmd =~ /^item/oi) {                
                $_ = $parm;
                s/^\s*//oi;                
                $tag = $_;
                $tag = "";
                $state = "soi";
                redo main;
            } elsif ($cmd =~ /^cut/oi) { 
                $state = "hunt";
            } elsif ($cmd =~ /^pod/oi) { 
                $state = "sop"; 
            } else { 
                print STDERR "Unrecognised POD directive: $cmd\n"; 
            }
        } elsif (m/^\s+/oi && $state ne "inp" && $state ne "head" && $state ne "soi") {
            if ($state eq "litpar" || $state eq "litgrp") { 
                print OUTFILE '\line ' . $_; 
                $podlength += length($_);
            }
            elsif ($state ne "sop") { 
                endpar(1); 
                $state = "sop"; 
            }
            if ($state eq "sop") {
                print OUTFILE $parhd . '\li' . ($indent * 90) . $lithd . $_ ;
                $podlength += length($_) + 2;
                $state = "litpar";
            }
        } elsif ($state eq "litpar" || $state eq "litgrp") {
            print OUTFILE '\line ' . $_ ;
            $podlength += length($_) + 1;
        } elsif ($state ne "dump") {
            $out = "";
            $outlength = 0;
            s/^\s+//oig;                    # strip spaces from start of continuation lines
            if ($state eq "sop") {
                print OUTFILE $parhd . '\li' . ($indent * 90) . $normhd;
                $podlength += 2;
                $state = "inp";
            }
            # now for the inline stuff!
            while (m/(>|[IBSLFXZEC]<)/o) {
                $out .= $`;
                $outlength += length($`);
                $found = $1;
                $_ = $';
                if ($found eq ">") {
                    if (--$inside <= -1) {
                        $inside = 0;
                        $out .= '>';
                        $outlength += 1;
                    } else { 
                        $out .= "}"; 
                    }
                } else {
                    $inside++;
                    $type = substr($found, 0, 1);
                    if ($type eq "I") { 
                        $out .= '{\i '; 
                    } elsif ($type eq "B") { 
                        $out .= '{\b '; 
                    } elsif ($type eq "C" || $type eq "F") { 
                        $out .= '{\f3 '; 
                    } elsif ($type eq "L") { 
                        $out .= '{\cf2 ';   # wimp out
                        if(m/^([^|]+)\|([^\/]+)\/([^>]*)>/) {
                            $out .= $1;
                            $outlength += length($1);
                            $inside--;
                            $_ = $';                            
                        }
                    } elsif ($type eq "E") {
                        if (m/^(\d+)>/oi) { 
                            $out .= sprintf("\\'%02x ", $1); 
                            $outlength += 2;
                            $inside--; 
                            $_ = $'; 
                        } elsif (m/^lt>/oi) { 
                            $out .= '<'; 
                            $outlength += 1;
                            $inside--; 
                            $_ = $'; 
                        } elsif (m/^gt>/oi) { 
                            $out .= '>'; 
                            $outlength += 1;
                            $inside--; 
                            $_ = $'; 
                        }
                    } else { 
                        $out .= "{"; 
                    }
# Can't be bothered with the rest. Just print the stuff out.
                }
                
            }
            if ($state eq "soi" || $state eq "head") { 
                $tag .= $out . $_; 
            } else { 
                print OUTFILE $out . $_ . " "; 
                $podlength += $outlength+length($_)+1;                
            }
        }
    }
    endpar(1);
    print OUTFILE "}";

    close(INFILE);

}

sub endpar {
    my ($strict) = @_;

    my $soiseen = 0;

    $inside = 0;

    $soiseen = 1 if ($state eq "soi");

    return if ($state eq "sop");

    if ($state eq "soi" and not $strict) {

        $tagindent = $indent[-1] || $baseindent;

        # this is the correct solution. But the RichEdit control isn't up to correct RTF
        #   print OUTFILE $parhd . '\li' . ($indent * 90) . '\fi' . (($tagindent - $indent) * 90);
        #   print OUTFILE $itemhd . $tag . ((length($tag) > $indent - $tagindent) ? '\line ' : '\tab ');

        my $ctag;
        ($ctag = $tag) =~ s/[\r\n]//g;
        print "item '$ctag' indent=$indent tagindent=$tagindent state=$state lastwasitem=$lastwasitem\n";
      
        if (length($tag) > $indent - $tagindent) {
            print OUTFILE '\par' unless $lastwasitem;       
            # $tag =~ s/[\r\n]//g;
            print OUTFILE '\pard\plain' . '\li' . ($tagindent * 90) . $itemhd . ' ' .$tag;
            print OUTFILE '\par\pard\plain' . '\li' . ($indent * 90) . $normconthd;
            $podlength += length($tag) + 4;
            $state = "sop";
            
        } else {                        # can do it properly
            # print OUTFILE '\par' unless $lastwasitem;       
            $tag =~ s/[\r\n]//g;
            #print OUTFILE $parhd . '\li' . ($indent * 90) . '\fi' . (($tagindent - $indent) * 90);
            print OUTFILE '\pard\plain' . '\li' . ($indent * 90) . '\fi' . (($tagindent - $indent) * 90);
            print OUTFILE '\par ' . $itemhd . $tag . '\tab\plain' . $normconthd ;
            $podlength += length($tag) + 4;
            $state = "inp";
        }
        push(@heads, "".(3+$#indent).";$podlength;$ctag");
        
    } elsif ($state eq "head") {
        print OUTFILE $parhd . $head[$head] . $tag . '\par';
        $podlength += 1;
        chomp($tag);
        push(@heads, "$head;$podlength;$tag");
        $state = "sop";
        $podlength += length($tag) + 1;
        # print "POD::RTF::endpar adding head(\n$tag\nPOD::RTF::endpar podlength now $podlength\n";
    } elsif ($state eq "dummy") { 
        $state = "sop"; 
    } elsif ($state eq "litgrp") { 
        print OUTFILE '\par'; 
        $podlength += 1;
    } else {
        print OUTFILE '\par';
        $podlength += 1;
        $state = "sop";
    }
    if($soiseen) {
        $lastwasitem = 1;
    } else {
        $lastwasitem = 0;
    }
    
}

sub set_normal_color { @clrnorm = @_; }
sub set_head_color { @clrhead = @_; }
sub set_link_color { @clrlink = @_; }

1;




