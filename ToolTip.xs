    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Tooltip
    #
    # $Id: ToolTip.xs,v 1.3 2004/09/29 21:18:44 lrocher Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

void 
Tooltip_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = TOOLTIPS_CLASS;
    perlcs->cs.style = WS_VISIBLE | WS_CHILD | TTS_ALWAYSTIP;
}

BOOL
Tooltip_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {
    BOOL retval = TRUE;

    if BitmaskOptionValue("-alwaystip", perlcs->cs.style, TTS_ALWAYSTIP)
    } else if BitmaskOptionValue("-noprefix", perlcs->cs.style, TTS_NOPREFIX )    
    } else if BitmaskOptionValue("-balloon", perlcs->cs.style, TTS_BALLOON )    
    } else retval= FALSE;

    return retval;
}

void 
Tooltip_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    if(perlcs->clrForeground != CLR_INVALID) {
        SendMessage(myhandle, TTM_SETTIPTEXTCOLOR, (WPARAM) perlcs->clrForeground, (LPARAM) 0);
        perlcs->clrForeground = CLR_INVALID;  // Don't Store
    }
    if(perlcs->clrBackground != CLR_INVALID) {
        SendMessage(myhandle, TTM_SETTIPBKCOLOR, (WPARAM) perlcs->clrBackground, (LPARAM) 0);
        perlcs->clrBackground = CLR_INVALID;  // Don't Store
    }
}

BOOL
Tooltip_onParseEvent(NOTXSPROC char *name, int* eventID) {

    BOOL retval = TRUE;

         if Parse_Event("NeedText",    PERLWIN32GUI_NEM_CONTROL1)
    else if Parse_Event("Pop",         PERLWIN32GUI_NEM_CONTROL2)
    else if Parse_Event("Show",        PERLWIN32GUI_NEM_CONTROL3)
    else retval = FALSE;

    return retval;
}

int
Tooltip_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    int PerlResult = 1;

    if ( uMsg == WM_NOTIFY ) {

        LPNMHDR notify = (LPNMHDR) lParam;

        switch(notify->code) {

        case TTN_NEEDTEXT :
            /*
             * (@)EVENT:NeedText(ID)
             * (@)APPLIES_TO:Tooltip
             */
            {
            LPTOOLTIPTEXT lptt = (LPTOOLTIPTEXT) lParam;
            lptt->lpszText = (LPTSTR) DoEvent_NeedText(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL1, "NeedText",
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG)lptt->hdr.idFrom,
                    -1);

            PerlResult = 1;
            }
            break;
        case TTN_POP:
            /*
             * (@)EVENT:Pop(ID)
             * (@)APPLIES_TO:Tooltip
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL2, "Pop",
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG) wParam,
                    -1);
            break;
        case TTN_SHOW:
            /*
             * (@)EVENT:Show(ID)
             * (@)APPLIES_TO:Tooltip
             */
            PerlResult = DoEvent(NOTXSCALL perlud, PERLWIN32GUI_NEM_CONTROL3, "Show",
                    PERLWIN32GUI_ARGTYPE_LONG, (LONG) wParam,
                    -1);
            break;
        }
    }

    return PerlResult;
}
    
MODULE = Win32::GUI::Tooltip        PACKAGE = Win32::GUI::Tooltip

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::Tooltip..." )

    ###########################################################################
    # (@)METHOD:Activate([FLAG=TRUE])
    # Activates or deactivates a tooltip control. 
LRESULT
Activate(handle, value=TRUE)
    HWND handle
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, TTM_ACTIVATE, value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:AddTool(@OPTIONS)
    # (@)METHOD:Add(@OPTIONS)
    # Registers a tool with a Tooltip. 
    #
    # B<@OPTIONS>:
    #  -text   => STRING
    #    Tool text
    #  -needtext => 0/1
    #     Use NeedText Event.
    #  -window => HANDLE
    #     Window handle for the tool.
    #  -id => ID
    #     ID for the tool.
    #  -flags  => FLAGS
    #     Set of bit flags
    #     -absolute => 0/1
    #     -centertip => 0/1
    #     -idishwnd => 0/1
    #     -rtlreading => 0/1
    #     -subclass => 0/1
    #     -track => 0/1
    #     -transparent => 0/1
    #  -rect => [LEFT,TOP,RIGHT,BOTTOM]
    #     Aera of the tool
