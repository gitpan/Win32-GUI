    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI::RichEdit
    #
    # $Id: RichEdit.xs,v 1.3 2005/06/13 17:37:46 robertemay Exp $
    #
    ###########################################################################
    */

#include "GUI.h"

void 
RichEdit_onPreCreate(NOTXSPROC LPPERLWIN32GUI_CREATESTRUCT perlcs) {

    perlcs->cs.lpszClass = "RichEdit";
    perlcs->cs.style = WS_VISIBLE | WS_CHILD | ES_MULTILINE | ES_AUTOHSCROLL | ES_AUTOVSCROLL;
    perlcs->cs.dwExStyle = WS_EX_CLIENTEDGE;
}

BOOL
RichEdit_onParseOption(NOTXSPROC char *option, SV* value, LPPERLWIN32GUI_CREATESTRUCT perlcs) {
    return Textfield_onParseOption (NOTXSCALL option, value, perlcs);
}

void
RichEdit_onPostCreate(NOTXSPROC HWND myhandle, LPPERLWIN32GUI_CREATESTRUCT perlcs) {
}

BOOL
RichEdit_onParseEvent(NOTXSPROC char *name, int* eventID) {

    return Textfield_onParseEvent(NOTXSCALL name, eventID);
}

int
RichEdit_onEvent (NOTXSPROC LPPERLWIN32GUI_USERDATA perlud, UINT uMsg, WPARAM wParam, LPARAM lParam) {

    return Textfield_onEvent (NOTXSCALL perlud, uMsg, wParam, lParam);
}

MODULE = Win32::GUI::RichEdit       PACKAGE = Win32::GUI::RichEdit

PROTOTYPES: DISABLE

#pragma message( "*** PACKAGE Win32::GUI::RichEdit..." )

    #
    # See Alias in TextField.xs
    # 

    ###########################################################################
    # (@)METHOD:AutoURLDetect([FLAG=TRUE])
    # Set automatic detection of URLs mode.

LRESULT
AutoURLDetect(handle, flag=TRUE)
    HWND   handle
    BOOL   flag
