    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::NotifyIcon
    #
    # $Id: NotifyIcon.xs,v 1.3 2004/03/28 15:01:47 lrocher Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

MODULE = Win32::GUI::NotifyIcon     PACKAGE = Win32::GUI::NotifyIcon

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::NotifyIcon..." )

    ###########################################################################
    # (@)INTERNAL:Add(PARENT, %OPTIONS)
BOOL
Add(parent,...)
    HWND parent
PREINIT:
    NOTIFYICONDATA nid;
CODE:
    ZeroMemory(&nid, sizeof(NOTIFYICONDATA));
    nid.cbSize = sizeof(NOTIFYICONDATA);

    nid.hWnd = parent;
    nid.uCallbackMessage = WM_NOTIFYICON;
    SwitchBit(nid.uFlags, NIF_MESSAGE, 1);

    ParseNotifyIconOptions(NOTXSCALL sp, mark, ax, items, 1, &nid);

    RETVAL = Shell_NotifyIcon(NIM_ADD, &nid);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:Modify(PARENT, %OPTIONS)
BOOL
Modify(parent,...)
    HWND parent
PREINIT:
    NOTIFYICONDATA nid;
CODE:
    ZeroMemory(&nid, sizeof(NOTIFYICONDATA));

    nid.cbSize = sizeof(NOTIFYICONDATA);
    nid.hWnd = parent;

    ParseNotifyIconOptions(NOTXSCALL sp, mark, ax, items, 1, &nid);

    RETVAL = Shell_NotifyIcon(NIM_MODIFY, &nid);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:Delete(PARENT, %OPTIONS)
BOOL
Delete(parent,...)
    HWND parent
PREINIT:
    NOTIFYICONDATA nid;
CODE:
    ZeroMemory(&nid, sizeof(NOTIFYICONDATA));
    nid.cbSize = sizeof(NOTIFYICONDATA);
    nid.hWnd = parent;

    ParseNotifyIconOptions(NOTXSCALL sp, mark, ax, items, 1, &nid);

    RETVAL = Shell_NotifyIcon(NIM_DELETE, &nid);
OUTPUT:
    RETVAL