BOOL
AddTool(handle,...)
    HWND handle
ALIAS:
    Win32::GUI::Tooltip::Add = 1
PREINIT:
    TOOLINFO ti;
CODE:
    ZeroMemory(&ti, sizeof(TOOLINFO));
    ti.cbSize = sizeof(TOOLINFO);
    ti.hwnd = (HWND) GetWindowLong(handle, GWL_HWNDPARENT);
    ParseTooltipOptions(NOTXSCALL sp, mark, ax, items, 1, &ti);
    RETVAL = SendMessage(handle, TTM_ADDTOOL, 0, (LPARAM) &ti);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DelTool(ID)
    # (@)METHOD:Del(ID)
    # Removes a tool from a Tooltip.
    #
    # B<ID> is Tool ID (a number or a window handle).
BOOL
DelTool(handle,id)
    HWND handle
    HWND id
ALIAS:
    Win32::GUI::Tooltip::Del = 1
PREINIT:
    TOOLINFO ti;
CODE:
    ZeroMemory(&ti, sizeof(TOOLINFO));
    ti.cbSize = sizeof(TOOLINFO);
    ti.hwnd = (HWND) GetWindowLong(handle, GWL_HWNDPARENT);
    ti.uId  = (UINT) id; 
    RETVAL = SendMessage(handle, TTM_DELTOOL, 0, (LPARAM) &ti);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:EnumTools(ID)
    # Retrieves the information for the tool in a tooltip control. 
void
EnumTools(handle, id)
    HWND handle
    HWND id
PREINIT:
    TOOLINFO ti;
CODE:
    ZeroMemory(&ti, sizeof(TOOLINFO));
    ti.cbSize = sizeof(TOOLINFO);
    if (SendMessage(handle, TTM_ENUMTOOLS, (WPARAM) id, (LPARAM) &ti)) {
        EXTEND(SP, 8);
        XST_mPV(0, "-flag");
        XST_mIV(1, ti.uFlags);
        XST_mPV(2, "-hwnd");
        XST_mIV(3, (long) ti.hwnd);
        XST_mPV(4, "-id");
        XST_mIV(5, ti.uId);
        XST_mPV(4, "-hinstance");
        XST_mIV(5, (long) ti.hinst);        
        if (ti.lpszText == LPSTR_TEXTCALLBACK) {
            XST_mPV(6, "-needtext");
            XST_mIV(7, 1);
        } else {
            XST_mPV(6, "-text");
            XST_mPV(7, ti.lpszText);
        }
        XSRETURN(8);
    }
    else
        XSRETURN_UNDEF;

    ###########################################################################
    # (@)METHOD:GetCurrentTool()
    # Retrieves the information for the current tool in a tooltip control.
void
GetCurrentTool(handle)
    HWND handle
PREINIT:
    TOOLINFO ti;
CODE:
    ZeroMemory(&ti, sizeof(TOOLINFO));
    ti.cbSize = sizeof(TOOLINFO);
    if (SendMessage(handle, TTM_GETCURRENTTOOL, (WPARAM) 0, (LPARAM) &ti)) {
        EXTEND(SP, 8);
        XST_mPV(0, "-flag");
        XST_mIV(1, ti.uFlags);
        XST_mPV(2, "-hwnd");
        XST_mIV(3, (long) ti.hwnd);
        XST_mPV(4, "-id");
        XST_mIV(5, ti.uId);
        XST_mPV(4, "-hinstance");
        XST_mIV(5, (long) ti.hinst);        
        if (ti.lpszText == LPSTR_TEXTCALLBACK) {
            XST_mPV(6, "-needtext");
            XST_mIV(7, 1);
        } else {
            XST_mPV(6, "-text");
            XST_mPV(7, ti.lpszText);
        }
        XSRETURN(8);        
    }
    else
        XSRETURN_UNDEF;

    ###########################################################################
    # (@)METHOD:GetDelayTime([FLAG=TTDT_INITIAL])
    # Retrieves the initial, pop-up, and reshow durations currently set for a tooltip control.
    #
    # B<FLAG> :
    #   TTDT_RESHOW  = 1 : Length of time it takes for subsequent tooltip windows to appear as the pointer moves from one tool to another.
    #   TTDT_AUTOPOP = 2 : Length of time the tooltip window remains visible if the pointer is stationary within a tool's bounding rectangle.
    #   TTDT_INITIAL = 3 : Length of time the pointer must remain stationary within a tool's bounding rectangle before the tooltip window appears.
