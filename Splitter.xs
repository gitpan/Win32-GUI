    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Splitter
    #
    # $Id: Splitter.xs,v 1.4 2005/08/03 21:45:57 robertemay Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

void 
Splitter_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = "Win32::GUI::Splitter(vertical)";
    perlcs->cs.style = WS_VISIBLE | WS_CHILD;
    perlcs->cs.dwExStyle = WS_EX_NOPARENTNOTIFY;
}

BOOL
Splitter_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    SV* storing;
    SV** stored;
    BOOL retval = TRUE;

    if(strcmp(option, "-horizontal") == 0) {
        if(SvIV(value)) {
            perlcs->cs.lpszClass = "Win32::GUI::Splitter(horizontal)";
        } else {
            perlcs->cs.lpszClass = "Win32::GUI::Splitter(vertical)";
        }
        SwitchBit(perlcs->dwPlStyle, PERLWIN32GUI_HORIZONTAL, SvIV(value));
    } else if(strcmp(option, "-min") == 0) {
        storing = newSViv((LONG) SvIV(value));
        stored = hv_store_mg(NOTXSCALL perlcs->hvSelf, "-min", 4, storing, 0);
        perlcs->iMinWidth = SvIV(value);
    } else if(strcmp(option, "-max") == 0) {
        storing = newSViv((LONG) SvIV(value));
        stored = hv_store_mg(NOTXSCALL perlcs->hvSelf, "-max", 4, storing, 0);
        perlcs->iMaxWidth = SvIV(value);
    } else if(strcmp(option, "-range") == 0) {
        if(SvROK(value) && SvTYPE(SvRV(value)) == SVt_PVAV) {
            SV** t;
            t = av_fetch((AV*)SvRV(value), 0, 0);
            if(t != NULL) {
                storing = newSViv((LONG) SvIV(*t));
                stored = hv_store_mg(NOTXSCALL perlcs->hvSelf, "-min", 4, storing, 0);
                perlcs->iMinWidth = SvIV(*t);
            }
            t = av_fetch((AV*)SvRV(value), 1, 0);
            if(t != NULL) {
                storing = newSViv((LONG) SvIV(*t));
                stored = hv_store_mg(NOTXSCALL perlcs->hvSelf, "-max", 4, storing, 0);
                perlcs->iMaxWidth = SvIV(*t);
            }
        } else {
            W32G_WARN("Win32::GUI: Argument to -range is not an array reference!");
        }
    } else retval = FALSE;

    return retval;
}

void 
Splitter_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {
}

BOOL
Splitter_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

    if Parse_Event("Release",   PERLWIN32GUI_NEM_CONTROL1)
    else retval = FALSE;

    return retval;
}

int
Splitter_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 0;
    BOOL tracking, horizontal;
    POINT pt;
    HWND phwnd, hwnd;
    RECT rc;

    switch(uMsg) {
    case WM_MOUSEMOVE:
        tracking = perlud->dwPlStyle & PERLWIN32GUI_TRACKING;
        if(tracking) {
            horizontal = perlud->dwPlStyle & PERLWIN32GUI_HORIZONTAL;
            hwnd  = handle_From (NOTXSCALL perlud->svSelf);
            phwnd = GetParent(hwnd);
            GetCursorPos(&pt);
            ScreenToClient(phwnd, &pt);
            if(horizontal) {
                pt.y = AdjustSplitterCoord(NOTXSCALL perlud, pt.y, phwnd);
                DrawSplitter(NOTXSCALL hwnd);
                GetWindowRect(hwnd, &rc);
                ScreenToClient(phwnd, (POINT*)&rc);
                SetWindowPos(hwnd, NULL, rc.left, pt.y, 0, 0, SWP_NOZORDER | SWP_NOSIZE);
                DrawSplitter(NOTXSCALL hwnd);
            } else {
                pt.x = AdjustSplitterCoord(NOTXSCALL perlud, pt.x, phwnd);
                DrawSplitter(NOTXSCALL hwnd);
                GetWindowRect(hwnd, &rc);
                ScreenToClient(phwnd, (POINT*)&rc);
                SetWindowPos(hwnd, NULL, pt.x, rc.top, 0, 0, SWP_NOZORDER | SWP_NOSIZE);
                DrawSplitter(NOTXSCALL hwnd);
            }
        }
        break;
    case WM_LBUTTONDOWN:
        SwitchBit(perlud->dwPlStyle, PERLWIN32GUI_TRACKING, 1);        
        horizontal = perlud->dwPlStyle & PERLWIN32GUI_HORIZONTAL;
        hwnd  = handle_From (NOTXSCALL perlud->svSelf);
        phwnd = GetParent(hwnd);
        GetCursorPos(&pt);
        ScreenToClient(phwnd, &pt);

        if(horizontal) {
            pt.y = AdjustSplitterCoord(NOTXSCALL perlud, pt.y, phwnd);
            DrawSplitter(NOTXSCALL hwnd);
            SetCapture(hwnd);
        } else {
            pt.x = AdjustSplitterCoord(NOTXSCALL perlud, pt.x, phwnd);
            DrawSplitter(NOTXSCALL hwnd);
            SetCapture(hwnd);
        }
        break;
    case WM_LBUTTONUP:
        tracking = perlud->dwPlStyle & PERLWIN32GUI_TRACKING;
        if(tracking) {
            horizontal = perlud->dwPlStyle & PERLWIN32GUI_HORIZONTAL;
            hwnd  = handle_From (NOTXSCALL perlud->svSelf);
            phwnd = GetParent(hwnd);
            GetCursorPos(&pt);
            ScreenToClient(phwnd, &pt);
            /*
            * (@)EVENT:Release(COORD)
            * Sent when the Splitter is released after being
            * dragged to a new location (identified by the
            * COORD parameter).
            * (@)APPLIES_TO:Splitter
            */
            if(horizontal) {
                pt.y = AdjustSplitterCoord(NOTXSCALL perlud, pt.y, phwnd);
                DrawSplitter(NOTXSCALL hwnd);

                PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "Release",
                                     PERLWIN32GUI_ARGTYPE_LONG, (long) pt.y,
                                     -1);

            } else {
                pt.x = AdjustSplitterCoord(NOTXSCALL perlud, pt.x, phwnd);
                DrawSplitter(NOTXSCALL hwnd);
                PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "Release",
                                     PERLWIN32GUI_ARGTYPE_LONG, (long) pt.x,
                                     -1);
            }
        }
        SwitchBit(perlud->dwPlStyle, PERLWIN32GUI_TRACKING, 0);
        SetWindowLong(hwnd, GWL_USERDATA, (LONG) perlud);
        ReleaseCapture();
        break;

    default :
        PerlResult = 1;
    }

    return PerlResult;
}

