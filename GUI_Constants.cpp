/*
###########################################################################
# Win32::GUI Constants
# $Id: GUI_Constants.cpp,v 1.5 2004/05/31 17:41:29 lrocher Exp $
###########################################################################
*/
#include "GUI.h"

DWORD
constant(NOTXSPROC char *name, int arg) {
    errno = 0;
    switch (*name) {

    case 'A':
        break;
    case 'B':
        if (strEQ(name, "BS_3STATE"))
            #ifdef BS_3STATE
                return BS_3STATE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_AUTO3STATE"))
            #ifdef BS_AUTO3STATE
                return BS_AUTO3STATE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_AUTOCHECKBOX"))
            #ifdef BS_AUTOCHECKBOX
                return BS_AUTOCHECKBOX;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_AUTORADIOBUTTON"))
            #ifdef BS_AUTORADIOBUTTON
                return BS_AUTORADIOBUTTON;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_CHECKBOX"))
            #ifdef BS_CHECKBOX
                return BS_CHECKBOX;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_DEFPUSHBUTTON"))
            #ifdef BS_DEFPUSHBUTTON
                return BS_DEFPUSHBUTTON;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_GROUPBOX"))
            #ifdef BS_GROUPBOX
                return BS_GROUPBOX;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_LEFTTEXT"))
            #ifdef BS_LEFTTEXT
                return BS_LEFTTEXT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_NOTIFY"))
            #ifdef BS_NOTIFY
                return BS_NOTIFY;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_OWNERDRAW"))
            #ifdef BS_OWNERDRAW
                return BS_OWNERDRAW;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_PUSHBUTTON"))
            #ifdef BS_PUSHBUTTON
                return BS_PUSHBUTTON;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_RADIOBUTTON"))
            #ifdef BS_RADIOBUTTON
                return BS_RADIOBUTTON;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_USERBUTTON"))
            #ifdef BS_USERBUTTON
                return BS_USERBUTTON;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_BITMAP"))
            #ifdef BS_BITMAP
                return BS_BITMAP;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_BOTTOM"))
            #ifdef BS_BOTTOM
                return BS_BOTTOM;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_CENTER"))
            #ifdef BS_CENTER
                return BS_CENTER;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_ICON"))
            #ifdef BS_ICON
                return BS_ICON;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_LEFT"))
            #ifdef BS_LEFT
                return BS_LEFT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_MULTILINE"))
            #ifdef BS_MULTILINE
                return BS_MULTILINE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_RIGHT"))
            #ifdef BS_RIGHT
                return BS_RIGHT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_RIGHTBUTTON"))
            #ifdef BS_RIGHTBUTTON
                return BS_RIGHTBUTTON;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_TEXT"))
            #ifdef BS_TEXT
                return BS_TEXT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_TOP"))
            #ifdef BS_TOP
                return BS_TOP;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BS_VCENTER"))
            #ifdef BS_VCENTER
                return BS_VCENTER;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BTNS_AUTOSIZE"))
            #ifdef BTNS_AUTOSIZE
                return BTNS_AUTOSIZE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BTNS_BUTTON"))
            #ifdef BTNS_BUTTON
                return BTNS_BUTTON;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BTNS_CHECK"))
            #ifdef BTNS_CHECK
                return BTNS_CHECK;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BTNS_CHECKGROUP"))
            #ifdef BTNS_CHECKGROUP
                return BTNS_CHECKGROUP;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BTNS_DROPDOWN"))
            #ifdef BTNS_DROPDOWN
                return BTNS_DROPDOWN;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BTNS_GROUP"))
            #ifdef BTNS_GROUP
                return BTNS_GROUP;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BTNS_NOPREFIX"))
            #ifdef BTNS_NOPREFIX
                return BTNS_NOPREFIX;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BTNS_SEP"))
            #ifdef BTNS_SEP
                return BTNS_SEP;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BTNS_SHOWTEXT"))
            #ifdef BTNS_SHOWTEXT
                return BTNS_SHOWTEXT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "BTNS_WHOLEDROPDOWN"))
            #ifdef BTNS_WHOLEDROPDOWN
                return BTNS_WHOLEDROPDOWN;
            #else
                goto not_there;
            #endif
        break;
    case 'C':
        if (strEQ(name, "COLOR_3DFACE"))
            #ifdef COLOR_3DFACE
                return COLOR_3DFACE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "COLOR_ACTIVEBORDER"))
            #ifdef COLOR_ACTIVEBORDER
                return COLOR_ACTIVEBORDER;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "COLOR_ACTIVECAPTION"))
            #ifdef COLOR_ACTIVECAPTION
                return COLOR_ACTIVECAPTION;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "COLOR_APPWORKSPACE"))
            #ifdef COLOR_APPWORKSPACE
                return COLOR_APPWORKSPACE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "COLOR_BACKGROUND"))
            #ifdef COLOR_BACKGROUND
                return COLOR_BACKGROUND;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "COLOR_BTNFACE"))
            #ifdef COLOR_BTNFACE
                return COLOR_BTNFACE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "COLOR_BTNSHADOW"))
            #ifdef COLOR_BTNSHADOW
                return COLOR_BTNSHADOW;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "COLOR_BTNTEXT"))
            #ifdef COLOR_BTNTEXT
                return COLOR_BTNTEXT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "COLOR_CAPTIONTEXT"))
            #ifdef COLOR_CAPTIONTEXT
                return COLOR_CAPTIONTEXT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "COLOR_GRAYTEXT"))
            #ifdef COLOR_GRAYTEXT
                return COLOR_GRAYTEXT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "COLOR_HIGHLIGHT"))
            #ifdef COLOR_HIGHLIGHT
                return COLOR_HIGHLIGHT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "COLOR_HIGHLIGHTTEXT"))
            #ifdef COLOR_HIGHLIGHTTEXT
                return COLOR_HIGHLIGHTTEXT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "COLOR_INACTIVEBORDER"))
            #ifdef COLOR_INACTIVEBORDER
                return COLOR_INACTIVEBORDER;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "COLOR_INACTIVECAPTION"))
            #ifdef COLOR_INACTIVECAPTION
                return COLOR_INACTIVECAPTION;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "COLOR_MENU"))
            #ifdef COLOR_MENU
                return COLOR_MENU;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "COLOR_MENUTEXT"))
            #ifdef COLOR_MENUTEXT
                return COLOR_MENUTEXT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "COLOR_SCROLLBAR"))
            #ifdef COLOR_SCROLLBAR
                return COLOR_SCROLLBAR;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "COLOR_WINDOW"))
            #ifdef COLOR_WINDOW
                return COLOR_WINDOW;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "COLOR_WINDOWFRAME"))
            #ifdef COLOR_WINDOWFRAME
                return COLOR_WINDOWFRAME;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "COLOR_WINDOWTEXT"))
            #ifdef COLOR_WINDOWTEXT
                return COLOR_WINDOWTEXT;
            #else
                goto not_there;
            #endif
        break;
    case 'D':
        if (strEQ(name, "DS_3DLOOK"))
            #ifdef DS_3DLOOK
                return DS_3DLOOK;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "DS_ABSALIGN"))
            #ifdef DS_ABSALIGN
                return DS_ABSALIGN;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "DS_CENTER"))
            #ifdef DS_CENTER
                return DS_CENTER;
            #else
                goto not_there;
            #endif
       if (strEQ(name, "DS_CENTERMOUSE"))
            #ifdef DS_CENTERMOUSE
                return DS_CENTERMOUSE;
            #else
                goto not_there;
            #endif
       if (strEQ(name, "DS_CONTEXTHELP"))
            #ifdef DS_CONTEXTHELP
                return DS_CONTEXTHELP;
            #else
                goto not_there;
            #endif
       if (strEQ(name, "DS_CONTROL"))
            #ifdef DS_CONTROL
                return DS_CONTROL;
            #else
                goto not_there;
            #endif
       if (strEQ(name, "DS_FIXEDSYS"))
            #ifdef DS_FIXEDSYS
                return DS_FIXEDSYS;
            #else
                goto not_there;
            #endif
       if (strEQ(name, "DS_LOCALEDIT"))
            #ifdef DS_LOCALEDIT
                return DS_LOCALEDIT;
            #else
                goto not_there;
            #endif
       if (strEQ(name, "DS_MODALFRAME"))
            #ifdef DS_MODALFRAME
                return DS_MODALFRAME;
            #else
                goto not_there;
            #endif
       if (strEQ(name, "DS_NOFAILCREATE"))
            #ifdef DS_NOFAILCREATE
                return DS_NOFAILCREATE;
            #else
                goto not_there;
            #endif
       if (strEQ(name, "DS_NOIDLEMSG"))
            #ifdef DS_NOIDLEMSG
                return DS_NOIDLEMSG;
            #else
                goto not_there;
            #endif
       if (strEQ(name, "DS_RECURSE"))
            #ifdef DS_RECURSE
                return DS_RECURSE;
            #else
                goto not_there;
            #endif
       if (strEQ(name, "DS_SETFONT"))
            #ifdef DS_SETFONT
                return DS_SETFONT;
            #else
                goto not_there;
            #endif
       if (strEQ(name, "DS_SETFOREGROUND"))
            #ifdef DS_SETFOREGROUND
                return DS_SETFOREGROUND;
            #else
                goto not_there;
            #endif
       if (strEQ(name, "DS_SYSMODAL"))
            #ifdef DS_SYSMODAL
                return DS_SYSMODAL;
            #else
                goto not_there;
            #endif

        if (strEQ(name, "DTS_UPDOWN"))
            #ifdef DS_SYSMODAL
                return DTS_UPDOWN;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "DTS_SHOWNONE"))
            #ifdef DS_SYSMODAL
                return DTS_SHOWNONE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "DTS_SHORTDATEFORMAT"))
            #ifdef DS_SYSMODAL
                return DTS_SHORTDATEFORMAT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "DTS_LONGDATEFORMAT"))
            #ifdef DS_SYSMODAL
                return DTS_LONGDATEFORMAT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "DTS_TIMEFORMAT"))
            #ifdef DS_SYSMODAL
                return DTS_TIMEFORMAT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "DTS_APPCANPARSE"))
            #ifdef DS_SYSMODAL
                return DTS_APPCANPARSE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "DTS_RIGHTALIGN"))
            #ifdef DS_SYSMODAL
                return DTS_RIGHTALIGN;
            #else
                goto not_there;
            #endif
        break;
    case 'E':
        if (strEQ(name, "ES_AUTOHSCROLL"))
            #ifdef ES_AUTOHSCROLL
                return ES_AUTOHSCROLL;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "ES_AUTOVSCROLL"))
            #ifdef ES_AUTOVSCROLL
                return ES_AUTOVSCROLL;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "ES_CENTER"))
            #ifdef ES_CENTER
                return ES_CENTER;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "ES_LEFT"))
            #ifdef ES_LEFT
                return ES_LEFT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "ES_LOWERCASE"))
            #ifdef ES_LOWERCASE
                return ES_LOWERCASE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "ES_MULTILINE"))
            #ifdef ES_MULTILINE
                return ES_MULTILINE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "ES_NOHIDESEL"))
            #ifdef ES_NOHIDESEL
                return ES_NOHIDESEL;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "ES_NUMBER"))
            #ifdef ES_NUMBER
                return ES_NUMBER;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "ES_OEMCONVERT"))
            #ifdef ES_OEMCONVERT
                return ES_OEMCONVERT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "ES_PASSWORD"))
            #ifdef ES_PASSWORD
                return ES_PASSWORD;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "ES_READONLY"))
            #ifdef ES_READONLY
                return ES_READONLY;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "ES_RIGHT"))
            #ifdef ES_RIGHT
                return ES_RIGHT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "ES_UPPERCASE"))
            #ifdef ES_UPPERCASE
                return ES_UPPERCASE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "ES_WANTRETURN"))
            #ifdef ES_WANTRETURN
                return ES_WANTRETURN;
            #else
                goto not_there;
            #endif
        break;
    case 'F':
        break;
    case 'G':
        if (strEQ(name, "GW_CHILD"))
            #ifdef GW_CHILD
                return GW_CHILD;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "GW_HWNDFIRST"))
            #ifdef GW_HWNDFIRST
                return GW_HWNDFIRST;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "GW_HWNDLAST"))
            #ifdef GW_HWNDLAST
                return GW_HWNDLAST;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "GW_HWNDNEXT"))
            #ifdef GW_HWNDNEXT
                return GW_HWNDNEXT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "GW_HWNDPREV"))
            #ifdef GW_HWNDPREV
                return GW_HWNDPREV;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "GW_OWNER"))
            #ifdef GW_OWNER
                return GW_OWNER;
            #else
                goto not_there;
            #endif
        break;
    case 'H':
        break;
    case 'I':
        if (strEQ(name, "IMAGE_BITMAP"))
            #ifdef IMAGE_BITMAP
                return IMAGE_BITMAP;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "IMAGE_CURSOR"))
            #ifdef IMAGE_CURSOR
                return IMAGE_CURSOR;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "IMAGE_ICON"))
            #ifdef IMAGE_ICON
                return IMAGE_ICON;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "IDABORT"))
                return IDABORT;
        if (strEQ(name, "IDCANCEL"))
                return IDCANCEL;
        if (strEQ(name, "IDIGNORE"))
                return IDIGNORE;
        if (strEQ(name, "IDNO"))
                return IDNO;
        if (strEQ(name, "IDOK"))
                return IDOK;
        if (strEQ(name, "IDRETRY"))
                return IDRETRY;
        if (strEQ(name, "IDYES"))
                return IDYES; 
        break;
    case 'J':
        break;
    case 'K':
        break;
    case 'L':
        if (strEQ(name, "LR_DEFAULTCOLOR"))
            #ifdef LR_DEFAULTCOLOR
                return LR_DEFAULTCOLOR;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "LR_MONOCHROME"))
            #ifdef LR_MONOCHROME
                return LR_MONOCHROME;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "LR_COLOR"))
            #ifdef LR_COLOR
                return LR_COLOR;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "LR_COPYRETURNORG"))
            #ifdef LR_COPYRETURNORG
                return LR_COPYRETURNORG;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "LR_COPYDELETEORG"))
            #ifdef LR_COPYDELETEORG
                return LR_COPYDELETEORG;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "LR_LOADFROMFILE"))
            #ifdef LR_LOADFROMFILE
                return LR_LOADFROMFILE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "LR_LOADTRANSPARENT"))
            #ifdef LR_LOADTRANSPARENT
                return LR_LOADTRANSPARENT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "LR_DEFAULTSIZE"))
            #ifdef LR_DEFAULTSIZE
                return LR_DEFAULTSIZE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "LR_LOADMAP3DCOLORS"))
            #ifdef LR_LOADMAP3DCOLORS
                return LR_LOADMAP3DCOLORS;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "LR_CREATEDIBSECTION"))
            #ifdef LR_CREATEDIBSECTION
                return LR_CREATEDIBSECTION;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "LR_COPYFROMRESOURCE"))
            #ifdef LR_COPYFROMRESOURCE
                return LR_COPYFROMRESOURCE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "LR_SHARED"))
            #ifdef LR_SHARED
                return LR_SHARED;
            #else
                goto not_there;
            #endif
        break;
    case 'M':
        if (strEQ(name, "MB_ABORTRETRYIGNORE"))
            #ifdef MB_ABORTRETRYIGNORE
                return MB_ABORTRETRYIGNORE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_OK"))
            #ifdef MB_OK
                return MB_OK;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_OKCANCEL"))
            #ifdef MB_OKCANCEL
                return MB_OKCANCEL;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_RETRYCANCEL"))
            #ifdef MB_RETRYCANCEL
                return MB_RETRYCANCEL;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_YESNO"))
            #ifdef MB_YESNO
                return MB_YESNO;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_YESNOCANCEL"))
            #ifdef MB_YESNOCANCEL
                return MB_YESNOCANCEL;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_ICONEXCLAMATION"))
            #ifdef MB_ICONEXCLAMATION
                return MB_ICONEXCLAMATION;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_ICONWARNING"))
            #ifdef MB_ICONWARNING
                return MB_ICONWARNING;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_ICONINFORMATION"))
            #ifdef MB_ICONINFORMATION
                return MB_ICONINFORMATION;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_ICONASTERISK"))
            #ifdef MB_ICONASTERISK
                return MB_ICONASTERISK;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_ICONQUESTION"))
            #ifdef MB_ICONQUESTION
                return MB_ICONQUESTION;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_ICONSTOP"))
            #ifdef MB_ICONSTOP
                return MB_ICONSTOP;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_ICONERROR"))
            #ifdef MB_ICONERROR
                return MB_ICONERROR;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_ICONHAND"))
            #ifdef MB_ICONHAND
                return MB_ICONHAND;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_DEFBUTTON1"))
            #ifdef MB_DEFBUTTON1
                return MB_DEFBUTTON1;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_DEFBUTTON2"))
            #ifdef MB_DEFBUTTON2
                return MB_DEFBUTTON2;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_DEFBUTTON3"))
            #ifdef MB_DEFBUTTON3
                return MB_DEFBUTTON3;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_DEFBUTTON4"))
            #ifdef MB_DEFBUTTON4
                return MB_DEFBUTTON4;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_APPLMODAL"))
            #ifdef MB_APPLMODAL
                return MB_APPLMODAL;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_SYSTEMMODAL"))
            #ifdef MB_SYSTEMMODAL
                return MB_SYSTEMMODAL;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_TASKMODAL"))
            #ifdef MB_TASKMODAL
                return MB_TASKMODAL;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_DEFAULT_DESKTOP_ONLY"))
            #ifdef MB_DEFAULT_DESKTOP_ONLY
                return MB_DEFAULT_DESKTOP_ONLY;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_HELP"))
            #ifdef MB_HELP
                return MB_HELP;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_RIGHT"))
            #ifdef MB_RIGHT
                return MB_RIGHT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_RTLREADING"))
            #ifdef MB_RTLREADING
                return MB_RTLREADING;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_SETFOREGROUND"))
            #ifdef MB_SETFOREGROUND
                return MB_SETFOREGROUND;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_TOPMOST"))
            #ifdef MB_TOPMOST
                return MB_TOPMOST;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_SERVICE_NOTIFICATION"))
            #ifdef MB_SERVICE_NOTIFICATION
                return MB_SERVICE_NOTIFICATION;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MB_SERVICE_NOTIFICATION_NT3X"))
            #ifdef MB_SERVICE_NOTIFICATION_NT3X
                return MB_SERVICE_NOTIFICATION_NT3X;
            #else
                goto not_there;
            #endif

        if (strEQ(name, "MF_POPUP"))
            #ifdef MF_POPUP
                return MF_POPUP;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "MF_STRING"))
            #ifdef MF_STRING
                return MF_STRING;
            #else
                goto not_there;
            #endif

        break;
    case 'N':
        break;
    case 'O':
        break;
    case 'P':
        break;
    case 'Q':
        break;
    case 'R':
        if (strEQ(name, "RBBS_BREAK"))
            #ifdef RBBS_BREAK
                return RBBS_BREAK;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "RBBS_CHILDEDGE"))
            #ifdef RBBS_CHILDEDGE
                return RBBS_CHILDEDGE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "RBBS_FIXEDBMP"))
            #ifdef RBBS_FIXEDBMP
                return RBBS_FIXEDBMP;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "RBBS_FIXEDSIZE"))
            #ifdef RBBS_FIXEDSIZE
                return RBBS_FIXEDSIZE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "RBBS_GRIPPERALWAYS"))
            #ifdef RBBS_GRIPPERALWAYS
                return RBBS_GRIPPERALWAYS;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "RBBS_HIDDEN"))
            #ifdef RBBS_HIDDEN
                return RBBS_HIDDEN;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "RBBS_NOGRIPPER"))
            #ifdef RBBS_NOGRIPPER
                return RBBS_NOGRIPPER;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "RBBS_NOVERT"))
            #ifdef RBBS_NOVERT 
                return RBBS_NOVERT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "RBBS_VARIABLEHEIGHT"))
            #ifdef RBBS_VARIABLEHEIGHT
                return RBBS_VARIABLEHEIGHT;
            #else
                goto not_there;
            #endif
        break;
    case 'S':
        if (strEQ(name, "SB_LINEUP"))
            #ifdef SB_LINEUP
                return SB_LINEUP;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SB_LINELEFT"))
            #ifdef SB_LINELEFT
                return SB_LINELEFT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SB_LINEDOWN"))
            #ifdef SB_LINEDOWN
                return SB_LINEDOWN;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SB_LINERIGHT"))
            #ifdef SB_LINERIGHT
                return SB_LINERIGHT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SB_PAGEUP"))
            #ifdef SB_PAGEUP
                return SB_PAGEUP;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SB_PAGELEFT"))
            #ifdef SB_PAGELEFT
                return SB_PAGELEFT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SB_PAGEDOWN"))
            #ifdef SB_PAGEDOWN
                return SB_PAGEDOWN;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SB_PAGERIGHT"))
            #ifdef SB_PAGERIGHT
                return SB_PAGERIGHT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SB_THUMBPOSITION"))
            #ifdef SB_THUMBPOSITION
                return SB_THUMBPOSITION;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SB_THUMBTRACK"))
            #ifdef SB_THUMBTRACK
                return SB_THUMBTRACK;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SB_TOP"))
            #ifdef SB_TOP
                return SB_TOP;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SB_LEFT"))
            #ifdef SB_LEFT
                return SB_LEFT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SB_BOTTOM"))
            #ifdef SB_BOTTOM
                return SB_BOTTOM;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SB_RIGHT"))
            #ifdef SB_RIGHT
                return SB_RIGHT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SB_ENDSCROLL"))
            #ifdef SB_ENDSCROLL
                return SB_ENDSCROLL;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SBT_NOBORDERS"))
            #ifdef SBT_NOBORDERS
                return SBT_NOBORDERS;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SBT_POPOUT"))
            #ifdef SBT_POPOUT
                return SBT_POPOUT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SBT_RTLREADING"))
            #ifdef SBT_RTLREADING
                return SBT_RTLREADING;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SBT_OWNERDRAW"))
            #ifdef SBT_OWNERDRAW
                return SBT_OWNERDRAW;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_ARRANGE"))
            #ifdef SM_ARRANGE
                return SM_ARRANGE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CLEANBOOT"))
            #ifdef SM_CLEANBOOT
                return SM_CLEANBOOT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CMOUSEBUTTONS"))
            #ifdef SM_CMOUSEBUTTONS
                return SM_CMOUSEBUTTONS;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXBORDER"))
            #ifdef SM_CXBORDER
                return SM_CXBORDER;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYBORDER"))
            #ifdef SM_CYBORDER
                return SM_CYBORDER;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXCURSOR"))
            #ifdef SM_CXCURSOR
                return SM_CXCURSOR;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYCURSOR"))
            #ifdef SM_CYCURSOR
                return SM_CYCURSOR;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXDLGFRAME"))
            #ifdef SM_CXDLGFRAME
                return SM_CXDLGFRAME;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYDLGFRAME"))
            #ifdef SM_CYDLGFRAME
                return SM_CYDLGFRAME;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXDOUBLECLK"))
            #ifdef SM_CXDOUBLECLK
                return SM_CXDOUBLECLK;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYDOUBLECLK"))
            #ifdef SM_CYDOUBLECLK
                return SM_CYDOUBLECLK;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXDRAG"))
            #ifdef SM_CXDRAG
                return SM_CXDRAG;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYDRAG"))
            #ifdef SM_CYDRAG
                return SM_CYDRAG;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXEDGE"))
            #ifdef SM_CXEDGE
                return SM_CXEDGE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYEDGE"))
            #ifdef SM_CYEDGE
                return SM_CYEDGE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXFIXEDFRAME"))
            #ifdef SM_CXFIXEDFRAME
                return SM_CXFIXEDFRAME;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYFIXEDFRAME"))
            #ifdef SM_CYFIXEDFRAME
                return SM_CYFIXEDFRAME;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXFRAME"))
            #ifdef SM_CXFRAME
                return SM_CXFRAME;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYFRAME"))
            #ifdef SM_CYFRAME
                return SM_CYFRAME;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXFULLSCREEN"))
            #ifdef SM_CXFULLSCREEN
                return SM_CXFULLSCREEN;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYFULLSCREEN"))
            #ifdef SM_CYFULLSCREEN
                return SM_CYFULLSCREEN;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXHSCROLL"))
            #ifdef SM_CXHSCROLL
                return SM_CXHSCROLL;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYHSCROLL"))
            #ifdef SM_CYHSCROLL
                return SM_CYHSCROLL;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXHTHUMB"))
            #ifdef SM_CXHTHUMB
                return SM_CXHTHUMB;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXICON"))
            #ifdef SM_CXICON
                return SM_CXICON;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYICON"))
            #ifdef SM_CYICON
                return SM_CYICON;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXICONSPACING"))
            #ifdef SM_CXICONSPACING
                return SM_CXICONSPACING;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYICONSPACING"))
            #ifdef SM_CYICONSPACING
                return SM_CYICONSPACING;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXMAXIMIZED"))
            #ifdef SM_CXMAXIMIZED
                return SM_CXMAXIMIZED;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYMAXIMIZED"))
            #ifdef SM_CYMAXIMIZED
                return SM_CYMAXIMIZED;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXMAXTRACK"))
            #ifdef SM_CXMAXTRACK
                return SM_CXMAXTRACK;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYMAXTRACK"))
            #ifdef SM_CYMAXTRACK
                return SM_CYMAXTRACK;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXMENUCHECK"))
            #ifdef SM_CXMENUCHECK
                return SM_CXMENUCHECK;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYMENUCHECK"))
            #ifdef SM_CYMENUCHECK
                return SM_CYMENUCHECK;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXMENUSIZE"))
            #ifdef SM_CXMENUSIZE
                return SM_CXMENUSIZE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYMENUSIZE"))
            #ifdef SM_CYMENUSIZE
                return SM_CYMENUSIZE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXMIN"))
            #ifdef SM_CXMIN
                return SM_CXMIN;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYMIN"))
            #ifdef SM_CYMIN
                return SM_CYMIN;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXMINIMIZED"))
            #ifdef SM_CXMINIMIZED
                return SM_CXMINIMIZED;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYMINIMIZED"))
            #ifdef SM_CYMINIMIZED
                return SM_CYMINIMIZED;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXMINSPACING"))
            #ifdef SM_CXMINSPACING
                return SM_CXMINSPACING;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYMINSPACING"))
            #ifdef SM_CYMINSPACING
                return SM_CYMINSPACING;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXMINTRACK"))
            #ifdef SM_CXMINTRACK
                return SM_CXMINTRACK;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYMINTRACK"))
            #ifdef SM_CYMINTRACK
                return SM_CYMINTRACK;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXSCREEN"))
            #ifdef SM_CXSCREEN
                return SM_CXSCREEN;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYSCREEN"))
            #ifdef SM_CYSCREEN
                return SM_CYSCREEN;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXSIZE"))
            #ifdef SM_CXSIZE
                return SM_CXSIZE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYSIZE"))
            #ifdef SM_CYSIZE
                return SM_CYSIZE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXSIZEFRAME"))
            #ifdef SM_CXSIZEFRAME
                return SM_CXSIZEFRAME;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYSIZEFRAME"))
            #ifdef SM_CYSIZEFRAME
                return SM_CYSIZEFRAME;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXSMICON"))
            #ifdef SM_CXSMICON
                return SM_CXSMICON;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYSMICON"))
            #ifdef SM_CYSMICON
                return SM_CYSMICON;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXSMSIZE"))
            #ifdef SM_CXSMSIZE
                return SM_CXSMSIZE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYSMSIZE"))
            #ifdef SM_CYSMSIZE
                return SM_CYSMSIZE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CXVSCROLL"))
            #ifdef SM_CXVSCROLL
                return SM_CXVSCROLL;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYVSCROLL"))
            #ifdef SM_CYVSCROLL
                return SM_CYVSCROLL;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYCAPTION"))
            #ifdef SM_CYCAPTION
                return SM_CYCAPTION;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYKANJIWINDOW"))
            #ifdef SM_CYKANJIWINDOW
                return SM_CYKANJIWINDOW;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYMENU"))
            #ifdef SM_CYMENU
                return SM_CYMENU;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYSMCAPTION"))
            #ifdef SM_CYSMCAPTION
                return SM_CYSMCAPTION;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_CYVTHUMB"))
            #ifdef SM_CYVTHUMB
                return SM_CYVTHUMB;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_DBCSENABLED"))
            #ifdef SM_DBCSENABLED
                return SM_DBCSENABLED;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_DEBUG"))
            #ifdef SM_DEBUG
                return SM_DEBUG;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_MENUDROPALIGNMENT"))
            #ifdef SM_MENUDROPALIGNMENT
                return SM_MENUDROPALIGNMENT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_MIDEASTENABLED"))
            #ifdef SM_MIDEASTENABLED
                return SM_MIDEASTENABLED;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_MOUSEPRESENT"))
            #ifdef SM_MOUSEPRESENT
                return SM_MOUSEPRESENT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_MOUSEWHEELPRESENT"))
            #ifdef SM_MOUSEWHEELPRESENT
                return SM_MOUSEWHEELPRESENT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_NETWORK"))
            #ifdef SM_NETWORK
                return SM_NETWORK;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_PENWINDOWS"))
            #ifdef SM_PENWINDOWS
                return SM_PENWINDOWS;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_SECURE"))
            #ifdef SM_SECURE
                return SM_SECURE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_SHOWSOUNDS"))
            #ifdef SM_SHOWSOUNDS
                return SM_SHOWSOUNDS;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_SLOWMACHINE"))
            #ifdef SM_SLOWMACHINE
                return SM_SLOWMACHINE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "SM_SWAPBUTTON"))
            #ifdef SM_SWAPBUTTON
                return SM_SWAPBUTTON;
            #else
                goto not_there;
            #endif
        break;
    case 'T':
         if (strEQ(name, "TBSTATE_CHECKED"))
             #ifdef TBSTATE_CHECKED
                 return TBSTATE_CHECKED;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTATE_ELLIPSES"))
             #ifdef TBSTATE_ELLIPSES
                 return TBSTATE_ELLIPSES;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTATE_ENABLED"))
             #ifdef TBSTATE_ENABLED
                 return TBSTATE_ENABLED;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTATE_HIDDEN"))
             #ifdef TBSTATE_HIDDEN
                 return TBSTATE_HIDDEN;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTATE_INDETERMINATE"))
             #ifdef TBSTATE_INDETERMINATE
                 return TBSTATE_INDETERMINATE;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTATE_MARKED"))
             #ifdef TBSTATE_MARKED
                 return TBSTATE_MARKED;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTATE_PRESSED"))
             #ifdef TBSTATE_PRESSED
                 return TBSTATE_PRESSED;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTATE_WRAP"))
             #ifdef TBSTATE_WRAP
                 return TBSTATE_WRAP;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTYLE_ALTDRAG"))
             #ifdef TBSTYLE_ALTDRAG
                 return TBSTYLE_ALTDRAG;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTYLE_CUSTOMERASE"))
             #ifdef TBSTYLE_CUSTOMERASE
                 return TBSTYLE_CUSTOMERASE;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTYLE_FLAT"))
             #ifdef TBSTYLE_FLAT
                 return TBSTYLE_FLAT;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTYLE_LIST"))
             #ifdef TBSTYLE_LIST
                 return TBSTYLE_LIST;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTYLE_REGISTERDROP"))
             #ifdef TBSTYLE_REGISTERDROP
                 return TBSTYLE_REGISTERDROP;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTYLE_TOOLTIPS"))
             #ifdef TBSTYLE_TOOLTIPS
                 return TBSTYLE_TOOLTIPS;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTYLE_TRANSPARENT"))
             #ifdef TBSTYLE_TRANSPARENT
                 return TBSTYLE_TRANSPARENT;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTYLE_WRAPABLE"))
             #ifdef TBSTYLE_WRAPABLE
                 return TBSTYLE_WRAPABLE;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTYLE_AUTOSIZE"))
             #ifdef TBSTYLE_AUTOSIZE
                 return TBSTYLE_AUTOSIZE;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTYLE_BUTTON"))
             #ifdef TBSTYLE_BUTTON
                 return TBSTYLE_BUTTON;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTYLE_CHECK"))
             #ifdef TBSTYLE_CHECK
                 return TBSTYLE_CHECK;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTYLE_CHECKGROUP"))
             #ifdef TBSTYLE_CHECKGROUP
                 return TBSTYLE_CHECKGROUP;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTYLE_DROPDOWN"))
             #ifdef TBSTYLE_DROPDOWN
                 return TBSTYLE_DROPDOWN;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTYLE_GROUP"))
             #ifdef TBSTYLE_GROUP
                 return TBSTYLE_GROUP;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTYLE_NOPREFIX"))
             #ifdef TBSTYLE_NOPREFIX
                 return TBSTYLE_NOPREFIX;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTYLE_SEP"))
             #ifdef TBSTYLE_SEP
                 return TBSTYLE_SEP;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTYLE_EX_DRAWDDARROWS"))
             #ifdef TBSTYLE_EX_DRAWDDARROWS
                 return TBSTYLE_EX_DRAWDDARROWS;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTYLE_EX_HIDECLIPPEDBUTTONS"))
             #ifdef TBSTYLE_EX_HIDECLIPPEDBUTTONS
                 return TBSTYLE_EX_HIDECLIPPEDBUTTONS;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBSTYLE_EX_MIXEDBUTTONS"))
             #ifdef TBSTYLE_EX_MIXEDBUTTONS
                 return TBSTYLE_EX_MIXEDBUTTONS;
             #else
                 goto not_there;
             #endif    
         if (strEQ(name, "TBTS_TOP"))
             #ifdef TBTS_TOP
                 return TBTS_TOP;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBTS_LEFT"))
             #ifdef TBTS_LEFT
                 return TBTS_LEFT;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBTS_BOTTOM"))
             #ifdef TBTS_BOTTOM
                 return TBTS_BOTTOM;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TBTS_RIGHT"))
             #ifdef TBTS_RIGHT
                 return TBTS_RIGHT;
             #else
                 goto not_there;
             #endif
         if (strEQ(name, "TPM_LEFTBUTTON"))         
             #ifdef TPM_LEFTBUTTON                  
                 return TPM_LEFTBUTTON;             
             #else                                  
                 goto not_there;                    
             #endif                                 
         if (strEQ(name, "TPM_RIGHTBUTTON"))        
             #ifdef TPM_RIGHTBUTTON                 
                 return TPM_RIGHTBUTTON;            
             #else                                  
                 goto not_there;                    
             #endif                                 
         if (strEQ(name, "TPM_LEFTALIGN"))          
             #ifdef TPM_LEFTALIGN                   
                 return TPM_LEFTALIGN;              
             #else                                  
                 goto not_there;                    
             #endif                                 
         if (strEQ(name, "TPM_CENTERALIGN"))        
             #ifdef TPM_CENTERALIGN                 
                 return TPM_CENTERALIGN;            
             #else                                  
                 goto not_there;                    
             #endif                                 
         if (strEQ(name, "TPM_RIGHTALIGN"))         
             #ifdef TPM_RIGHTALIGN                  
                 return TPM_RIGHTALIGN;             
             #else                                  
                 goto not_there;                    
             #endif                                 
         if (strEQ(name, "TPM_TOPALIGN"))           
             #ifdef TPM_TOPALIGN                    
                 return TPM_TOPALIGN;               
             #else                                  
                 goto not_there;                    
             #endif                                 
         if (strEQ(name, "TPM_VCENTERALIGN"))       
             #ifdef TPM_VCENTERALIGN                
                 return TPM_VCENTERALIGN;           
             #else                                  
                 goto not_there;                    
             #endif                                 
         if (strEQ(name, "TPM_BOTTOMALIGN"))        
             #ifdef TPM_BOTTOMALIGN                 
                 return TPM_BOTTOMALIGN;            
             #else                                  
                 goto not_there;                    
             #endif                                 
         if (strEQ(name, "TPM_HORIZONTAL"))         
             #ifdef TPM_HORIZONTAL                  
                 return TPM_HORIZONTAL;             
             #else                                  
                 goto not_there;                    
             #endif                                 
         if (strEQ(name, "TPM_VERTICAL"))           
             #ifdef TPM_VERTICAL                    
                 return TPM_VERTICAL;               
             #else                                  
                 goto not_there;                    
             #endif                                 
         if (strEQ(name, "TMP_NONOTIFY"))           
             #ifdef TMP_NONOTIFY                    
                 return TMP_NONOTIFY;               
             #else                                  
                 goto not_there;                    
             #endif                                 
         if (strEQ(name, "TPM_RETURNCMD"))          
             #ifdef TPM_RETURNCMD                   
                 return TPM_RETURNCMD;              
             #else                                  
                 goto not_there;                    
             #endif                                 
         if (strEQ(name, "TPM_RECURSE"))            
             #ifdef TPM_RECURSE                     
                 return TPM_RECURSE;                
             #else                                  
                 goto not_there;                    
             #endif                                     
         if (strEQ(name, "TVGN_CARET"))            
             #ifdef TVGN_CARET                     
                 return TVGN_CARET;                
             #else                                  
                 goto not_there;                    
             #endif      
         if (strEQ(name, "TVGN_CHILD"))            
             #ifdef TVGN_CHILD                     
                 return TVGN_CHILD;                
             #else                                  
                 goto not_there;                    
             #endif      
         if (strEQ(name, "TVGN_DROPHILITE"))            
             #ifdef TVGN_DROPHILITE                     
                 return TVGN_DROPHILITE;                
             #else                                  
                 goto not_there;                    
             #endif     
         if (strEQ(name, "TVGN_FIRSTVISIBLE"))            
             #ifdef TVGN_FIRSTVISIBLE                     
                 return TVGN_FIRSTVISIBLE;                
             #else                                  
                 goto not_there;                    
             #endif     
         if (strEQ(name, "TVGN_NEXT"))            
             #ifdef TVGN_NEXT                     
                 return TVGN_NEXT;                
             #else                                  
                 goto not_there;                    
             #endif     
         if (strEQ(name, "TVGN_NEXTVISIBLE"))            
             #ifdef TVGN_NEXTVISIBLE                     
                 return TVGN_NEXTVISIBLE;                
             #else                                  
                 goto not_there;                    
             #endif     
         if (strEQ(name, "TVGN_PARENT"))            
             #ifdef TVGN_PARENT                     
                 return TVGN_PARENT;                
             #else                                  
                 goto not_there;                    
             #endif 
         if (strEQ(name, "TVGN_PREVIOUS"))            
             #ifdef TVGN_PREVIOUS                     
                 return TVGN_PREVIOUS;                
             #else                                  
                 goto not_there;                    
             #endif 
         if (strEQ(name, "TVGN_PREVIOUSVISIBLE"))            
             #ifdef TVGN_PREVIOUSVISIBLE                     
                 return TVGN_PREVIOUSVISIBLE;                
             #else                                  
                 goto not_there;                    
             #endif 
         if (strEQ(name, "TVGN_ROOT"))            
             #ifdef TVGN_ROOT                     
                 return TVGN_ROOT;                
             #else                                  
                 goto not_there;                    
             #endif 
        break;
    case 'U':
        break;
    case 'V':
        break;
    case 'W':

        if (strEQ(name, "WIN32__GUI__WINDOW"))
            return WIN32__GUI__WINDOW;
        else if (strEQ(name, "WIN32__GUI__DIALOG"))
            return WIN32__GUI__DIALOG;
        else if (strEQ(name, "WIN32__GUI__STATIC"))
            return WIN32__GUI__STATIC;
        else if (strEQ(name, "WIN32__GUI__BUTTON"))
            return WIN32__GUI__BUTTON;
        else if (strEQ(name, "WIN32__GUI__EDIT"))
            return WIN32__GUI__EDIT;
        else if (strEQ(name, "WIN32__GUI__LISTBOX"))
            return WIN32__GUI__LISTBOX;
        else if (strEQ(name, "WIN32__GUI__COMBOBOX"))
            return WIN32__GUI__COMBOBOX;
        else if (strEQ(name, "WIN32__GUI__CHECKBOX"))
            return WIN32__GUI__CHECKBOX;
        else if (strEQ(name, "WIN32__GUI__RADIOBUTTON"))
            return WIN32__GUI__RADIOBUTTON;
        else if (strEQ(name, "WIN32__GUI__TOOLBAR"))
            return WIN32__GUI__TOOLBAR;
        else if (strEQ(name, "WIN32__GUI__PROGRESS"))
            return WIN32__GUI__PROGRESS;
        else if (strEQ(name, "WIN32__GUI__STATUS"))
            return WIN32__GUI__STATUS;
        else if (strEQ(name, "WIN32__GUI__TAB"))
            return WIN32__GUI__TAB;
        else if (strEQ(name, "WIN32__GUI__RICHEDIT"))
            return WIN32__GUI__RICHEDIT;
        else if (strEQ(name, "WIN32__GUI__LISTVIEW"))
            return WIN32__GUI__LISTVIEW;
        else if (strEQ(name, "WIN32__GUI__TREEVIEW"))
            return WIN32__GUI__TREEVIEW;
        else if (strEQ(name, "WIN32__GUI__TRACKBAR"))
            return WIN32__GUI__TRACKBAR;
        else if (strEQ(name, "WIN32__GUI__UPDOWN"))
            return WIN32__GUI__UPDOWN;
        else if (strEQ(name, "WIN32__GUI__TOOLTIP"))
            return WIN32__GUI__TOOLTIP;
        else if (strEQ(name, "WIN32__GUI__ANIMATION"))
            return WIN32__GUI__ANIMATION;
        else if (strEQ(name, "WIN32__GUI__REBAR"))
            return WIN32__GUI__REBAR;
        else if (strEQ(name, "WIN32__GUI__HEADER"))
            return WIN32__GUI__HEADER;
        else if (strEQ(name, "WIN32__GUI__COMBOBOXEX"))
            return WIN32__GUI__COMBOBOXEX;
        else if (strEQ(name, "WIN32__GUI__DTPICK"))
            return WIN32__GUI__DTPICK;
        else if (strEQ(name, "WIN32__GUI__GRAPHIC"))
            return WIN32__GUI__GRAPHIC;
        else if (strEQ(name, "WIN32__GUI__GROUPBOX"))
            return WIN32__GUI__GROUPBOX;
        else if (strEQ(name, "WIN32__GUI__SPLITTER"))
            return WIN32__GUI__SPLITTER;
        else if (strEQ(name, "WIN32__GUI__MDIFRAME"))
            return WIN32__GUI__MDIFRAME;
        else if (strEQ(name, "WIN32__GUI__MDICLIENT"))
            return WIN32__GUI__MDICLIENT;
        else if (strEQ(name, "WIN32__GUI__MDICHILD"))
            return WIN32__GUI__MDICHILD;
        else if (strEQ(name, "WIN32__GUI__MONTHCAL"))
            return WIN32__GUI__MONTHCAL;

        if (strEQ(name, "WM_CREATE"))
            #ifdef WM_CREATE
                return WM_CREATE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WM_DESTROY"))
            #ifdef WM_DESTROY
                return WM_DESTROY;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WM_MOVE"))
            #ifdef WM_MOVE
                return WM_MOVE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WM_SIZE"))
            #ifdef WM_SIZE
                return WM_SIZE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WM_ACTIVATE"))
            #ifdef WM_ACTIVATE
                return WM_ACTIVATE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WM_SETFOCUS"))
            #ifdef WM_SETFOCUS
                return WM_SETFOCUS;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WM_KILLFOCUS"))
            #ifdef WM_KILLFOCUS
                return WM_KILLFOCUS;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WM_ENABLE"))
            #ifdef WM_ENABLE
                return WM_ENABLE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WM_SETREDRAW"))
            #ifdef WM_SETREDRAW
                return WM_SETREDRAW;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WM_COMMAND"))
            #ifdef WM_COMMAND
                return WM_COMMAND;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WM_KEYDOWN"))
            #ifdef WM_KEYDOWN
                return WM_KEYDOWN;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WM_SETCURSOR"))
            #ifdef WM_SETCURSOR
                return WM_SETCURSOR;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WM_KEYUP"))
            #ifdef WM_KEYUP
                return WM_KEYUP;
            #else
                goto not_there;
            #endif

        if (strEQ(name, "WS_BORDER"))
            #ifdef WS_BORDER
                return WS_BORDER;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_CAPTION"))
            #ifdef WS_CAPTION
                return WS_CAPTION;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_CHILD"))
            #ifdef WS_CHILD
                return WS_CHILD;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_CHILDWINDOW"))
            #ifdef WS_CHILDWINDOW
                return WS_CHILDWINDOW;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_CLIPCHILDREN"))
            #ifdef WS_CLIPCHILDREN
                return WS_CLIPCHILDREN;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_CLIPSIBLINGS"))
            #ifdef WS_CLIPSIBLINGS
                return WS_CLIPSIBLINGS;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_DISABLED"))
            #ifdef WS_DISABLED
                return WS_DISABLED;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_DLGFRAME"))
            #ifdef WS_DLGFRAME
                return WS_DLGFRAME;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_GROUP"))
            #ifdef WS_GROUP
                return WS_GROUP;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_HSCROLL"))
            #ifdef WS_HSCROLL
                return WS_HSCROLL;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_ICONIC"))
            #ifdef WS_ICONIC
                return WS_ICONIC;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_MAXIMIZE"))
            #ifdef WS_MAXIMIZE
                return WS_MAXIMIZE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_MAXIMIZEBOX"))
            #ifdef WS_MAXIMIZEBOX
                return WS_MAXIMIZEBOX;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_MINIMIZE"))
            #ifdef WS_MINIMIZE
                return WS_MINIMIZE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_MINIMIZEBOX"))
            #ifdef WS_MINIMIZEBOX
                return WS_MINIMIZEBOX;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_OVERLAPPED"))
            #ifdef WS_OVERLAPPED
                return WS_OVERLAPPED;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_OVERLAPPEDWINDOW"))
            #ifdef WS_OVERLAPPEDWINDOW
                return WS_OVERLAPPEDWINDOW;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_POPUP"))
            #ifdef WS_POPUP
                return WS_POPUP;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_POPUPWINDOW"))
            #ifdef WS_POPUPWINDOW
                return WS_POPUPWINDOW;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_SIZEBOX"))
            #ifdef WS_SIZEBOX
                return WS_SIZEBOX;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_SYSMENU"))
            #ifdef WS_SYSMENU
                return WS_SYSMENU;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_TABSTOP"))
            #ifdef WS_TABSTOP
                return WS_TABSTOP;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_THICKFRAME"))
            #ifdef WS_THICKFRAME
                return WS_THICKFRAME;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_TILED"))
            #ifdef WS_TILED
                return WS_TILED;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_TILEDWINDOW"))
            #ifdef WS_TILEDWINDOW
                return WS_TILEDWINDOW;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_VISIBLE"))
            #ifdef WS_VISIBLE
                return WS_VISIBLE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_VSCROLL"))
            #ifdef WS_VSCROLL
                return WS_VSCROLL;
            #else
                goto not_there;
            #endif


        if (strEQ(name, "WS_EX_ACCEPTFILES"))
            #ifdef WS_EX_ACCEPTFILES
                return WS_EX_ACCEPTFILES;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_EX_APPWINDOW"))
            #ifdef WS_EX_APPWINDOW
                return WS_EX_APPWINDOW;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_EX_CLIENTEDGE"))
            #ifdef WS_EX_CLIENTEDGE
                return WS_EX_CLIENTEDGE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_EX_CONTEXTHELP"))
            #ifdef WS_EX_CONTEXTHELP
                return WS_EX_CONTEXTHELP;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_EX_CONTROLPARENT"))
            #ifdef WS_EX_CONTROLPARENT
                return WS_EX_CONTROLPARENT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_EX_DLGMODALFRAME"))
            #ifdef WS_EX_DLGMODALFRAME
                return WS_EX_DLGMODALFRAME;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_EX_LEFT"))
            #ifdef WS_EX_LEFT
                return WS_EX_LEFT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_EX_LEFTSCROLLBAR"))
            #ifdef WS_EX_LEFTSCROLLBAR
                return WS_EX_LEFTSCROLLBAR;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_EX_LTRREADING"))
            #ifdef WS_EX_LTRREADING
                return WS_EX_LTRREADING;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_EX_MDICHILD"))
            #ifdef WS_EX_MDICHILD
                return WS_EX_MDICHILD;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_EX_NOPARENTNOTIFY"))
            #ifdef WS_EX_NOPARENTNOTIFY
                return WS_EX_NOPARENTNOTIFY;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_EX_OVERLAPPEDWINDOW"))
            #ifdef WS_EX_OVERLAPPEDWINDOW
                return WS_EX_OVERLAPPEDWINDOW;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_EX_PALETTEWINDOW"))
            #ifdef WS_EX_PALETTEWINDOW
                return WS_EX_PALETTEWINDOW;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_EX_RIGHT"))
            #ifdef WS_EX_RIGHT
                return WS_EX_RIGHT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_EX_RIGHTSCROLLBAR"))
            #ifdef WS_EX_RIGHTSCROLLBAR
                return WS_EX_RIGHTSCROLLBAR;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_EX_RTLREADING"))
            #ifdef WS_EX_RTLREADING
                return WS_EX_RTLREADING;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_EX_STATICEDGE"))
            #ifdef WS_EX_STATICEDGE
                return WS_EX_STATICEDGE;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_EX_TOOLWINDOW"))
            #ifdef WS_EX_TOOLWINDOW
                return WS_EX_TOOLWINDOW;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_EX_TOPMOST"))
            #ifdef WS_EX_TOPMOST
                return WS_EX_TOPMOST;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_EX_TRANSPARENT"))
            #ifdef WS_EX_TRANSPARENT
                return WS_EX_TRANSPARENT;
            #else
                goto not_there;
            #endif
        if (strEQ(name, "WS_EX_WINDOWEDGE"))
            #ifdef WS_EX_WINDOWEDGE
                return WS_EX_WINDOWEDGE;
            #else
                goto not_there;
            #endif
        break;
    case 'X':
        break;
    case 'Y':
        break;
    case 'Z':
        break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}