LRESULT
GetDelayTime(handle,flag=TTDT_INITIAL)
    HWND handle
    WPARAM flag
CODE:
    RETVAL = SendMessage(handle, TTM_GETDELAYTIME, flag, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetMargin()
    # Retrieves the top, left, bottom, and right margins set for a tooltip window.
    # A margin is the distance, in pixels, between the tooltip window border and
    # the text contained within the tooltip window. 
void
GetMargin(handle)
    HWND handle
PREINIT:
    RECT rect;
CODE:
    if(SendMessage(handle, TTM_GETMARGIN, 0, (LPARAM) &rect)) {
        EXTEND(SP, 4);
        XST_mIV(0, rect.left);
        XST_mIV(1, rect.top);
        XST_mIV(2, rect.right);
        XST_mIV(3, rect.bottom);
        XSRETURN(4);
    } else 
        XSRETURN_UNDEF;

    ###########################################################################
    # (@)METHOD:GetMaxTipWidth()
    # Retrieves the maximum width for a tooltip window.
LRESULT
GetMaxTipWidth(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, TTM_GETMAXTIPWIDTH, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetText(ID)
    # Retrieves the information a tooltip control maintains about a tool.
void
GetText(handle, id)
    HWND handle
    HWND id
PREINIT:
    TOOLINFO ti;
CODE:
    ZeroMemory(&ti, sizeof(TOOLINFO));
    ti.cbSize = sizeof(TOOLINFO);
    ti.hwnd = (HWND) GetWindowLong(handle, GWL_HWNDPARENT);
    ti.uId = (UINT) id;
    SendMessage(handle, TTM_GETTEXT, 0, (LPARAM) &ti);
    EXTEND(SP, 1);
    XST_mPV(0, ti.lpszText);
    XSRETURN(1);

    ###########################################################################
    # (@)METHOD:GetTipBkColor()
    # Retrieves the background color in a tooltip window.
COLORREF
GetTipBkColor(handle)
    HWND handle
CODE:
    RETVAL = (COLORREF) SendMessage(handle, TTM_GETTIPBKCOLOR, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetTipBkColor()
    # Retrieves the text color in a tooltip window.
COLORREF
GetTipTextColor(handle)
    HWND handle
CODE:
    RETVAL = (COLORREF) SendMessage(handle, TTM_GETTIPTEXTCOLOR, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Count()
    # (@)METHOD:GetToolCount()
    # Returns the number of tools in the Tooltip.
LRESULT
GetToolCount(handle)
    HWND handle
ALIAS:
    Win32::GUI::Tooltip::Count = 1
CODE:
    RETVAL = SendMessage(handle, TTM_GETTOOLCOUNT, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetToolInfo(ID)
    # Retrieves the information that a tooltip control maintains about a tool.
void
GetToolInfo(handle,id)
    HWND handle
    HWND id
PREINIT:
    TOOLINFO ti;
CODE:
    ZeroMemory(&ti, sizeof(TOOLINFO));
    ti.cbSize = sizeof(TOOLINFO);
    ti.hwnd = (HWND) GetWindowLong(handle, GWL_HWNDPARENT);
    ti.uId = (UINT) id;
    if (SendMessage(handle, TTM_GETTOOLINFO, (WPARAM) 0, (LPARAM) &ti)) {
        EXTEND(SP, 8);
        XST_mPV(0, "-flag");
        XST_mIV(1, ti.uFlags);
        XST_mPV(2, "-hwnd");
        XST_mIV(3, (long) ti.hwnd);
        XST_mPV(4, "-id");
        XST_mIV(5, ti.uId);
        XST_mPV(4, "-hinstance");
        XST_mIV(5, (long) ti.hinst);        
        if (ti.lpszText == LPSTR_TEXTCALLBACK) {
            XST_mPV(6, "-needtext");
            XST_mIV(7, 1);
        } else {
            XST_mPV(6, "-text");
            XST_mPV(7, ti.lpszText);
        }
        XSRETURN(8);        
    }
    else
        XSRETURN_UNDEF;

    ###########################################################################
    # (@)METHOD:HitTest(X,Y)
    # Retrieves the information that a tooltip control maintains about a tool.
void
HitTest(handle,id,x,y)
    HWND handle
    HWND id
    int x
    int y
PREINIT:
    TTHITTESTINFO ti;
CODE:    
    ZeroMemory(&ti, sizeof(TTHITTESTINFO));
    ti.pt.x = x; ti.pt.y = y;
    ti.ti.cbSize = sizeof(TOOLINFO);
    ti.hwnd = id;
    if (SendMessage(handle, TTM_GETTOOLINFO, (WPARAM) 0, (LPARAM) &ti)) {
        EXTEND(SP, 8);
        XST_mPV(0, "-flag");
        XST_mIV(1, ti.ti.uFlags);
        XST_mPV(2, "-hwnd");
        XST_mIV(3, (long) ti.ti.hwnd);
        XST_mPV(4, "-id");
        XST_mIV(5, ti.ti.uId);
        XST_mPV(4, "-hinstance");
        XST_mIV(5, (long) ti.ti.hinst);        
        if (ti.ti.lpszText == LPSTR_TEXTCALLBACK) {
            XST_mPV(6, "-needtext");
            XST_mIV(7, 1);
        } else {
            XST_mPV(6, "-text");
            XST_mPV(7, ti.ti.lpszText);
        }
        XSRETURN(8);        
    }
    else
        XSRETURN_UNDEF;

    ###########################################################################
    # (@)METHOD:NewToolRect(ID, LEFT, TOP, RIGHT, BOTTOM)
    # Sets a new bounding rectangle for a tool. 
LRESULT
NewToolRect(handle,id,left,top,right,bottom)
    HWND handle
    HWND id
    int  left
    int  top
    int  right
    int  bottom
PREINIT:
    TOOLINFO ti;
CODE:
    ZeroMemory(&ti, sizeof(TOOLINFO));
    ti.cbSize = sizeof(TOOLINFO);
    ti.hwnd = (HWND) GetWindowLong(handle, GWL_HWNDPARENT);
    ti.uId  = (UINT) id;
    ti.rect.left   = left;
    ti.rect.top    = top;
    ti.rect.right  = right;
    ti.rect.bottom = bottom;
    RETVAL = SendMessage(handle, TTM_NEWTOOLRECT, (WPARAM) 0, (LPARAM) &ti);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Pop()
    # Removes a displayed tooltip window from view.
LRESULT
Pop(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, TTM_POP, 0, 0);
OUTPUT:
    RETVAL

    # TODO : TTM_RELAYEVENT (???)

    ###########################################################################
    # (@)METHOD:SetDelayTime(TIME,[FLAG=TTDT_INITIAL])
    # Sets the initial, pop-up, and reshow durations for a tooltip control. 
    #
    # B<FLAG> :
    #   TTDT_RESHOW  = 1 : Length of time it takes for subsequent tooltip windows to appear as the pointer moves from one tool to another.
    #   TTDT_AUTOPOP = 2 : Length of time the tooltip window remains visible if the pointer is stationary within a tool's bounding rectangle.
    #   TTDT_INITIAL = 3 : Length of time the pointer must remain stationary within a tool's bounding rectangle before the tooltip window appears.
LRESULT
SetDelayTime(handle,time,flag=TTDT_INITIAL)
    HWND handle
    WPARAM time
    WPARAM flag
CODE:
    RETVAL = SendMessage(handle, TTM_SETDELAYTIME, flag, (LPARAM) MAKELONG(time,0));
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetMargin(LEFT, TOP, RIGHT, BOTTOM)
    # Sets the top, left, bottom, and right margins for a tooltip window.
    # A margin is the distance, in pixels, between the tooltip window border and
    # the text contained within the tooltip window. 
LRESULT
SetMargin(handle,left,top,right,bottom)
    HWND handle
    int left
    int top
    int right
    int bottom
PREINIT:
    RECT myRect;
CODE:
    myRect.left   = left;
    myRect.top    = top;
    myRect.right  = right;
    myRect.bottom = bottom;
    RETVAL = SendMessage(handle, TTM_SETMARGIN, (WPARAM) 0, (LPARAM) &myRect);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetMaxTipWidth(WIDTH)
    # Sets the maximum width for a tooltip window.
LRESULT
SetMaxTipWidth(handle,width)
    HWND handle
    WPARAM width
CODE:
    RETVAL = SendMessage(handle, TTM_SETMAXTIPWIDTH, 0, (LPARAM) width);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetTipBkColor(COLOR)
    # Sets the background color in a tooltip window.
LRESULT
SetTipBkColor(handle,color)
    HWND handle
    COLORREF color
CODE:
    RETVAL = SendMessage(handle, TTM_SETTIPBKCOLOR, (WPARAM) color, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetTipTextColor(COLOR)
    # Sets the text color in a tooltip window.
LRESULT
SetTipTextColor(handle,color)
    HWND handle
    COLORREF color
CODE:
    RETVAL = SendMessage(handle, TTM_SETTIPTEXTCOLOR, (WPARAM) color, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetToolInfo(@OPTIONS)
    # Sets the information that a tooltip control maintains for a tool.
    #
    # B<@OPTIONS>: See Add().
LRESULT
SetToolInfo(handle,...)
    HWND handle
PREINIT:
    TOOLINFO ti;
CODE:
    ZeroMemory(&ti, sizeof(TOOLINFO));
    ti.cbSize = sizeof(TOOLINFO);
    ti.hwnd = (HWND) GetWindowLong(handle, GWL_HWNDPARENT);
    ParseTooltipOptions(NOTXSCALL sp, mark, ax, items, 1, &ti);
    RETVAL = SendMessage(handle, TTM_SETTOOLINFO, 0, (LPARAM) &ti);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:TrackActivate(ID, FLAG)
    # Activates or deactivates a tracking tooltip. 
LRESULT
TrackActivate(handle,id,flag)
    HWND handle
    UINT id
    WPARAM flag
PREINIT:
    TOOLINFO ti;
CODE:
    ZeroMemory(&ti, sizeof(TOOLINFO));
    ti.cbSize = sizeof(TOOLINFO);
    ti.hwnd = (HWND) GetWindowLong(handle, GWL_HWNDPARENT);
    ti.uId  = id;
    RETVAL = SendMessage(handle, TTM_TRACKACTIVATE, flag, (LPARAM) &ti);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:TrackPosition(X,Y)
    # Sets the position of a tracking tooltip.
LRESULT
TrackPosition(handle,x,y)
    HWND handle
    UINT x
    UINT y
CODE:
    RETVAL = SendMessage(handle, TTM_TRACKPOSITION, 0, (LPARAM) MAKELONG(x, y));
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Update()
    # Forces the current tool to be redrawn.
LRESULT
Update(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, TTM_UPDATE, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:UpdateTipText(ID, STRING, [INSTANCE=NULL])
    # Sets the tooltip text for a tool.
LRESULT
UpdateTipText(handle, id, string, instance=NULL)
    HWND      handle
    HWND      id
    LPTSTR    string
    HINSTANCE instance
PREINIT:
    TOOLINFO ti;
CODE:
    ZeroMemory(&ti, sizeof(TOOLINFO));
    ti.cbSize = sizeof(TOOLINFO);
    ti.hwnd = (HWND) GetWindowLong(handle, GWL_HWNDPARENT);
    ti.uId  = (UINT) id;
    ti.lpszText = string;
    ti.hinst    = instance;
    RETVAL = SendMessage(handle, TTM_UPDATETIPTEXT, 0, (LPARAM) &ti);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:WindowFromPoint(X, Y)
    # Allows a subclass procedure to cause a tooltip to display text for a window
    # other than the one beneath the mouse cursor. 
LRESULT
WindowFromPoint(handle,x,y)
    HWND handle
    int x
    int y
PREINIT:
    POINT pt;
CODE:
    pt.x = x; pt.y = y;
    RETVAL = SendMessage(handle, TTM_WINDOWFROMPOINT, 0, (LPARAM) &pt);
OUTPUT:
    RETVAL