CODE:
    RETVAL = SendMessage(handle, EM_AUTOURLDETECT, (WPARAM) flag, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:CanPaste([FORMAT=CF_TEXT])
    # Determine if RichEdit can paste a specified clipboard format.

LRESULT
CanPaste(handle, value=CF_TEXT)
    HWND   handle
    WPARAM value
CODE:
    RETVAL = SendMessage(handle, EM_CANPASTE, value, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:CanRedo()
    # Determine whether there are any actions in redo queue

LRESULT
CanRedo(handle)
    HWND   handle
CODE:
    RETVAL = SendMessage(handle, EM_CANREDO, 0, 0);
OUTPUT:
    RETVAL
 
    ###########################################################################
    # (@)METHOD:DisplayBand(LEFT, TOP, RIGHT, BOTTOM)
    # Displays a portion of a RichEdit's contents, as previously formatted for a device using the EM_FORMATRANGE message.

LRESULT
DisplayBand(handle,left,top,right,bottom)
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
    RETVAL = SendMessage(handle, EM_DISPLAYBAND, 0, (LPARAM) &myRect);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetSel()
    # (@)METHOD:Selection()
    # Returns a two elements array containing the current selection start
    # and end.
void
GetSel(handle)
    HWND handle
ALIAS:
    Win32::GUI::RichEdit::Selection = 1
PREINIT:
    CHARRANGE cr;
PPCODE:
    ZeroMemory(&cr, sizeof(CHARRANGE));
    SendMessage(handle, EM_EXGETSEL, 0, (LPARAM) (CHARRANGE FAR *) &cr);
    EXTEND(SP, 2);
    XST_mIV(0, cr.cpMin);
    XST_mIV(1, cr.cpMax);
    XSRETURN(2);

    ###########################################################################
    # (@)METHOD:LimiteText(LENGTH)
    # (@)METHOD:SetMaxLength(LENGTH)
    # Sets the RichEdit control's maximum length (up to 2GB)
LRESULT
LimiteText(handle,length)
    HWND handle
    long length
ALIAS:
    Win32::GUI::RichEdit::SetMaxLength = 1
CODE:
    RETVAL = SendMessage(handle, EM_EXLIMITTEXT, 0, (LPARAM) length);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:LineFromChar(INDEX)
    # Returns the line number where the zero-based INDEX character appears.
LRESULT
LineFromChar(handle,index)
    HWND handle
    WPARAM index
CODE:
    RETVAL = SendMessage(handle, EM_EXLINEFROMCHAR, 0, (LPARAM) index);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetSel(START, END)
    # (@)METHOD:Select(START, END)
    # Selects the characters range from START to END.
LRESULT
SetSel(handle,start,end)
    HWND handle
    LONG start
    LONG end
ALIAS:
    Win32::GUI::RichEdit::Select = 1
PREINIT:
    CHARRANGE cr;
CODE:
    ZeroMemory(&cr, sizeof(CHARRANGE));
    cr.cpMin = start;
    cr.cpMax = end;
    RETVAL = SendMessage(handle, EM_EXSETSEL, 0, (LPARAM) (CHARRANGE FAR *) &cr);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:FindText(STRING, START, END, [FLAG})
    # Search a string text.
void
FindText(handle,string,start,end,flag=0)
    HWND   handle
    LPTSTR string
    LONG   start
    LONG   end
    WPARAM flag
PREINIT:
    FINDTEXTEX ft;
    LRESULT res;
CODE:
    ZeroMemory(&ft, sizeof(FINDTEXTEX));
    ft.chrg.cpMin = start;
    ft.chrg.cpMax = end;
    ft.lpstrText = string;
    res = SendMessage(handle, EM_FINDTEXTEX, flag, (LPARAM) (CHARRANGE FAR *) &ft);

    if(GIMME == G_ARRAY) {
        if (res != -1) {
            EXTEND(SP, 2);
            XST_mIV(0, ft.chrg.cpMin);
            XST_mIV(1, ft.chrg.cpMax);
            XSRETURN(2);
        }
        else
            XSRETURN_UNDEF;
    }
    else {
        EXTEND(SP, 1);
        XST_mIV(0, res);
        XSRETURN(1);
    }

    ###########################################################################
    # (@)METHOD:FindWordBreak(START, [FLAG=WB_NEXTBREAK] )
    # 
LRESULT
FindWordBreak(handle,index, flag=WB_NEXTBREAK)
    HWND handle
    LPARAM index
    WPARAM flag
CODE:
    RETVAL = SendMessage(handle, EM_FINDWORDBREAK, flag, index);
OUTPUT:
    RETVAL

    # TODO : EM_FORMATRANGE

    ###########################################################################
    # (@)METHOD:GetAutoURLDetect()
LRESULT
GetAutoURLDetect(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, EM_GETAUTOURLDETECT, 0, 0);
OUTPUT:
    RETVAL

    # TODO : EM_GETBIDIOPTIONS

    ###########################################################################
    # (@)METHOD:GetCharFormat([FLAG])
void
GetCharFormat(handle,flag=1)
    HWND handle
    BOOL flag
PREINIT:
    CHARFORMAT cf;
    DWORD dwMask;
    int si;
PPCODE:
    ZeroMemory(&cf, sizeof(CHARFORMAT));
    cf.cbSize = sizeof(CHARFORMAT);
    dwMask = SendMessage(
        handle, EM_GETCHARFORMAT, (WPARAM) flag, (LPARAM) (CHARFORMAT FAR *) &cf
    );
    si = 0;
    if(dwMask & CFM_BOLD) {
        if(cf.dwEffects & CFE_BOLD) {
            EXTEND(SP, 2);
            XST_mPV(si++, "-bold");
            XST_mIV(si++, 1);
        }
    }
    if(dwMask & CFM_COLOR) {
        EXTEND(SP, 2);
        XST_mPV(si++, "-color");
        XST_mIV(si++, (long) cf.crTextColor);
    }
    if(dwMask & CFM_FACE) {
        EXTEND(SP, 2);
        XST_mPV(si++, "-name");
        XST_mPV(si++, cf.szFaceName);
    }
    if(dwMask & CFM_ITALIC) {
        if(cf.dwEffects & CFE_ITALIC) {
            EXTEND(SP, 2);
            XST_mPV(si++, "-italic");
            XST_mIV(si++, 1);
        }
    }
    if(dwMask & CFM_SIZE) {
        EXTEND(SP, 2);
        XST_mPV(si++, "-name");
        XST_mIV(si++, cf.yHeight);
    }
    if(dwMask & CFM_STRIKEOUT) {
        if(cf.dwEffects & CFE_STRIKEOUT) {
            EXTEND(SP, 2);
            XST_mPV(si++, "-strikeout");
            XST_mIV(si++, 1);
        }
    }
    if(dwMask & CFM_UNDERLINE) {
        if(cf.dwEffects & CFE_UNDERLINE) {
            EXTEND(SP, 2);
            XST_mPV(si++, "-underline");
            XST_mIV(si++, 1);
        }
    }
    XSRETURN(si);

    ###########################################################################
    # (@)METHOD:GetEditStyle()
    # 
LRESULT
GetEditStyle(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, EM_GETEDITSTYLE, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetEventMask()
    # 
LRESULT
GetEventMask(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, EM_GETEVENTMASK, 0, 0);
OUTPUT:
    RETVAL

    # TODO : EM_GETIMECOLOR
    # TODO : EM_GETIMECOMPMODE

    ###########################################################################
    # (@)METHOD:GetIMEOptions()
    # 
LRESULT
GetIMEOptions(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, EM_GETIMEOPTIONS, 0, 0);
OUTPUT:
    RETVAL 

    ###########################################################################
    # (@)METHOD:GetLangOptions()
    # 
LRESULT
GetLangOptions(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, EM_GETLANGOPTIONS, 0, 0);
OUTPUT:
    RETVAL 

    # TODO : EM_GETOLEINTERFACE

    ###########################################################################
    # (@)METHOD:GetOptions()
    # 
LRESULT
GetOptions(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, EM_GETOPTIONS, 0, 0);
OUTPUT:
    RETVAL 

    # TODO : EM_GETPARAFORMAT
    # TODO : EM_GETPUNCTUATION

    ###########################################################################
    # (@)METHOD:GetRedoName()
    # 
LRESULT
GetRedoName(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, EM_GETREDONAME, 0, 0);
OUTPUT:
    RETVAL 

    ###########################################################################
    # (@)METHOD:GetSelText()
    # Returns the current selection text
void
GetSelText(handle)
    HWND handle
PREINIT:
    CHARRANGE cr;
PPCODE:
    ZeroMemory(&cr, sizeof(CHARRANGE));
    SendMessage(handle, EM_EXGETSEL, 0, (LPARAM) (CHARRANGE FAR *) &cr);
    if (cr.cpMin + cr.cpMax > 0) {
        char * pBuf = (char *) safemalloc(cr.cpMin + cr.cpMax + 16); 
        LRESULT size = SendMessage(handle, EM_GETSELTEXT, 0, (LPARAM) pBuf);
        pBuf[size] = '\0';

        EXTEND(SP, 1);
        XST_mPV(0, pBuf);
        safefree (pBuf);
        XSRETURN(1);
    }
    else
        XSRETURN_UNDEF;

    ###########################################################################
    # (@)METHOD:TextLength()
    # Returns the text length of the RichEdit control
LRESULT
GetTextLength(handle)
    HWND handle
ALIAS:
    Win32::GUI::RichEdit::TextLength = 1
PREINIT:
    GETTEXTLENGTHEX tl;
CODE:
    ZeroMemory(&tl, sizeof(GETTEXTLENGTHEX));
    tl.flags = GTL_DEFAULT;
    tl.codepage = CP_ACP;
    RETVAL = SendMessage(
        handle, EM_GETTEXTLENGTHEX, (WPARAM) (GETTEXTLENGTHEX FAR *) &tl, 0
    );
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetTextMode()
    # 
LRESULT
GetTextMode(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, EM_GETTEXTMODE, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetTextRange(START, LENGTH)
    # Returns LENGTH bytes of text from the RichEdit control, starting at START
void
GetTextRange(handle,start,length)
    HWND handle
    LONG start
    LONG length
PREINIT:
    TEXTRANGE tr;
    LRESULT count;
PPCODE:
    ZeroMemory(&tr, sizeof(TEXTRANGE));
    if(length < 0) length = 0;
    if(start < 0)   start = 0;

    tr.chrg.cpMin = start;
    tr.chrg.cpMax = start+length;
    tr.lpstrText = (char *) safemalloc(length+1);
    count = SendMessage(handle, EM_GETTEXTRANGE, 0, (LPARAM) (TEXTRANGE FAR *) &tr);
    tr.lpstrText[count] = '\0';
    EXTEND(SP, 1);
    XST_mPV(0, tr.lpstrText);
    safefree(tr.lpstrText);
    XSRETURN(1);

    ###########################################################################
    # (@)METHOD:GetTypographyOptions()
    # 
LRESULT
GetTypographyOptions(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, EM_GETTYPOGRAPHYOPTIONS, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetUndoName()
    # 
LRESULT
GetUndoName(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, EM_GETUNDONAME, 0, 0);
OUTPUT:
    RETVAL

    # TODO : EM_GETWORDBREAKPROCEX

    ###########################################################################
    # (@)METHOD:GetWordWrapMode()
    # 
LRESULT
GetWordWrapMode(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, EM_GETWORDWRAPMODE, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:HideSelection([HIDE=TRUE,CHANGESTYLE=FALSE])
    # 
LRESULT
HideSelection(handle,hide=TRUE,style=FALSE)
    HWND handle
    BOOL hide
    BOOL style
CODE:
    RETVAL = SendMessage(handle, EM_HIDESELECTION, (WPARAM) hide, (LPARAM) style);
OUTPUT:
    RETVAL

    # TODO : PasteSpecial

    ###########################################################################
    # (@)METHOD:Redo()
    # 
LRESULT
Redo(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, EM_REDO, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:RequestResize()
    # 
LRESULT
RequestResize(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, EM_REQUESTRESIZE, 0, 0);
OUTPUT:
    RETVAL   

    ###########################################################################
    # (@)METHOD:SelectionType()
    # 
LRESULT
SelectionType(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, EM_SELECTIONTYPE, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetBkgndColor([COLOR])
    # (@)METHOD:BackColor([COLOR])
LRESULT
SetBkgndColor(handle,color=(COLORREF) -1, flag = 0)
    HWND handle
    COLORREF color    
    WPARAM flag;
ALIAS:
    Win32::GUI::RichEdit::BackColor = 1
CODE:
    if(color < 0) {
        color = 0;
        flag = 1;
    } else {
        flag = 0;
    }
    RETVAL = SendMessage(handle, EM_SETBKGNDCOLOR, flag, (LPARAM) color);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetCharFormat(%OPTIONS)
LRESULT
SetCharFormat(handle,...)
    HWND handle
PREINIT:
    CHARFORMAT cf;
    int i, next_i;
    char * option;
CODE:
    ZeroMemory(&cf, sizeof(CHARFORMAT));
    cf.cbSize = sizeof(CHARFORMAT);
    next_i = -1;
    for(i = 1; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-bold") == 0) {
                next_i = i + 1;
                if(SvIV(ST(next_i)) != 0) {
                    cf.dwEffects = cf.dwEffects | CFE_BOLD;
                }
                cf.dwMask = cf.dwMask | CFM_BOLD;
            }
            if(strcmp(option, "-italic") == 0) {
                next_i = i + 1;
                if(SvIV(ST(next_i)) != 0) {
                    cf.dwEffects = cf.dwEffects | CFE_ITALIC;
                }
                cf.dwMask = cf.dwMask | CFM_ITALIC;
            }
            if(strcmp(option, "-underline") == 0) {
                next_i = i + 1;
                if(SvIV(ST(next_i)) != 0) {
                    cf.dwEffects = cf.dwEffects | CFE_UNDERLINE;
                }
                cf.dwMask = cf.dwMask | CFM_UNDERLINE;
            }
            if(strcmp(option, "-strikeout") == 0) {
                next_i = i + 1;
                if(SvIV(ST(next_i)) != 0) {
                    cf.dwEffects = cf.dwEffects | CFE_STRIKEOUT;
                }
                cf.dwMask = cf.dwMask | CFM_STRIKEOUT;
            }
            if(strcmp(option, "-color") == 0) {
                next_i = i + 1;
                cf.crTextColor = SvCOLORREF(NOTXSCALL ST(next_i));
                cf.dwMask = cf.dwMask | CFM_COLOR;
            }
            if(strcmp(option, "-autocolor") == 0) {
                next_i = i + 1;
                if(SvIV(ST(next_i)) != 0) {
                    cf.dwEffects = cf.dwEffects | CFE_AUTOCOLOR;
                    cf.dwMask = cf.dwMask | CFM_COLOR;
                }
            }
            if(strcmp(option, "-height") == 0
            || strcmp(option, "-size") == 0) {
                next_i = i + 1;
                cf.yHeight = (LONG) SvIV(ST(next_i));
                cf.dwMask = cf.dwMask | CFM_SIZE;
            }
            if(strcmp(option, "-name") == 0) {
                next_i = i + 1;
                strncpy((char *)cf.szFaceName, SvPV_nolen(ST(next_i)), 32);
                cf.dwMask = cf.dwMask | CFM_FACE;
            }
        } else {
            next_i = -1;
        }
    }
    RETVAL = SendMessage(handle, EM_SETCHARFORMAT,
                         (WPARAM) (UINT) SCF_SELECTION,
                         (LPARAM) (CHARFORMAT FAR *) &cf);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetEditStyle(STYLE, MASK)
    # 
LRESULT
SetEditStyle(handle, style, mask)
    HWND handle
    DWORD style
    DWORD mask
CODE:
    RETVAL = SendMessage(handle, EM_SETEDITSTYLE, (WPARAM) style, (LPARAM) mask);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetEventMask(MASK)
    # 
LRESULT
SetEventMask(handle, mask)
    HWND handle
    DWORD mask
CODE:
    RETVAL = SendMessage(handle, EM_SETEVENTMASK, 0, (LPARAM)mask);
OUTPUT:
    RETVAL

    # TODO : EM_SETIMECOLOR
    # TODO : EM_SETIMEOPTIONS

    ###########################################################################
    # (@)METHOD:SetLangOptions(MASK)
    # 
LRESULT
SetLangOptions(handle, mask)
    HWND handle
    DWORD mask
CODE:
    RETVAL = SendMessage(handle, EM_SETLANGOPTIONS, 0, (LPARAM)mask);
OUTPUT:
    RETVAL

    # TODO : EM_SETOLECALLBACK

    ###########################################################################
    # (@)METHOD:SetOptions(MASK)
    # 
LRESULT
SetOptions(handle, operation, options)
    HWND handle
    UINT operation
    UINT options
CODE:
    RETVAL = SendMessage(handle, EM_SETOPTIONS, (WPARAM) operation, (LPARAM) options);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetParaFormat(%OPTIONS)
LRESULT
SetParaFormat(handle,...)
    HWND handle
PREINIT:
    PARAFORMAT pf;
    int i, next_i;
    char * option;
CODE:
    ZeroMemory(&pf, sizeof(PARAFORMAT));
    pf.cbSize = sizeof(PARAFORMAT);
    next_i = -1;
    for(i = 1; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-numbering") == 0
            || strcmp(option, "-bullet") == 0) {
                next_i = i + 1;
                if(SvIV(ST(next_i)) != 0) {
                    pf.wNumbering = PFN_BULLET;
                } else {
                    pf.wNumbering = 0;
                }
                pf.dwMask = pf.dwMask | PFM_NUMBERING;
            } else if(strcmp(option, "-align") == 0) {
                next_i = i + 1;
                if(strcmp(SvPV_nolen(ST(next_i)), "left") == 0) {
                    pf.wAlignment = PFA_LEFT;
                    pf.dwMask = pf.dwMask | PFM_ALIGNMENT;
                } else if(strcmp(SvPV_nolen(ST(next_i)), "center") == 0) {
                    pf.wAlignment = PFA_CENTER;
                    pf.dwMask = pf.dwMask | PFM_ALIGNMENT;
                } else if(strcmp(SvPV_nolen(ST(next_i)), "right") == 0) {
                    pf.wAlignment = PFA_RIGHT;
                    pf.dwMask = pf.dwMask | PFM_ALIGNMENT;
                } else {
                    if(PL_dowarn) warn("Win32::GUI:: Invalid value for -align!\n");
                }
            } else if(strcmp(option, "-offset") == 0) {
                next_i = i + 1;
                pf.dxOffset = SvIV(ST(next_i));
                pf.dwMask = pf.dwMask | PFM_OFFSET;
            } else if(strcmp(option, "-startindent") == 0) {
                next_i = i + 1;
                pf.dxStartIndent = SvIV(ST(next_i));
                pf.dwMask = pf.dwMask | PFM_STARTINDENT;
            } else if(strcmp(option, "-right") == 0) {
                next_i = i + 1;
                pf.dxRightIndent = SvIV(ST(next_i));
                pf.dwMask = pf.dwMask | PFM_RIGHTINDENT;
            }
        } else {
            next_i = -1;
        }
    }
    RETVAL = SendMessage(handle, EM_SETPARAFORMAT, 0,
                         (LPARAM) (PARAFORMAT FAR *) &pf);
OUTPUT:
    RETVAL

    # TODO : EM_SETPUNCTUATION
    # TODO : EM_SETTARGETDEVICE

    ###########################################################################
    # (@)METHOD:SetTextMode(MODE, UNDO)
    # Sets the RichEdit control's text mode
LRESULT
SetTextMode(handle,mode,undo)
    HWND handle
    int mode
    int undo
PREINIT:
    WPARAM wParam;
CODE:
    wParam = 0;
    wParam |= (mode ? TM_RICHTEXT : TM_PLAINTEXT);
    wParam |= (undo ? TM_MULTILEVELUNDO : TM_SINGLELEVELUNDO);

    RETVAL = SendMessage(
        handle, EM_SETTEXTMODE, (WPARAM) wParam, 0
    );
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetUndoLimit(MAX)
    # 
LRESULT
SetUndoLimit(handle, max)
    HWND handle
    WPARAM max
CODE:
    RETVAL = SendMessage(handle, EM_SETUNDOLIMIT, max, 0);
OUTPUT:
    RETVAL

    # TODO : EM_SETWORDBREAKPROCEX

    ###########################################################################
    # (@)METHOD:SetWrapMode(OPTION)
    # 
LRESULT
SetWrapMode(handle, option)
    HWND handle
    WPARAM option
CODE:
    RETVAL = SendMessage(handle, EM_SETWORDWRAPMODE, option, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ShowScrollBar(BARRE,[SHOW=TRUE])
    # 
LRESULT
ShowScrollBar(handle, bar, show)
    HWND handle
    WPARAM bar
    WPARAM show
CODE:
    RETVAL = SendMessage(handle, EM_SHOWSCROLLBAR, bar, (LPARAM) show);
OUTPUT:
    RETVAL

    ###########################################################################
    ###########################################################################
    ###########################################################################


    ###########################################################################
    # (@)METHOD:CharFromPos(X, Y)
    # Returns a two elements array identifying the character nearest to the
    # position specified by X and Y.
    # The array contains the zero-based index of the character and its line
    # index.
void
CharFromPos(handle,x,y)
    HWND handle
    int x
    int y
PREINIT:
    POINT p;
    LRESULT cfp;
PPCODE:
    ZeroMemory(&p, sizeof(POINT));
    p.x = x;
    p.y = y;
    cfp = SendMessage(handle, EM_CHARFROMPOS, 0, (LPARAM) &p);
    if(cfp == -1) {
        XSRETURN_IV(-1);
    } else {
        EXTEND(SP, 2);
        XST_mIV(0, LOWORD(cfp));
        XST_mIV(1, HIWORD(cfp));
        XSRETURN(2);
    }

    ###########################################################################
    # (@)METHOD:PosFromChar(INDEX)
    # Returns a two elements array containing the x and y position of the
    # specified zero-based INDEX character in the RichEdit control.
void
PosFromChar(handle,index)
    HWND handle
    LPARAM index
PREINIT:
    POINT p;
CODE:
    ZeroMemory(&p, sizeof(POINT));
    SendMessage(handle, EM_POSFROMCHAR, (WPARAM) &p, index);
    EXTEND(SP, 2);
    XST_mIV(0, p.x);
    XST_mIV(1, p.y);
    XSRETURN(2);

    ###########################################################################
    # (@)METHOD:SetRect(LEFT,TOP,RIGHT,BOTTOM)
void
SetRect(handle,left,top,right,bottom)
    HWND handle
    int left
    int top
    int right
    int bottom
PREINIT:
    RECT myRect;
PPCODE:
    myRect.left   = left;
    myRect.top    = top;
    myRect.right  = right;
    myRect.bottom = bottom;
    SendMessage(handle, EM_SETRECT, 0, (LPARAM) &myRect);

    ###########################################################################
    # (@)METHOD:Save(FILENAME, [FORMAT])
LRESULT
Save(handle,filename,format=SF_RTF)
    HWND handle
    LPCTSTR filename
    WPARAM format
PREINIT:
    HANDLE hfile;
    EDITSTREAM estream;
CODE:
    hfile = CreateFile(
        filename, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL
    );
    estream.dwCookie = (DWORD) hfile;
    estream.dwError = 0;
    estream.pfnCallback = (EDITSTREAMCALLBACK) RichEditSave;

    RETVAL = SendMessage(handle, EM_STREAMOUT,
                         format, (LPARAM) &estream);
    CloseHandle(hfile);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Load(FILENAME, [FORMAT])
LRESULT
Load(handle,filename,format=SF_RTF)
    HWND handle
    LPCTSTR filename
    WPARAM format
PREINIT:
    HANDLE hfile;
    EDITSTREAM estream;
CODE:
    hfile = CreateFile(
        filename, GENERIC_READ, 0, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
    );
    estream.dwCookie = (DWORD) hfile;
    estream.dwError = 0;
    estream.pfnCallback = (EDITSTREAMCALLBACK) RichEditLoad;

    RETVAL = SendMessage(handle, EM_STREAMIN,
                         format, (LPARAM) &estream);
    CloseHandle(hfile);
OUTPUT:
    RETVAL