MODULE = Win32::GUI::Splitter       PACKAGE = Win32::GUI::Splitter

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::Splitter..." )

    ###########################################################################
    # (@)METHOD:Min([VALUE])
    # Get or Set Min value

void
Min(handle,...)
    HWND handle
PREINIT:
    LPPERLWIN32GUI_USERDATA perlud;
PPCODE:
    if(items > 2) {
        CROAK("Usage: Min(handle, [value]);\n");
    }
    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLong(handle, GWL_USERDATA);
    if( ValidUserData(perlud) ) {
        if(items == 1) {
            XSRETURN_IV(perlud->iMinWidth);
        } else {
            perlud->iMinWidth = SvIV(ST(1));
            XSRETURN_YES;
        }
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:Max([VALUE])
    # Get or Set Max value

void
Max(handle,...)
    HWND handle
PREINIT:
    LPPERLWIN32GUI_USERDATA perlud;
PPCODE:
    if(items > 2) {
        CROAK("Usage: Max(handle, [value]);\n");
    }
    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLong(handle, GWL_USERDATA);
    if( ValidUserData(perlud) ) {
        if(items == 1) {
            XSRETURN_IV(perlud->iMaxWidth);
        } else {
            perlud->iMaxWidth = SvIV(ST(1));
            XSRETURN_YES;
        }
    } else {
        XSRETURN_UNDEF;
    }

    ###########################################################################
    # (@)METHOD:Horizontal([VALUE])
    # Get or Set Horizontal value

void
Horizontal(handle,...)
    HWND handle
PREINIT:
    LPPERLWIN32GUI_USERDATA perlud;
PPCODE:
    if(items > 2) {
        CROAK("Usage: Horizontal(handle, [value]);\n");
    }
    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLong(handle, GWL_USERDATA);
    if( ValidUserData(perlud) ) {
        if(items == 1) {
            XSRETURN_IV(perlud->dwPlStyle & PERLWIN32GUI_HORIZONTAL);
        } else {
            SwitchBit(perlud->dwPlStyle, PERLWIN32GUI_HORIZONTAL, SvIV(ST(1)));
            SetWindowLong(handle, GWL_USERDATA, (LONG) perlud);
            XSRETURN_YES;
        }
    } else {
        XSRETURN_UNDEF;
    }
    ###########################################################################
    # (@)METHOD:Vertical([VALUE])
    # Get or Set Vertical value

void
Vertical(handle,...)
    HWND handle
PREINIT:
    LPPERLWIN32GUI_USERDATA perlud;
PPCODE:
    if(items > 2) {
        CROAK("Usage: Vertical(handle, [value]);\n");
    }
    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLong(handle, GWL_USERDATA);
    if( ValidUserData(perlud) ) {
        if(items == 1) {
            XSRETURN_IV(!(perlud->dwPlStyle & PERLWIN32GUI_HORIZONTAL));
        } else {
            SwitchBit(perlud->dwPlStyle, PERLWIN32GUI_HORIZONTAL, !SvIV(ST(1)));
            SetWindowLong(handle, GWL_USERDATA, (LONG) perlud);
            XSRETURN_YES;
        }
    } else {
        XSRETURN_UNDEF;
    }
