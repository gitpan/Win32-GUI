@echo off
del pod\pod2html*
perl dodoc.pl
perl dohtml.pl
