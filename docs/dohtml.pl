use Pod::Html;
use File::Copy;
use Win32::GUI;

@toindex = qw(
    guioptions
    guiconcepts
);

opendir(D, "..");
while($infile = readdir(D)) {
    next unless $infile =~ /\.pm$/i
            and $infile !~ /^GUI\.pm$/i;
    ($outfile = $infile) =~ s/\.pm$/.pod/i;   
    copy("../$infile", "pod/$outfile");
    $infile =~ s/\.pm$//i;
	print "found support_pack: $infile\n";
    push(@support_pack, $infile);
}
closedir(D);

open(P, "<gui.pod");
open(N, ">gui.new");
$found = "no";
$ver = Win32::GUI::Version();
($mday,$mon,$year) = (localtime)[3..5];
@monthname = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
$date = sprintf("%02d %3s %4d", $mday, $monthname[$mon], $year+1900);
while(<P>) {
    if(/Support packages/i) {
        print N $_;
        $found = "yes";
    }
    if($found ne "no") {        
        if(/^=back/) {
            print N $_;
            $found = "no";
        }
        if($found eq "yes") {
            print N "\n\n=over 4\n\n";
            foreach $p (@support_pack) {
                ($n = $p) =~ s/^/Win32::GUI::/;
                print N "=item *\n\nL<$n|$p/>\n\n";
            }
            $found = "done";
        }
    } else {
        s/^Version:\s+.*/Version: B<$ver>, $date/io and print "found VERSION on line $.\n";
        print N $_;
    }
}
close(P);
close(N);
unlink("gui.pod");
rename("gui.new", "gui.pod");

system("copy *.pod pod");

chdir("./pod");
opendir(D, ".");
@files = readdir(D);
foreach $infile (sort @files) {
    next unless $infile =~ /\.pod$/i;
    ($outfile = $infile) =~ s/\.pod$/.html/i;
    pod2html(
        "--htmlroot=.", 
        "--podpath=.", 
        "--infile=./$infile",
        "--outfile=../html/$outfile",
        "--noindex",
    );
}
closedir(D);
chdir("..");

foreach $file (@toindex) {
    open(P, "pod/$file.pod");
    @poddata = <P>;
    close(P);
    $index = Pod::Html::scan_headings(\%sections, @poddata);
    $index =~ s/<LI>.*\n//;
    1 while ($index =~ s/<UL>([\s\n]*)<UL>/<UL>/);
    1 while ($index =~ s/<\/UL>([\s\n]*)<\/UL>/<\/UL>/);
    $opened++ while ($index =~ /<UL>/g);
    $closed++ while ($index =~ /<\/UL>/g);
    if($opened > $closed) {
        $index .= "</UL>" x ($opened-$closed);
    }
    open(H, "<html/$file.html");
    open(N, ">html/$file.new");
    $idone = 0;
    while(<H>) {    
        if($idone == 2) {
            next if /^\s*$/ or /^\s*<(P|BR)>\s*$/;
            print N "<HR>" unless /<HR>/;
            $idone = 3;
        }
        print N $_;        
        if($idone == 1) {
            print N $index;
            $idone = 2;
        }
        if(/<A HREF=.*>Back/ and not $idone) {
            $idone = 1;
        }
    }
    close(H);
    close(N);
    unlink("html/$file.html");
    rename("html/$file.new", "html/$file.html");
}

#$exists = Win32::GUI::FindWindow(
#    '', 
#    'Win32::GUI Documentation - Microsoft Internet Explorer',
#);
#if($exists) {
#    print "window is a ", Win32::GUI::GetClassName($exists), "\n";
#    Win32::GUI::BringWindowToTop($exists);
#} else {
#    system("start html\\gui.html");
#}