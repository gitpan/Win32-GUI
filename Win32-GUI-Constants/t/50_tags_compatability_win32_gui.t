#!perl -wT
# Win32::GUI::Constants test suite
# $Id: 50_tags_compatability_win32_gui.t,v 1.1 2006/05/13 15:39:30 robertemay Exp $
#

use strict;
use warnings;

BEGIN { $| = 1 } # Autoflush

# Check that the :compatability_win32_gui export tag actually exports
# the same symbols as Win32::GUI currently does.

use Test::More tests => 2;

require Win32::GUI::Constants::Tags;

my @W32G_NEW = @{Win32::GUI::Constants::Tags::tag('compatibility_win32_gui')};

# Copied from GUI.pm, with DS_RECURSE removed, as it doesn't seem to exist
my @W32G_ORIG =  qw(
    BS_3STATE
    BS_AUTO3STATE
    BS_AUTOCHECKBOX
    BS_AUTORADIOBUTTON
    BS_CHECKBOX
    BS_DEFPUSHBUTTON
    BS_GROUPBOX
    BS_LEFTTEXT
    BS_NOTIFY
    BS_OWNERDRAW
    BS_PUSHBUTTON
    BS_RADIOBUTTON
    BS_USERBUTTON
    BS_BITMAP
    BS_BOTTOM
    BS_CENTER
    BS_ICON
    BS_LEFT
    BS_MULTILINE
    BS_RIGHT
    BS_RIGHTBUTTON
    BS_TEXT
    BS_TOP
    BS_VCENTER

    COLOR_3DFACE
    COLOR_ACTIVEBORDER
    COLOR_ACTIVECAPTION
    COLOR_APPWORKSPACE
    COLOR_BACKGROUND
    COLOR_BTNFACE
    COLOR_BTNSHADOW
    COLOR_BTNTEXT
    COLOR_CAPTIONTEXT
    COLOR_GRAYTEXT
    COLOR_HIGHLIGHT
    COLOR_HIGHLIGHTTEXT
    COLOR_INACTIVEBORDER
    COLOR_INACTIVECAPTION
    COLOR_MENU
    COLOR_MENUTEXT
    COLOR_SCROLLBAR
    COLOR_WINDOW
    COLOR_WINDOWFRAME
    COLOR_WINDOWTEXT

    DS_3DLOOK
    DS_ABSALIGN
    DS_CENTER
    DS_CENTERMOUSE
    DS_CONTEXTHELP
    DS_CONTROL
    DS_FIXEDSYS
    DS_LOCALEDIT
    DS_MODALFRAME
    DS_NOFAILCREATE
    DS_NOIDLEMSG
    DS_SETFONT
    DS_SETFOREGROUND
    DS_SYSMODAL

    DTS_UPDOWN
    DTS_SHOWNONE
    DTS_SHORTDATEFORMAT
    DTS_LONGDATEFORMAT
    DTS_TIMEFORMAT
    DTS_APPCANPARSE
    DTS_RIGHTALIGN

    ES_AUTOHSCROLL
    ES_AUTOVSCROLL
    ES_CENTER
    ES_LEFT
    ES_LOWERCASE
    ES_MULTILINE
    ES_NOHIDESEL
    ES_NUMBER
    ES_OEMCONVERT
    ES_PASSWORD
    ES_READONLY
    ES_RIGHT
    ES_UPPERCASE
    ES_WANTRETURN

    GW_CHILD
    GW_HWNDFIRST
    GW_HWNDLAST
    GW_HWNDNEXT
    GW_HWNDPREV
    GW_OWNER

    IMAGE_BITMAP
    IMAGE_CURSOR
    IMAGE_ICON

    IDABORT
    IDCANCEL
    IDIGNORE
    IDNO
    IDOK
    IDRETRY
    IDYES

    LR_DEFAULTCOLOR
    LR_MONOCHROME
    LR_COLOR
    LR_COPYRETURNORG
    LR_COPYDELETEORG
    LR_LOADFROMFILE
    LR_LOADTRANSPARENT
    LR_DEFAULTSIZE
    LR_LOADMAP3DCOLORS
    LR_CREATEDIBSECTION
    LR_COPYFROMRESOURCE
    LR_SHARED

    MB_ABORTRETRYIGNORE
    MB_OK
    MB_OKCANCEL
    MB_RETRYCANCEL
    MB_YESNO
    MB_YESNOCANCEL
    MB_ICONEXCLAMATION
    MB_ICONWARNING
    MB_ICONINFORMATION
    MB_ICONASTERISK
    MB_ICONQUESTION
    MB_ICONSTOP
    MB_ICONERROR
    MB_ICONHAND
    MB_DEFBUTTON1
    MB_DEFBUTTON2
    MB_DEFBUTTON3
    MB_DEFBUTTON4
    MB_APPLMODAL
    MB_SYSTEMMODAL
    MB_TASKMODAL
    MB_DEFAULT_DESKTOP_ONLY
    MB_HELP
    MB_RIGHT
    MB_RTLREADING
    MB_SETFOREGROUND
    MB_TOPMOST
    MB_SERVICE_NOTIFICATION
    MB_SERVICE_NOTIFICATION_NT3X

    MF_STRING
    MF_POPUP

    RBBS_BREAK
    RBBS_CHILDEDGE
    RBBS_FIXEDBMP
    RBBS_FIXEDSIZE
    RBBS_GRIPPERALWAYS
    RBBS_HIDDEN
    RBBS_NOGRIPPER
    RBBS_NOVERT
    RBBS_VARIABLEHEIGHT

    SB_LINEUP
    SB_LINELEFT
    SB_LINEDOWN
    SB_LINERIGHT
    SB_PAGEUP
    SB_PAGELEFT
    SB_PAGEDOWN
    SB_PAGERIGHT
    SB_THUMBPOSITION
    SB_THUMBTRACK
    SB_TOP
    SB_LEFT
    SB_BOTTOM
    SB_RIGHT
    SB_ENDSCROLL

    SBT_POPOUT
    SBT_RTLREADING
    SBT_NOBORDERS
    SBT_OWNERDRAW

    SM_ARRANGE
    SM_CLEANBOOT
    SM_CMOUSEBUTTONS
    SM_CXBORDER
    SM_CYBORDER
    SM_CXCURSOR
    SM_CYCURSOR
    SM_CXDLGFRAME
    SM_CYDLGFRAME
    SM_CXDOUBLECLK
    SM_CYDOUBLECLK
    SM_CXDRAG
    SM_CYDRAG
    SM_CXEDGE
    SM_CYEDGE
    SM_CXFIXEDFRAME
    SM_CYFIXEDFRAME
    SM_CXFRAME
    SM_CYFRAME
    SM_CXFULLSCREEN
    SM_CYFULLSCREEN
    SM_CXHSCROLL
    SM_CYHSCROLL
    SM_CXHTHUMB
    SM_CXICON
    SM_CYICON
    SM_CXICONSPACING
    SM_CYICONSPACING
    SM_CXMAXIMIZED
    SM_CYMAXIMIZED
    SM_CXMAXTRACK
    SM_CYMAXTRACK
    SM_CXMENUCHECK
    SM_CYMENUCHECK
    SM_CXMENUSIZE
    SM_CYMENUSIZE
    SM_CXMIN
    SM_CYMIN
    SM_CXMINIMIZED
    SM_CYMINIMIZED
    SM_CXMINSPACING
    SM_CYMINSPACING
    SM_CXMINTRACK
    SM_CYMINTRACK
    SM_CXSCREEN
    SM_CYSCREEN
    SM_CXSIZE
    SM_CYSIZE
    SM_CXSIZEFRAME
    SM_CYSIZEFRAME
    SM_CXSMICON
    SM_CYSMICON
    SM_CXSMSIZE
    SM_CYSMSIZE
    SM_CXVSCROLL
    SM_CYVSCROLL
    SM_CYCAPTION
    SM_CYKANJIWINDOW
    SM_CYMENU
    SM_CYSMCAPTION
    SM_CYVTHUMB
    SM_DBCSENABLED
    SM_DEBUG
    SM_MENUDROPALIGNMENT
    SM_MIDEASTENABLED
    SM_MOUSEPRESENT
    SM_MOUSEWHEELPRESENT
    SM_NETWORK
    SM_PENWINDOWS
    SM_SECURE
    SM_SHOWSOUNDS
    SM_SLOWMACHINE
    SM_SWAPBUTTON

    TPM_LEFTBUTTON
    TPM_RIGHTBUTTON
    TPM_LEFTALIGN
    TPM_CENTERALIGN
    TPM_RIGHTALIGN
    TPM_TOPALIGN
    TPM_VCENTERALIGN
    TPM_BOTTOMALIGN
    TPM_HORIZONTAL
    TPM_VERTICAL
    TPM_NONOTIFY
    TPM_RETURNCMD
    TPM_RECURSE

    TBSTATE_CHECKED
    TBSTATE_ELLIPSES
    TBSTATE_ENABLED
    TBSTATE_HIDDEN
    TBSTATE_INDETERMINATE
    TBSTATE_MARKED
    TBSTATE_PRESSED
    TBSTATE_WRAP

    TBSTYLE_ALTDRAG
    TBSTYLE_CUSTOMERASE
    TBSTYLE_FLAT
    TBSTYLE_LIST
    TBSTYLE_REGISTERDROP
    TBSTYLE_TOOLTIPS
    TBSTYLE_TRANSPARENT
    TBSTYLE_WRAPABLE

    BTNS_AUTOSIZE
    BTNS_BUTTON
    BTNS_CHECK
    BTNS_CHECKGROUP
    BTNS_DROPDOWN
    BTNS_GROUP
    BTNS_NOPREFIX
    BTNS_SEP
    BTNS_SHOWTEXT
    BTNS_WHOLEDROPDOWN

    TBSTYLE_AUTOSIZE
    TBSTYLE_BUTTON
    TBSTYLE_CHECK
    TBSTYLE_CHECKGROUP
    TBSTYLE_DROPDOWN
    TBSTYLE_GROUP
    TBSTYLE_NOPREFIX
    TBSTYLE_SEP

    TBSTYLE_EX_DRAWDDARROWS
    TBSTYLE_EX_HIDECLIPPEDBUTTONS
    TBSTYLE_EX_MIXEDBUTTONS

    TBTS_TOP
    TBTS_LEFT
    TBTS_BOTTOM
    TBTS_RIGHT

    TVGN_CARET
    TVGN_CHILD
    TVGN_DROPHILITE
    TVGN_FIRSTVISIBLE
    TVGN_NEXT
    TVGN_NEXTVISIBLE
    TVGN_PARENT
    TVGN_PREVIOUS
    TVGN_PREVIOUSVISIBLE
    TVGN_ROOT

    WM_CREATE
    WM_DESTROY
    WM_MOVE
    WM_SIZE
    WM_ACTIVATE
    WM_SETFOCUS
    WM_KILLFOCUS
    WM_ENABLE
    WM_SETREDRAW
    WM_COMMAND
    WM_KEYDOWN
    WM_SETCURSOR
    WM_KEYUP

    WS_BORDER
    WS_CAPTION
    WS_CHILD
    WS_CHILDWINDOW
    WS_CLIPCHILDREN
    WS_CLIPSIBLINGS
    WS_DISABLED
    WS_DLGFRAME
    WS_GROUP
    WS_HSCROLL
    WS_ICONIC
    WS_MAXIMIZE
    WS_MAXIMIZEBOX
    WS_MINIMIZE
    WS_MINIMIZEBOX
    WS_OVERLAPPED
    WS_OVERLAPPEDWINDOW
    WS_POPUP
    WS_POPUPWINDOW
    WS_SIZEBOX
    WS_SYSMENU
    WS_TABSTOP
    WS_THICKFRAME
    WS_TILED
    WS_TILEDWINDOW
    WS_VISIBLE
    WS_VSCROLL

    WS_EX_ACCEPTFILES
    WS_EX_APPWINDOW
    WS_EX_CLIENTEDGE
    WS_EX_CONTEXTHELP
    WS_EX_CONTROLPARENT
    WS_EX_DLGMODALFRAME
    WS_EX_LEFT
    WS_EX_LEFTSCROLLBAR
    WS_EX_LTRREADING
    WS_EX_MDICHILD
    WS_EX_NOPARENTNOTIFY
    WS_EX_OVERLAPPEDWINDOW
    WS_EX_PALETTEWINDOW
    WS_EX_RIGHT
    WS_EX_RIGHTSCROLLBAR
    WS_EX_RTLREADING
    WS_EX_STATICEDGE
    WS_EX_TOOLWINDOW
    WS_EX_TOPMOST
    WS_EX_TRANSPARENT
    WS_EX_WINDOWEDGE
);

#both lists the same size?
ok(@W32G_ORIG == @W32G_NEW, "Old and new export lists are the same size");

#both lists contain the same items?
my %h;
for my $item (@W32G_ORIG, @W32G_NEW) {
	$h{$item}++;
}
my @errors;
for my $item (keys %h) {
	next if $h{$item} == 2;
	push @errors, $item;
}
ok(!@errors, "Lists have no differing items (@errors)");


