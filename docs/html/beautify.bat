@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
perl -pi "%0" *.html
goto endofperl
:WinNT
perl -pi "%0" *.html
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
goto endofperl
@rem ';
    s/<BODY.*>/<BODY BGCOLOR=red TEXT=white>/i;
__END__
:endofperl
