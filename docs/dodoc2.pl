#perl -w
#use strict;
use Pod::Html;

my %D;
my %METHOD;
my %EVENT;
my $DEBUG = 0;

Parse("../GUI.xs");
Parse("../GUI.pm");

if($ARGV[0] eq "-u") {
    TbdOutput();
} elsif($ARGV[0] eq "-t") {
    TxtOutput();
} elsif($ARGV[0] eq "-h") {
    HtmlOutput();
} else {
    HtmlOutput();
#    PodOutput();
}

###############################################################################

sub Parse {
    my($file) = @_;
    my $package;
    my $method;
    my $methodname;
    my $applies;
    my $event;
    my $thisevent;
    my @packages;
    my $p;

    open(FILE, "<$file") or die;
    while(<FILE>) {
        if($method) {
            if(s/^\s*#\s?//) {
                $D{$package}{methods}{$method} .= $_;            
            } else {
                $method = 0;           
            }
        }
        if($event) {
            if(s/^\s*[#\*]\s?//) {
                if(/\(\@\)APPLIES_TO:\s*(.*\S)\s*/) {
                    $applies = $1;
                    if($applies eq "*") {
                    } else {
                        @packages = split(/\s*,\s*/, $applies);
                        foreach $p (@packages) {
                            #$p = "Win32::GUI::".$p;
                            #$p =~ s/\s*$//;
                            $METHOD{$p} = {} unless exists($METHOD{$p});
                            $EVENT{$p} = {} unless exists($EVENT{$p});
                            $EVENT{$p}{$event} = $thisevent;
							$D{$p}{events}{$event} = $thisevent;
                        }
                    }
                } else {
                    $thisevent .= $_;
                }
            } else {
                $event = 0;         
                $thisevent = "";
            }
        }
        if(/\(\@\)PACKAGE:\s*(.*\S)\s*$/) {
            $packname = $1;
			($package = $packname) =~ s/Win32::GUI:://;
            print "Found package: '$package'\n" if $DEBUG == 1;
			$D{$package}{name} = $packname;
			$D{$package}{methods} = {} unless exists $D{$package}{methods};
			$D{$package}{events}  = {} unless exists $D{$package}{events};
			$D{$package}{attrs}   = {} unless exists $D{$package}{attrs};
        }
        if(/\(\@\)EVENT:\s*(.*\S)\s*/) {        
            $event = $1;        
            print "Found event: '$event'\n" if $DEBUG == 1;

        }
        if(/\(\@\)METHOD:\s*(.*\S)\s*/) {
            $methodname = $1;
            ($method = $methodname) =~ s/\(.*//;
            print "Found method: '$method'\n" if $DEBUG == 1;
			$D{$package}{methods}{$method} = "$methodname;;;";
        }
    }
    close(FILE);
}

###############################################################################

sub newfirst {
    return ($a =~ /^new/) ? -1 : 
           ($b =~ /^new/) ? 1 : uc($a) cmp uc($b);
}

sub HtmlOutput {
    my $pak;
    my $page;
    my $sub;
    my $subname;
    my $syntax;
    my $content;
    my $newdone;

    my $nofpackages = 0;
    my $nofmethods = 0;
    my $nofumethods = 0;
    my $nofevents = 0;
    my $nofuevents = 0;

    open(INDEX, ">new.html");
	print INDEX "
		<HTML><HEAD><TITLE>new docs</TITLE></HEAD><BODY BGCOLOR=white>
	";
	# objects
	print INDEX qq(<B><A HREF="#objects">OBJECTS</A></B> -- );
	foreach $pak (sort keys %D) {
		next if $pak eq "Win32::GUI";
		push(@P, qq(<A HREF="#O_$pak">$pak</A>));
	}
	print INDEX join(", ", @P);
	# attributes

	# events
	@P = ();
	print INDEX "<P>";
	print INDEX qq(<B><A HREF="#events">EVENTS</A></B> -- );
	foreach $pak (sort keys %D) {
		foreach $evt (sort keys %{$D{$pak}{events}}) {
			$evt =~ s/\(.*$//;
			next if exists $evt{$evt};
			push(@P, qq(<A HREF="#E_$evt">$evt</A>));
			$evt{$evt} = 1;
		}
	}
	print INDEX join(", ", sort @P);
	# methods
	@P = ();
	print INDEX "<P>";
	print INDEX qq(<B><A HREF="#methods">METHODS</A></B> -- );
	foreach $pak (sort keys %D) {
		foreach $met (sort keys %{$D{$pak}{methods}}) {
			next if $met =~ /^new /;
			$met =~ s/\(.*$//;
			next if exists $met{$met};
			push(@P, qq(<A HREF="#M_$met">$met</A>));
			$met{$met} = 1;
		}
	}
	print INDEX join(", ", sort @P);


	# constructors
	print INDEX qq(<H1><A NAME="objects">OBJECTS</H1>);
	foreach $pak (sort keys %D) {
		next if $pak eq "Win32::GUI";
		print INDEX qq(<H2><A NAME="O_$pak">$pak</H2>);
		%met = ();
		@P = ();
		foreach $met (sort keys %{$D{$pak}{methods}}) {
			next unless $met =~ /^new /;
			($syntax, $content) = split(/;;;/, $D{$pak}{methods}{$met});
			push(@P, qq(<TT>$syntax</TT><BR>$content));
			$met{$met} = 1;
		}
		if($#P >= 0) {
			print INDEX qq(<B>CONSTRUCTOR(S)</B><P>);
			print INDEX join("<P>", @P);
		}
		%w = ();
		@P = ();

		foreach $w (sort keys %{$D{$pak}{methods}}) {
			next if $w =~ /^new /;
			$w =~ s/\(.*$//;
			next if exists $w{$w};
			push(@P, qq(<A HREF="#M_$w">$w</A>));
			$w{$w} = 1;
		}
		if($#P >= 0) {
			print INDEX "<P>";
			print INDEX qq(<B>METHODS</B> -- );
			print INDEX join(", ", @P);
		}

		%w = ();
		@P = ();	
		foreach $w (sort keys %{$D{$pak}{events}}) {
			$w =~ s/\(.*$//;
			next if exists $w{$w};
			push(@P, qq(<A HREF="#E_$w">$w</A>));
			$w{$w} = 1;
		}
		if($#P >= 0) {
			print INDEX "<P>";
			print INDEX qq(<B>EVENTS</B> -- );
			print INDEX join(", ", @P);
		}
		print INDEX "<HR>";

	}

	print INDEX "</BODY></HTML>\n";
	close(INDEX);
    close(INDEX);
}


sub HtmlPage {
    my($package) = @_;
    # $package =~ s/^Win32::GUI:://;
    $package =~ s/::/_/g;
    return $package.".html";
}

sub HtmlStart {
    my($title) = @_;
    return "
        <HTML>
        <HEAD>
        <TITLE>$title</TITLE>
        </HEAD>
        <BODY BGCOLOR=white>
        <FONT FACE=\"Verdana, Tahoma, Arial, Helvetica\" SIZE=2>
        <H3>$title</H3>
    ";
}

sub HtmlHeading {
    my($text) = @_;
    return "<B>$text</B>\n";
}

sub HtmlDefinition {
    my($package, $link, $term, $definition) = @_;
    #$definition =~ s/\n/<BR>\n/g;
    $definition =~ s/\n(\s*)/"<BR>\n"."&nbsp;" x length($1)/ge;
    #$definition =~ s/\s/&nbsp;/g;
    $definition =~ s
        [see(&nbsp;|\s)*(also)?(&nbsp;|\s)*(.*\(\))]
        ['see'.$1.$2.'&nbsp;'.HtmlInternalLink($package, $4)]gie;
    if($definition eq "") {
        print "TBD: ${package}::${term}\n";
        $definition = "<I>[TBD]</I><BR>\n";
    }
    if($link =~ /^e_/) {
        $term = "<I>OBJECT_</I><B>$term</B>";
    } else {
        $term = "<B>$term</B>";
    }
    return "
        <DT><A NAME=\"$link\">$term
        <DD>$definition<BR>
    ";
}

sub HtmlList {
    my($link, $item) = @_;
    return "<LI><A HREF=\"$link\">$item</A>\n";
}

###############################################################################

sub PodOutput {
    my $pak;
    my $page;
    my $sub;
    my $subname;
    my $syntax;
    my $content;
    my $newdone;

    my $nofpackages = 0;
    my $nofmethods = 0;
    my $nofumethods = 0;
    my $nofevents = 0;
    my $nofuevents = 0;

    foreach $pak (sort keys %METHOD) {
        $page = PodPage($pak);
        open(POD, ">$page") or warn "$0: can't open $page for writing: $!";
        print POD "=head2 Package $pak\n\n";
        print POD "L<Back to the Packages|guipacks/>\n\n";
        $newdone = 0;
        print POD "=over\n\n";
        foreach $sub (sort newfirst keys %{$METHOD{$pak}}) {
            if(!$newdone) {
                if($METHOD{$pak}{$sub} =~ /^new/) {
                    print POD "=item *\n\nL<Constructor>\n\n=over\n\n";
                } else {
                    print POD "=item *\n\nL<Methods>\n\n=over\n\n";
                }
            } elsif($newdone == 2) {
                print POD "=back\n\n=item *\n\nL<Methods>\n\n=over\n\n";
                $newdone = 1;
            }
            ($syntax, $content) = split(/;;;/, $METHOD{$pak}{$sub});
            if($METHOD{$pak}{$sub} =~ /^new/) {
                $newdone = 2;
            } else {
                $newdone = 1;
            }
            ($syntax, $content) = split(/;;;/, $METHOD{$pak}{$sub});
            ($subname = $syntax) =~ s/\|/&#124;/g;
            print POD "=item *\n\nL<$subname|/".htmlify(0, $syntax).">\n\n";
        }
        if(keys %{$EVENT{$pak}} > 0) {
            print POD "=back\n\n=item *\n\nL<Events>\n\n=over\n\n";
            foreach $sub (sort keys %{$EVENT{$pak}}) {
                $subname = $sub;
                $subname =~ s/\(.*$//;
                print POD "=item *\n\nL<$sub|/".htmlify(0, $sub).">\n\n";
            }
        }
        print POD "=back\n\n=back\n\n";
        $newdone = 0;
        foreach $sub (sort newfirst keys %{$METHOD{$pak}}) {
            if(!$newdone) {
                if($METHOD{$pak}{$sub} =~ /^new/) {
                    print POD "=head3 Constructor\n\n=over 4\n\n";
                } else {
                    print POD "=head3 Methods\n\n=over 4\n\n";
                }
            } elsif($newdone == 2) {
                print POD "=back\n\n=head3 Methods\n\n=over 4\n\n";
                $newdone = 1;
            }
            ($syntax, $content) = split(/;;;/, $METHOD{$pak}{$sub});
            $nofmethods++;
            $nofumethods++ if $content eq "";
            if($METHOD{$pak}{$sub} =~ /^new/) {
                $newdone = 2;
            } else {
                $newdone = 1;
            }
            print "METHOD<$pak><$sub>\n" if $DEBUG == 1;
            ($syntax, $content) = split(/;;;/, $METHOD{$pak}{$sub});
            print POD PodDefinition($pak, $syntax, $content);
            #print POD "=head4 $syntax\n\n";
            #print POD "$content\n\n";
        }
        if(keys %{$EVENT{$pak}} > 0) {
            print POD "=back\n\n=head3 Events\n\n=over 4\n\n";
        }
        foreach $sub (sort keys %{$EVENT{$pak}}) {
            $subname = $sub;
            $subname =~ s/\(.*$//;
            print POD PodDefinition($pak, $sub, $EVENT{$pak}{$sub});
            #print POD "=head4 $sub\n\n";
            #print POD "$EVENT{$pak}{$sub}\n\n";            
        }
        print POD "=back\n\n=cut\n";
        close(POD);
        $nofpackages++;
    }

    open(INDEX, ">pod/guipacks.pod") or warn "$0: can't open guipacks.pod for writing!";
    print INDEX "=head2 Win32::GUI Packages\n\n";
    print INDEX "L<Back to the index|gui/>\n\n";
    print INDEX "=head3 Packages\n\n=over\n\n";
    foreach $pak (sort keys %METHOD) {
        $page = PodPage($pak);
        $page =~ s/\.pod//;
		$page =~ s/^pod\///;
        print INDEX "=item *\n\nL<$pak|$page/>\n\n";
    }
    print INDEX "=back\n\n=cut\n";
    close(INDEX);

    print STDERR "$nofpackages packages.\n";
    print STDERR "$nofmethods methods ($nofumethods undocumented).\n";
    print STDERR "$nofevents events ($nofuevents undocumented).\n";
}

sub PodPage {
    my($package) = @_;
    $package =~ s/^Win32::GUI:://;
    $package =~ s/::/_/g;
    return "pod/$package.pod";
}

sub PodDefinition {
    my($package, $term, $definition) = @_;
    #
    # properly split literal paragraphs from plain text
    #
    my(@lines) = split(/\n/, $definition);
    foreach my $i (0..$#lines) {
        if($lines[$i] =~ /^\S/ and $lines[$i+1] =~ /^\s/) {
            $lines[$i] .= "\n";
        }
        if($lines[$i] =~ /^\s/ and $lines[$i+1] =~ /^\S/) {
            $lines[$i] .= "\n";
        }
    }
    $definition = join("\n", @lines);
    #$definition =~ s/\n(\S.*)\n/\n$1\n\n/g;
    #$definition =~ s/\n(\s.*)\n(\S)/\n\n$1\n\n$2/g;
    $definition =~ s
        [(see\s*)(also)?(\s*)(.*\(\))]
        [$1.$2.$3.' '.PodInternalLink($package, $4)]gie;
    if($definition eq "") {
        # print "TBD: ${package}::${term}\n";
        $definition = "[TBD]\n\n";
    }
    
    return 
    "=for html <A NAME=\"".htmlify(0, $term)."\">\n\n"
    .
    "=item $term\n\n$definition\n\n"
    .
    "=for html <P>\n\n"
    ;
}

sub PodInternalLink {
    my($package, $link) = @_;
    my $pak;
    $link =~ s/^\s*//;
    $link =~ s/\s*$//;
    my $name = substr($link, 0, index($link, '('));
    if(defined($METHOD{$package}{$name})) {
        my $section = PodLinkSyntax($package, $name);
        return "L<$link|/$section>";
    } elsif(defined($EVENT{$package}{$name})) {
        return "L<$link|/$name>";
    } else {
        foreach $pak (sort keys %METHOD) {
            if($METHOD{$pak}{$name}) {
                my $section = PodLinkSyntax($pak, $name);
                my $page = PodPage($pak);
                $page =~ s/\.pod//;
                $page =~ s/^pod\///;
                return "L<$link|".$page."/$section>";
            } elsif($EVENT{$pak}{$name}) {
                my $page = PodPage($pak);
                $page =~ s/\.pod//;
                $page =~ s/^pod\///;
				return "L<$link|".$page."/$name>";
            }
        }
    }
    warn "broken link (package: $package, link: $name)\n";
    return $link;
}

sub PodLinkSyntax {
    my($package, $name) = @_;
    my ($syntax, $content) = split(/;;;/, $METHOD{$package}{$name});
    return htmlify(0, $syntax);
}

sub PodOutput_OLD {
    my $pak;
    my $page;
    my $sub;
    my $subname;
    my $syntax;
    my $content;
    my $newdone;

    my $nofpackages = 0;
    my $nofmethods = 0;
    my $nofumethods = 0;
    my $nofevents = 0;
    my $nofuevents = 0;

    foreach $pak (sort keys %METHOD) {
        $page = PodPage($pak);
        open(POD, ">$page") or warn "$0: can't open $page for writing: $!";
        print POD "=head2 Package $pak\n\n";
        print POD "L<Back to the Packages|guipacks/>\n\n";
        $newdone = 0;
        print POD "=over\n\n";
        foreach $sub (sort newfirst keys %{$METHOD{$pak}}) {
            if(!$newdone) {
                if($METHOD{$pak}{$sub} =~ /^new/) {
                    print POD "=item *\n\nL<Constructor>\n\n=over\n\n";
                } else {
                    print POD "=item *\n\nL<Methods>\n\n=over\n\n";
                }
            } elsif($newdone == 2) {
                print POD "=back\n\n=item *\n\nL<Methods>\n\n=over\n\n";
                $newdone = 1;
            }
            ($syntax, $content) = split(/;;;/, $METHOD{$pak}{$sub});
            if($METHOD{$pak}{$sub} =~ /^new/) {
                $newdone = 2;
            } else {
                $newdone = 1;
            }
            ($syntax, $content) = split(/;;;/, $METHOD{$pak}{$sub});
            ($subname = $syntax) =~ s/\|/&#124;/g;
            print POD "=item *\n\nL<$subname|/".htmlify(0, $syntax).">\n\n";
        }
        if(keys %{$EVENT{$pak}} > 0) {
            print POD "=back\n\n=item *\n\nL<Events>\n\n=over\n\n";
            foreach $sub (sort keys %{$EVENT{$pak}}) {
                $subname = $sub;
                $subname =~ s/\(.*$//;
                print POD "=item *\n\nL<$sub|/".htmlify(0, $sub).">\n\n";
            }
        }
        print POD "=back\n\n=back\n\n";
        $newdone = 0;
        foreach $sub (sort newfirst keys %{$METHOD{$pak}}) {
            if(!$newdone) {
                if($METHOD{$pak}{$sub} =~ /^new/) {
                    print POD "=head3 Constructor\n\n";
                } else {
                    print POD "=head3 Methods\n\n";
                }
            } elsif($newdone == 2) {
                print POD "=head3 Methods\n\n";
                $newdone = 1;
            }
            ($syntax, $content) = split(/;;;/, $METHOD{$pak}{$sub});
            $nofmethods++;
            $nofumethods++ if $content eq "";
            if($METHOD{$pak}{$sub} =~ /^new/) {
                $newdone = 2;
            } else {
                $newdone = 1;
            }
            print "METHOD<$pak><$sub>\n" if $DEBUG == 1;
            ($syntax, $content) = split(/;;;/, $METHOD{$pak}{$sub});
            print POD PodDefinition($pak, $syntax, $content);
            #print POD "=head4 $syntax\n\n";
            #print POD "$content\n\n";
        }
        if(keys %{$EVENT{$pak}} > 0) {
            print POD "=head3 Events\n\n";
        }
        foreach $sub (sort keys %{$EVENT{$pak}}) {
            $subname = $sub;
            $subname =~ s/\(.*$//;
            print POD "=head4 $sub\n\n";
            print POD "$EVENT{$pak}{$sub}\n\n";            
        }
        print POD "=cut\n";
        close(POD);
        $nofpackages++;
    }

    open(INDEX, ">guipacks.pod") or warn "$0: can't open guipacks.pod for writing!";
    print INDEX "=head2 Win32::GUI Packages\n\n";
    print INDEX "L<Back to the index|gui/>\n\n";
    print INDEX "=head3 Packages\n\n=over\n\n";
    foreach $pak (sort keys %METHOD) {
        $page = PodPage($pak);
        $page =~ s/\.pod//;
        print INDEX "=item *\n\nL<$pak|$page/>\n\n";
    }
    print INDEX "=back\n\n=cut\n";
    close(INDEX);

    print STDERR "$nofpackages packages.\n";
    print STDERR "$nofmethods methods ($nofumethods undocumented).\n";
    print STDERR "$nofevents events ($nofuevents undocumented).\n";
}

sub TbdOutput {
    my $pak;
    my $page;
    my $sub;
    my $subname;
    my $syntax;
    my $content;
    my $newdone;

    my $nofpackages = 0;
    my $nofmethods = 0;
    my $nofumethods = 0;
    my $nofevents = 0;
    my $nofuevents = 0;

    foreach $pak (sort keys %METHOD) {
        foreach $sub (sort newfirst keys %{$METHOD{$pak}}) {
            ($syntax, $content) = split(/;;;/, $METHOD{$pak}{$sub});
            $nofmethods++;
            if($content eq "") {
                $nofumethods++;
                print "Method: ${pak}::$sub\n";
            }            
        }
        if(keys %{$EVENT{$pak}} > 0) {
            foreach $sub (sort keys %{$EVENT{$pak}}) {
                $nofevents++;
                if($EVENT{$pak}{$sub} eq "") {
                    $nofuevents++;
                    print "Event: ${pak}::$sub\n";
                }
            }
        }
        $nofpackages++;
    }
    print STDERR "$nofpackages packages.\n";
    print STDERR "$nofmethods methods ($nofumethods undocumented).\n";
    print STDERR "$nofevents events ($nofuevents undocumented).\n";
}
