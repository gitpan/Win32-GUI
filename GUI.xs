/*
###############################################################################
#
# Win32::GUI - Perl-Win32 Graphical User Interface Extension
#
# 29 Jan 1997 by Aldo Calpini <dada@perl.it>
#
# Version: 0.0.558 (15 Jan 2001)
#
# Copyright (c) 1997..2001 Aldo Calpini. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
###############################################################################
 */

/*
 * Uncomment the next two lines (in increasing verbose order)
 * for debugging info
 */
/* #define PERLWIN32GUI_DEBUG */
/* #define PERLWIN32GUI_STRONGDEBUG */

#define  WIN32_LEAN_AND_MEAN
#define _WIN32_IE 0x0401
#include <windows.h>
#include <winuser.h>
#include <commctrl.h>
#include <commdlg.h>
#include <wtypes.h>
#include <richedit.h>
#include <shellapi.h>
#include <shlobj.h>

/*
 * needed?
 */
#include <ctl3d.h>

#include "resource.h"

#define __TEMP_WORD  WORD   /* perl defines a WORD, yikes! */

/*
 * Perl includes
 */
#if defined(__cplusplus) && !defined(PERL_OBJECT) && !defined(PERL_IMPLICIT_CONTEXT)
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#if defined(__cplusplus) && !defined(PERL_OBJECT) && !defined(PERL_IMPLICIT_CONTEXT)
}
#endif

#define MAX_WINDOW_NAME 128
#define MAX_EVENT_NAME 255

#define WM_EXITLOOP   (WM_APP+1)    /* custom message to exit from the Dialog() function */
#define WM_NOTIFYICON (WM_APP+2)    /* custom message to process NotifyIcon events */

/*
 * object types (for switch()ing)
 */
#define WIN32__GUI__WINDOW      0
#define WIN32__GUI__DIALOG      1

#define WIN32__GUI__STATIC      11
#define WIN32__GUI__BUTTON      12
#define WIN32__GUI__EDIT        13
#define WIN32__GUI__LISTBOX     14
#define WIN32__GUI__COMBOBOX    15

#define WIN32__GUI__CHECKBOX    21
#define WIN32__GUI__RADIOBUTTON 22
#define WIN32__GUI__GROUPBOX    23

#define WIN32__GUI__TOOLBAR     30
#define WIN32__GUI__PROGRESS    31
#define WIN32__GUI__STATUS      32
#define WIN32__GUI__TAB         33
#define WIN32__GUI__RICHEDIT    34
#define WIN32__GUI__LISTVIEW    35
#define WIN32__GUI__TREEVIEW    36
#define WIN32__GUI__TRACKBAR    37
#define WIN32__GUI__UPDOWN      38
#define WIN32__GUI__TOOLTIP     39
#define WIN32__GUI__ANIMATION   40
#define WIN32__GUI__REBAR       41
#define WIN32__GUI__HEADER      42
#define WIN32__GUI__COMBOBOXEX  43
#define WIN32__GUI__DTPICK      44

#define WIN32__GUI__GRAPHIC    101
#define WIN32__GUI__SPLITTER   102
#define WIN32__GUI__MDICLIENT  103

/*
 * Various definitions to accomodate the different Perl versions around
 */
#ifdef PERL_OBJECT
#   ifdef _INC_WIN32_PERL5
#       pragma message( "\n*** Using the 5.005 Perl Object CPerlObj class.\n" )
#       define NOTXSPROC   CPerlObj *pPerl,
#       define NOTXSCALL   pPerl,
#       define CPerl CPerlObj
#   else // not _INC_WIN32_PERL5
#       pragma message( "\n*** Using the 5.004 Perl Object CPerl class.\n" )
#       define NOTXSPROC   CPerl *pPerl,
#       define NOTXSCALL   pPerl,
#   endif  //  _INC_WIN32_PERL5
#	define	SvPV_nolen(x)	SvPV(x, na)
#else
#   pragma message( "\n*** Using a non-Object Core Perl.\n" )
#   define NOTXSPROC
#   define NOTXSCALL
#endif

/*
 * an extension to Window's CREATESTRUCT structure
 */
typedef struct tagPERLWIN32GUI_CREATESTRUCT {
    CREATESTRUCT cs;
    /*
    CREATESTRUCT has the following members:
        LPVOID      lpCreateParams;
        HINSTANCE   hInstance;
        HMENU       hMenu;
        HWND        hwndParent;
        int         cy;
        int         cx;
        int         y;
        int         x;
        LONG        style;
        LPCTSTR     lpszName;
        LPCTSTR     lpszClass;
        DWORD       dwExStyle;
    */
    HIMAGELIST  hImageList;
    HV*         hvParent;
    HV*         hvSelf;
    char *      szWindowName;
    char *      szWindowFunction;
    HFONT       hFont;
    int         iClass;
	HACCEL		hAcc;
	int			iMinWidth;
	int			iMaxWidth;
	int			iMinHeight;
	int			iMaxHeight;
	COLORREF	clrForeground;
	COLORREF	clrBackground;
	HBRUSH		hBackgroundBrush;
} PERLWIN32GUI_CREATESTRUCT, *LPPERLWIN32GUI_CREATESTRUCT;

/*
 * what we'll store in GWL_USERDATA
 */
typedef struct tagPERLWIN32GUI_USERDATA {
	DWORD 		dwSize;							// struct size (our signature)
#ifdef PERL_OBJECT
	CPerl   	*pPerl; 						// a pointer to the Perl Object
#endif
	SV*			svSelf;							// a pointer to ourself
	char 		szWindowName[MAX_WINDOW_NAME];	// our -name
	BOOL		fDialogUI;						// are we to intercept dialog messages?
	int			iClass;							// our (Perl) class
	HACCEL		hAcc;							// our accelerator table
	int			iMinWidth;
	int			iMaxWidth;
	int			iMinHeight;
	int			iMaxHeight;
	COLORREF	clrForeground;
	COLORREF	clrBackground;
	HBRUSH		hBackgroundBrush;
} PERLWIN32GUI_USERDATA, *LPPERLWIN32GUI_USERDATA;

/*
 * Various definitions to accomodate the different Perl versions around
 * (mainly courtesy of Dave Roth :-)
 */
#ifdef PERL_OBJECT
#   define  EMBEDDED_PERL_OBJECT    0x01
#   define  EMBEDDED_SELF_OBJECT    0x02
#   define  PERL_OBJECT_FROM_WINDOW(x)  (CPerl*) ExtractPerlObject(EMBEDDED_PERL_OBJECT, (PerlData *) GetWindowLong((x), GWL_USERDATA))
#   define  SV_SELF_FROM_WINDOW(x)      (SV*) ExtractPerlObject(EMBEDDED_SELF_OBJECT, (PerlData *) GetWindowLong((x), GWL_USERDATA))
#   define  HV_SELF_FROM_WINDOW(x)      (SV_SELF_FROM_WINDOW(x) ? (HV*) SvRV(SV_SELF_FROM_WINDOW(x)) : NULL)
#   define  _PERL_DATA_TEST_STRING  "This is a formal Test, baby!"

    typedef struct _PERL_DATA_ {
        CPerl   *pPerl; // a pointer to the Perl Object
        SV*     hvSelf;
        SV*     svCode;
        char    *pTest; // structure validator
        LPCTSTR lpszName;

        /* _PERL_DATA_ Constructor */
        _PERL_DATA_() {
            pPerl = NULL;
            hvSelf = NULL;
            svCode = NULL;
            pTest = _PERL_DATA_TEST_STRING;
        }

        /* _PERL_DATA_ Destructor */
        ~_PERL_DATA_() {
            /*
             * Here we should check for a valid SV* (or HV*).
             * If it exists we should decriment it's reference
             * count so it will die if need be.
             */
            while(SvREFCNT(hvSelf) > 0) {
				SvREFCNT_dec(hvSelf);
			}
            pPerl = NULL;
            hvSelf = NULL;
            pTest = NULL;
            svCode = NULL;
        }
    } PerlData;

    void *ExtractPerlObject( int iType, PerlData *pData ) {
        void *pReturn = NULL;
		/*
#ifdef PERLWIN32GUI_STRONGDEBUG
		printf("!XS(ExtractPerlObject) entering(%d)\n", iType);
#endif
		*/
        if( NULL != pData ) {
            /*
             * Put the test condition in a try/catch exception
             * handler since it is possible (for some reason)
             * that the pData is *not* a valid pData structure.
             * We need to compare it with the test string.
             * This may cause an exception. This typically
             * happens when focus in inside of an edit control
             * and you hit some hot key mapped to a button.
             */
            try {
                if( 0 == strcmp(_PERL_DATA_TEST_STRING, (char*) pData->pTest)) {
                    switch( iType ) {
                    case EMBEDDED_PERL_OBJECT:
                        pReturn = (void *) pData->pPerl;
                        break;

                    case EMBEDDED_SELF_OBJECT:
						/*
#ifdef PERLWIN32GUI_STRONGDEBUG
						printf("!XS(ExtractPerlObject) pData is valid (hvSelf=%ld)\n", (long) pData->hvSelf);
#endif
						*/
                        pReturn = (void *) pData->hvSelf;
                        break;
                    }
                }
/*
#ifdef PERLWIN32GUI_STRONGDEBUG
				  else {
					printf("!XS(ExtractPerlObject) pData is NOT valid\n");
				}
#endif
*/

            }
            catch(...) { }
        }
		/*
#ifdef PERLWIN32GUI_STRONGDEBUG
		printf("!XS(ExtractPerlObject) returning %ld\n", pReturn);
#endif
		*/
        return( pReturn );
    }

    void CleanUpWindow(HWND pHwnd) {
        PerlData *pData = (PerlData *) GetWindowLong(pHwnd, GWL_USERDATA);
        if( NULL != pData ) {
            try {
                if( 0 == strcmp((char*) pData->pTest, _PERL_DATA_TEST_STRING)) {
                    delete pData;
                    pData = NULL;
                }
            }
            catch(...) { }
        }
    }

#else   // not PERL_OBJECT
	SV *
	SV_SELF_FROM_WINDOW(HWND hwnd) {
		LPPERLWIN32GUI_USERDATA perlud;

		perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLong(hwnd, GWL_USERDATA);
		if(perlud != NULL && perlud->dwSize == sizeof(PERLWIN32GUI_USERDATA)) {
			return perlud->svSelf;
		} else {
			return NULL;
		}
	}
#   define HV_SELF_FROM_WINDOW(x) (SV_SELF_FROM_WINDOW(x) ? (HV*)SvRV(SV_SELF_FROM_WINDOW(x)) : NULL)
#endif  // PERL_OBJECT

#undef WORD
#define WORD __TEMP_WORD

/*
 * Section for the constant definitions.
 */
#define CROAK croak


/*
 * some Perl macros
 */
#define SETIV(index,value) sv_setiv(ST(index), value)
#define SETPV(index,string) sv_setpv(ST(index), string)
#define SETPVN(index, buffer, length) sv_setpvn(ST(index), (char*)buffer, length)

#define NEW(x,v,n,t)  (v = (t*)safemalloc((MEM_SIZE)((n) * sizeof(t))))

#ifndef SvIV
#define SvIV(sv) (SvIOK(sv) ? SvIVX(sv) : sv_2iv(sv))
#endif

#ifndef SvPV
#define SvPV(sv, lp) (SvPOK(sv) ? ((lp = SvCUR(sv)), SvPVX(sv)) : sv_2pv(sv, &lp))
#endif

#define PERLPUSHMARK(p) if (++markstack_ptr == markstack_max)   \
    markstack_grow();           \
    *markstack_ptr = (p) - stack_base

#define PERLXPUSHs(s)   do {\
    if (stack_max - sp < 1) {\
        sp = stack_grow(sp, sp, 1);\
    }\
    (*++sp = (s)); } while (0)

#ifdef NT_BUILD_NUMBER
#   define boolSV(b) ((b) ? &sv_yes : &sv_no)
#   ifndef dowarn
#       define dowarn FALSE
#   endif
#endif

/*
 * other useful things
 */
#define SwitchFlag(style, flag, switch) \
    if(switch == 0) { \
        if(style & flag) { \
            style ^= flag; \
        } \
    } else { \
        if(!(style & flag)) { \
            style |= flag; \
        } \
    }

/*
 * default procedures for controls (not really to be used yet)
 */
static WNDPROC DefButtonProc;
static WNDPROC DefListboxProc;
static WNDPROC DefTabStripProc;
static WNDPROC DefRichEditProc;

/*
 * constants definition
 */
#include "constants.c"

/*
    ###########################################################################
    # helper routines
    ###########################################################################
 */

static void
hv_magic_check (NOTXSPROC HV *hv, bool *needs_copy, bool *needs_store)
{
    MAGIC *mg = SvMAGIC(hv);
    *needs_copy = FALSE;
    *needs_store = TRUE;
    while (mg) {
	if (isUPPER(mg->mg_type)) {
	    *needs_copy = TRUE;
	    switch (mg->mg_type) {
	    case 'P':
	    case 'S':
		*needs_store = FALSE;
	    }
	}
#ifdef PERLWIN32GUI_STRONGDEBUG
    printf("!XS(hv_magic_check) magic='%c' needs_store='%d'\n", mg->mg_type, *needs_store);
#endif
	mg = mg->mg_moremagic;
    }
}

    /*
     ##########################################################################
     # (@)INTERNAL:handle_From(SV*)
     # gets the handle from either the blessed object
     # or the SV passed
     */
HWND handle_From(NOTXSPROC SV *pSv) {
    HWND hReturn = 0;
    char szKey[] = "-handle";

    if(NULL != pSv)  {
        if( SvROK(pSv)) {
            SV **pHv;
            pHv = hv_fetch((HV*) SvRV(pSv), szKey, strlen(szKey), 0);
 			if(SvMAGICAL((HV*) SvRV(pSv))) mg_get(*pHv);
            if(pHv != NULL) {
                hReturn = (HWND) SvIV(*pHv);
            }
        } else {
            hReturn = (HWND) SvIV(pSv);
        }
    }
    return(hReturn);
}

    /*
     ##########################################################################
     # (@)INTERNAL:classname_From(SV*)
     # gets the window class name from either the blessed object
     # or the SV passed
     */
char *classname_From(NOTXSPROC SV *pSv) {
    char *pszName = NULL;
    char szKey[] = "-name";

    if(NULL != pSv) {
        if(SvROK(pSv)) {
            SV **pHv;
            pHv = hv_fetch((HV*) SvRV(pSv), szKey, strlen(szKey), 0);
            if(SvMAGICAL((HV*) SvRV(pSv))) mg_get(*pHv);
            if(pHv != NULL) {
                pszName = SvPV_nolen(*pHv);
            }
        } else {
            pszName = SvPV_nolen(pSv);
        }
    }
    return(pszName);
}


    /*
     ##########################################################################
     # (@)INTERNAL:SvCOLORREF(SV*)
     # returns a COLORREF from either a numerical value
     # or a color expressed as [RR, GG, BB]
     # or a color expressed in HTML notation (#RRGGBB)
     */
COLORREF SvCOLORREF(NOTXSPROC SV* c) {
    SV** t;
    int r;
    int g;
    int b;
    COLORREF color;
    char html_color[8];
    char html_color_component[3];

	ZeroMemory(html_color, 8);
	ZeroMemory(html_color_component, 3);
    r = 0;
    g = 0;
    b = 0;
    if(SvROK(c) && SvTYPE(SvRV(c)) == SVt_PVAV) {
        t = av_fetch((AV*)SvRV(c), 0, 0);
        if(t != NULL) {
            r = SvIV(*t);
        }
        t = av_fetch((AV*)SvRV(c), 1, 0);
        if(t!= NULL) {
            g = SvIV(*t);
        }
        t = av_fetch((AV*)SvRV(c), 2, 0);
        if(t != NULL) {
            b = SvIV(*t);
        }
        return RGB((BYTE) r, (BYTE) g, (BYTE) b);
    } else {
		if(SvPOK(c)) {
			strncpy(html_color, SvPV_nolen(c), 7);
			if(strncmp(html_color, "#", 1) == 0) {
				strncpy(html_color_component, html_color+1, 2);
				*(html_color_component+2) = 0;
				sscanf(html_color_component, "%x", &r);
				strncpy(html_color_component, html_color+3, 2);
				*(html_color_component+2) = 0;
				sscanf(html_color_component, "%x", &g);
				strncpy(html_color_component, html_color+5, 2);
				*(html_color_component+2) = 0;
				sscanf(html_color_component, "%x", &b);
				return RGB((BYTE) r, (BYTE) g, (BYTE) b);
			} else {
        		return (COLORREF) SvIV(c);
			}
		} else {
        	return (COLORREF) SvIV(c);
		}
    }
}

    /*
     ##########################################################################
     # (@)INTERNAL:CalcControlSize(*perlcs, add_x, add_y)
     # Used by some control to automatically set width and height at creation
     # time.
     */
void CalcControlSize(
    NOTXSPROC
    LPPERLWIN32GUI_CREATESTRUCT perlcs,
    int add_x,
    int add_y
) {
    SIZE mySize;
    HDC hdc;
    SV** font;
    HFONT hfont;
    if(perlcs->cs.lpszName != NULL) {
        if(perlcs->cs.cx == 0 || perlcs->cs.cy == 0) {
            hdc = GetDC(perlcs->cs.hwndParent);
            if(perlcs->hFont != NULL) {
                hfont = perlcs->hFont;
            } else {
                hfont = (HFONT) GetStockObject(DEFAULT_GUI_FONT);
                if(perlcs->hvParent != NULL) {
                    font = hv_fetch(perlcs->hvParent, "-font", 5, FALSE);
                    if(SvMAGICAL(perlcs->hvParent)) mg_get(*font);
                    if(font != NULL && SvOK(*font)) {
                        hfont = (HFONT) handle_From(NOTXSCALL *font);
                    }
                }
            }
            SelectObject(hdc, hfont);
            if(GetTextExtentPoint32(
                hdc, perlcs->cs.lpszName, strlen(perlcs->cs.lpszName), &mySize
            )) {
                if(perlcs->cs.cx == 0) perlcs->cs.cx = mySize.cx + add_x;
                if(perlcs->cs.cy == 0) perlcs->cs.cy = mySize.cy + add_y;
            }
            ReleaseDC(perlcs->cs.hwndParent, hdc);
        }
    }
}

    /*
     ##########################################################################
     # (@)INTERNAL:GetObjectName(hwnd, *name)
     # Gets the object's name;
     # returns FALSE if no name found.
     */
BOOL GetObjectName(NOTXSPROC HWND hwnd, char *Name) {

	LPPERLWIN32GUI_USERDATA perlud;
	perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLong(hwnd, GWL_USERDATA);
#ifdef PERLWIN32GUI_STRONGDEBUG
	printf("!XS(GetObjectName): perlud=%ld\n", perlud);
#endif
	if(NULL != perlud && perlud->dwSize == sizeof(PERLWIN32GUI_USERDATA)) {
		strcat(Name, (char *) perlud->szWindowName);
		return TRUE;
	} else {
		return FALSE;
	}
	/*
	HV* self;
    SV** name;
    self = HV_SELF_FROM_WINDOW(hwnd);
    if(self == NULL) return FALSE;
    name = hv_fetch(self, "-name", 5, FALSE);
	if(SvMAGICAL(self)) mg_get(*name);
    if(name == NULL) return FALSE;
    strcat(Name, (char *) SvPV_nolen(*name));
    return TRUE;
	*/
}

    /*
     ##########################################################################
     # (@)INTERNAL:GetObjectNameAndClass(hwnd, *name, *class)
     # Gets the object's name AND class (integer);
     # returns FALSE if no name found.
     */
BOOL GetObjectNameAndClass(NOTXSPROC HWND hwnd, char *Name, int *obj_class) {

	LPPERLWIN32GUI_USERDATA perlud;

	perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLong(hwnd, GWL_USERDATA);

#ifdef PERLWIN32GUI_STRONGDEBUG
	printf("!XS(GetObjectNameAndClass): perlud=%ld\n", perlud);
#endif

	if(NULL != perlud && perlud->dwSize == sizeof(PERLWIN32GUI_USERDATA)) {
		strcat(Name, (char *) perlud->szWindowName);
		*obj_class = perlud->iClass;
#ifdef PERLWIN32GUI_STRONGDEBUG
		printf("!XS(GetObjectNameAndClass): returning TRUE\n");
#endif
		return TRUE;
	} else {
#ifdef PERLWIN32GUI_STRONGDEBUG
		printf("!XS(GetObjectNameAndClass): returning FALSE\n");
#endif
		return FALSE;
	}
	/*
	HV* self;
    SV** name;
    SV** type;
    self = HV_SELF_FROM_WINDOW(hwnd);
    if(self == NULL) return FALSE;
    name = hv_fetch(self, "-name", 5, FALSE);
    if(SvMAGICAL(self)) mg_get(*name);
    if(name == NULL) return FALSE;
    strcat(Name, (char *) SvPV_nolen(*name));
    type = hv_fetch(self, "-type", 5, FALSE);
    if(SvMAGICAL(self)) mg_get(*type);
    if(type == NULL) return FALSE;
    *obj_class = SvIV(*type);
    return TRUE;
	*/
}

    /*
     ##########################################################################
     # (@)INTERNAL:GetMenuName(ID, *name)
     # Gets the menu name from the ID;
     # returns FALSE if no name found.
     */
BOOL GetMenuName(NOTXSPROC int nID, char *Name) {
    HV* hash;
    SV** obj;
    SV** name;
    char temp[80];
    hash = perl_get_hv("Win32::GUI::Menus", FALSE);
    itoa(nID, temp, 10);
    obj = hv_fetch(hash, temp, strlen(temp), FALSE);
    if(SvMAGICAL(hash)) mg_get(*obj);
    if(obj == NULL) return FALSE;
    name = hv_fetch( ( (HV*) SvRV(*obj)), "-name", 5, FALSE);
    if(SvMAGICAL((HV*) SvRV(*obj))) mg_get(*name);
    if(name == NULL) return FALSE;
    strcat(Name, (char *) SvPV_nolen(*name));
    return TRUE;
}

    /*
     ##########################################################################
     # (@)INTERNAL:GetAcceleratorName(ID, *name)
     # Gets the accelerator name from the ID;
     # returns FALSE if no name found.
     */
BOOL GetAcceleratorName(NOTXSPROC int nID, char *Name) {
    HV* hash;
    SV** name;
    char temp[80];
    hash = perl_get_hv("Win32::GUI::Accelerators", FALSE);
    itoa(nID, temp, 10);
    name = hv_fetch(hash, temp, strlen(temp), FALSE);
    if(SvMAGICAL(hash)) mg_get(*name);
    if(name == NULL) return FALSE;
    strcat(Name, (char *) SvPV_nolen(*name));
    return TRUE;
}

    /*
     ##########################################################################
     # (@)INTERNAL:GetTimerName(hwnd, id, *name)
     # Gets the timer name;
     # returns FALSE if no name found.
     */
BOOL GetTimerName(NOTXSPROC HWND hwnd, UINT nID, char *Name) {
    HV*  parent;
    SV** name;
    SV** robjarray;
    HV*  objarray;
    SV** robj;
    HV*  obj;
    char temp[80];
    parent = HV_SELF_FROM_WINDOW(hwnd);
    if(parent == NULL) return FALSE;
    itoa(nID, temp, 10);
    robjarray = hv_fetch(parent, "-timers", 7, FALSE);
    if(SvMAGICAL(parent)) mg_get(*robjarray);
    if(robjarray == NULL) return FALSE;
    objarray = (HV*) SvRV(*robjarray);
    robj = hv_fetch(objarray, temp, strlen(temp), FALSE);
    if(SvMAGICAL(objarray)) mg_get(*robj);
    if(robj == NULL) return FALSE;
    obj = (HV*) SvRV(*robj);
    if(obj == NULL) return FALSE;
    name = hv_fetch(obj, "-name", 5, FALSE);
    if(SvMAGICAL(obj)) mg_get(*name);
    if(name == NULL) return FALSE;
    strcat(Name, (char *) SvPV_nolen(*name));
    return TRUE;
}

    /*
     ##########################################################################
     # (@)INTERNAL:GetNotifyIconName(hwnd, id, *name)
     # Gets the NotifyIcon name;
     # returns FALSE if no name found.
     */
BOOL GetNotifyIconName(NOTXSPROC HWND hwnd, UINT nID, char *Name) {
    HV*  parent;
    SV** name;
    SV** robjarray;
    HV*  objarray;
    SV** robj;
    HV*  obj;
    char temp[80];
    parent = HV_SELF_FROM_WINDOW(hwnd);
    if(parent == NULL) return FALSE;
    itoa(nID, temp, 10);
    robjarray = hv_fetch(parent, "-notifyicons", 12, FALSE);
    if(SvMAGICAL(parent)) mg_get(*robjarray);
    if(robjarray == NULL) return FALSE;
    objarray = (HV*) SvRV(*robjarray);
    robj = hv_fetch(objarray, temp, strlen(temp), FALSE);
    if(SvMAGICAL(objarray)) mg_get(*robj);
    if(robj == NULL) return FALSE;
    obj = (HV*) SvRV(*robj);
    name = hv_fetch(obj, "-name", 5, FALSE);
    if(SvMAGICAL(obj)) mg_get(*name);
    if(name == NULL) return FALSE;
    strcat(Name, (char *) SvPV_nolen(*name));
    return TRUE;
}


DWORD CALLBACK RichEditSave(DWORD dwCookie, LPBYTE pbBuff, LONG cb, LONG FAR *pcb) {
    HANDLE hfile;
    hfile = (HANDLE) dwCookie;
    WriteFile(hfile, (LPCVOID) pbBuff, (DWORD) cb, (LPDWORD) pcb, NULL);
    return(0);
}

DWORD CALLBACK RichEditLoad(DWORD dwCookie, LPBYTE pbBuff, LONG cb, LONG FAR *pcb) {
    HANDLE hfile;
    hfile = (HANDLE) dwCookie;
    ReadFile(hfile, (LPVOID) pbBuff, (DWORD) cb, (LPDWORD) pcb, NULL);
    return(0);
}

/*
BOOL EnumChildsProc(HWND hwnd, LPARAM lParam) {
#ifdef PERL_OBJECT
    CPerl *pPerl = PERL_OBJECT_FROM_WINDOW(hwnd);
#endif
    XPUSHs(HV_SELF_FROM_WINDOW(hwnd));
    ((UINT)*lParam)++;
    return TRUE;
}
*/

    /*
     ##########################################################################
     # (@)INTERNAL:AdjustSplitterCoord(self, x)
     */
int AdjustSplitterCoord(NOTXSPROC HV* self, int x, HWND phwnd) {
	int min, max;
	int adjusted;
	RECT rc;
	SV** fetching;

	adjusted = x;
	min = -1;
	fetching = hv_fetch(self, "-min", 4, FALSE);
	if(SvMAGICAL(self)) mg_get(*fetching);
	if(fetching != NULL && SvOK(*fetching)) {
		min = SvIV(*fetching);
	}
	if(min == -1) min = 0;
	GetClientRect(phwnd, &rc);
	max = -1;
	fetching = hv_fetch(self, "-max", 4, FALSE);
	if(SvMAGICAL(self)) mg_get(*fetching);
	if(fetching != NULL && SvOK(*fetching)) {
		max = SvIV(*fetching);
	}
	if(max == -1) max = rc.right;
	if(adjusted < min) adjusted = min;
	if(adjusted > max) adjusted = max;
	return(adjusted);
}

    /*
     ##########################################################################
     # (@)INTERNAL:DrawSplitter(hwnd)
     */
void DrawSplitter(NOTXSPROC HWND hwnd) {
	RECT rc;
	HDC hdc;
	HBRUSH oldBrush;
	HPEN oldPen;

	hdc = GetDC(hwnd);
	oldBrush = SelectObject(hdc, GetStockObject(GRAY_BRUSH));
	oldPen = SelectObject(hdc, GetStockObject(NULL_PEN));
	GetClientRect(hwnd, &rc);
	PatBlt(hdc, rc.left, rc.top, rc.right-rc.left, rc.bottom-rc.top, DSTINVERT);
	if(oldBrush != NULL) SelectObject(hdc, oldBrush);
	if(oldPen   != NULL) SelectObject(hdc, oldPen  );
	ReleaseDC(hwnd, hdc);
}


/*
    ###########################################################################
    # event processing routines
    ###########################################################################
 */

    /*
     ##########################################################################
     # (@)INTERNAL:ProcessEventError(Name, *PerlResult)
     # Pops up a message box in case of error within an event;
     # returns TRUE if errors were, FALSE otherwise, and sets PerlResult
     # according to user's click (CANCEL == -1),
     */
BOOL ProcessEventError(NOTXSPROC char *Name, int* PerlResult) {
    if(strncmp(Name, "main::", 6) == 0) Name += 6;
    if(SvTRUE(ERRSV)) {
        MessageBeep(MB_ICONASTERISK);
        *PerlResult = MessageBox(
            NULL,
            SvPV_nolen(ERRSV),
            Name,
            MB_ICONERROR | MB_OKCANCEL
        );
        if(*PerlResult == IDCANCEL) {
            *PerlResult = -1;
        }
        return TRUE;
    } else {
        return FALSE;
    }
}

    /*
     ##########################################################################
     # (@)INTERNAL:DoEvent_Generic(name)
     # Calls an event without arguments;
     # Name must be pre-filled.
     */
int DoEvent_Generic(NOTXSPROC char *Name) {
    int PerlResult;
    int count;
    PerlResult = 1;
#ifdef PERLWIN32GUI_DEBUG
    printf("!XS(DoEvent_Generic): EVENT: %s\n", Name);
#endif
    if(perl_get_cv(Name, FALSE) != NULL) {
        dSP;
        dTARG;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        PUTBACK;
        count = perl_call_pv(Name, G_EVAL|G_NOARGS);
        SPAGAIN;
        if(!ProcessEventError(NOTXSCALL Name, &PerlResult)) {
            if(count > 0) PerlResult = POPi;
        }
        PUTBACK;
        FREETMPS;
        LEAVE;
    }
#ifdef PERLWIN32GUI_DEBUG
    printf("!XS(DoEvent_Generic): returning %d\n", PerlResult);
#endif
    return PerlResult;
}


    /*
     ##########################################################################
     # (@)INTERNAL:DoEvent_Long(name,arg)
     # Same as above, but with a long argument.
     */
int DoEvent_Long(NOTXSPROC char *Name, long argh) {
    int PerlResult;
    int count;
    PerlResult = 1;
#ifdef PERLWIN32GUI_DEBUG
    printf("!XS(DoEvent_Long): EVENT: %s\n", Name);
#endif
    if(perl_get_cv(Name, FALSE) != NULL) {
        dSP;
        dTARG;
        ENTER ;
        SAVETMPS;
        PUSHMARK(SP) ;
        XPUSHs(sv_2mortal(newSViv(argh)));
        PUTBACK ;
        count = perl_call_pv(Name, G_EVAL|G_ARRAY);
        SPAGAIN ;
        if(!ProcessEventError(NOTXSCALL Name, &PerlResult)) {
            if(count > 0) PerlResult = POPi;
        }
        PUTBACK ;
        FREETMPS ;
        LEAVE ;
    }
    return PerlResult;
}


    /*
     ##########################################################################
     # (@)INTERNAL:DoEvent_TwoLongs(name,arg1,arg2)
     # Same as above, but with two long arguments.
     */
int DoEvent_TwoLongs(NOTXSPROC char *Name, long argone, long argtwo) {
    int PerlResult;
    int count;
    PerlResult = 1;
#ifdef PERLWIN32GUI_DEBUG
    printf("!XS(DoEvent_TwoLongs): EVENT: %s\n", Name);
#endif
    if(perl_get_cv(Name, FALSE) != NULL) {
        dSP;
        dTARG;
        ENTER ;
        SAVETMPS;
        PUSHMARK(SP) ;
        XPUSHs(sv_2mortal(newSViv(argone)));
        XPUSHs(sv_2mortal(newSViv(argtwo)));
        PUTBACK ;
        count = perl_call_pv(Name, G_EVAL|G_ARRAY);
        SPAGAIN ;
        if(!ProcessEventError(NOTXSCALL Name, &PerlResult)) {
            if(count > 0) PerlResult = POPi;
        }
        PUTBACK ;
        FREETMPS ;
        LEAVE ;
    }
    return PerlResult;
}


    /*
     ##########################################################################
     # (@)INTERNAL:DoEvent_ButtonClick(name, wparam)
     # calls a toolbar's WM_COMMAND event
     # adds "_ButtonClick" to Name
     */
int DoEvent_ButtonClick(NOTXSPROC char *Name, WPARAM wParam) {
    int PerlResult;
    int count;
    PerlResult = 1;
    strcat(Name, "_ButtonClick");
#ifdef PERLWIN32GUI_DEBUG
    printf("!XS(DoEvent_ButtonClick): EVENT: %s\n", Name);
#endif
    if(perl_get_cv(Name, FALSE) != NULL) {
        dSP;
        dTARG;
        ENTER ;
        SAVETMPS;
        PUSHMARK(SP) ;
        XPUSHs(sv_2mortal(newSViv(LOWORD(wParam))));
        PUTBACK ;
        count = perl_call_pv(Name, G_EVAL|G_ARRAY);
        SPAGAIN ;
        if(!ProcessEventError(NOTXSCALL Name, &PerlResult)) {
            if(count > 0) PerlResult = POPi;
        }
        PUTBACK ;
        FREETMPS ;
        LEAVE ;
    }
    return PerlResult;
}


    /*
     ##########################################################################
     # (@)INTERNAL:DoEvent_ListView(name, lparam)
     # calls a listview's item event
     */
int DoEvent_ListView(NOTXSPROC char *Name, LPARAM lParam) {
    int PerlResult;
    int count;
    LPNM_LISTVIEW lv_notify;
    long argh;
    PerlResult = 1;
    lv_notify = (LPNM_LISTVIEW) lParam;
    switch(lv_notify->hdr.code) {
    case LVN_ITEMCHANGED:
        strcat(Name, "_ItemClick");
        argh = (long) lv_notify->iItem;
        break;
    case LVN_COLUMNCLICK:
        strcat(Name, "_ColumnClick");
        argh = (long) lv_notify->iSubItem;
        break;
    }
#ifdef PERLWIN32GUI_DEBUG
    printf("!XS(DoEvent_ListView): EVENT: %s\n", Name);
#endif
    if(perl_get_cv(Name, FALSE) != NULL) {
        dSP;
        dTARG;
        ENTER ;
        SAVETMPS;
        PUSHMARK(SP) ;
        XPUSHs(sv_2mortal(newSViv(argh)));
        PUTBACK ;
        count = perl_call_pv(Name, G_EVAL|G_ARRAY);
        SPAGAIN ;
        if(!ProcessEventError(NOTXSCALL Name, &PerlResult)) {
            if(count > 0) PerlResult = POPi;
        }
        PUTBACK ;
        FREETMPS ;
        LEAVE ;
    }
    return PerlResult;
}

    /*
     ##########################################################################
     # (@)INTERNAL:DoEvent_TreeView(name, lparam)
     # calls a treeview's node event
     */
int DoEvent_TreeView(NOTXSPROC char *Name, LPARAM lParam) {
    int PerlResult;
    int count;
    LPNM_TREEVIEW tv_notify;
    PerlResult = 1;
    tv_notify = (LPNM_TREEVIEW) lParam;
    switch(tv_notify->hdr.code) {
    case TVN_SELCHANGED:
        strcat(Name, "_NodeClick");
        break;
    case TVN_ITEMEXPANDED:
        if(tv_notify->action == TVE_COLLAPSE)
            strcat(Name, "_Collapse");
        else
            strcat(Name, "_Expand");
        break;
    case TVN_ITEMEXPANDING:
        if(tv_notify->action == TVE_COLLAPSE)
            strcat(Name, "_Collapsing");
        else
            strcat(Name, "_Expanding");
        break;
    }
#ifdef PERLWIN32GUI_DEBUG
    printf("!XS(DoEvent_TreeView): EVENT: %s\n", Name);
#endif
	if(perl_get_cv(Name, FALSE) != NULL) {
        dSP;
        dTARG;
        ENTER ;
        SAVETMPS;
        PUSHMARK(SP) ;
        XPUSHs(sv_2mortal(newSViv((long) tv_notify->itemNew.hItem)));
        PUTBACK ;
        count = perl_call_pv(Name, G_EVAL|G_ARRAY);
        SPAGAIN ;
        if(!ProcessEventError(NOTXSCALL Name, &PerlResult)) {
            if(count > 0) PerlResult = POPi;
        }
        PUTBACK ;
        FREETMPS ;
        LEAVE ;
    }
    return PerlResult;
}

    /*
     ##########################################################################
     # (@)INTERNAL:DoEvent_MouseMove(name, lparam, wparam)
     # calls a WM_MOUSEMOVE event
     # adds "_MouseMove" to Name
     */
int DoEvent_MouseMove(NOTXSPROC char *Name, WPARAM wParam, LPARAM lParam) {
    int PerlResult;
    int count;
    PerlResult = 1;
    strcat(Name, "_MouseMove");
#ifdef PERLWIN32GUI_DEBUG
    printf("!XS(DoEvent_MouseMove): EVENT: %s\n", Name);
#endif
    if(perl_get_cv(Name, FALSE) != NULL) {
        dSP;
        dTARG;
        ENTER ;
        SAVETMPS;
        PUSHMARK(SP) ;
        XPUSHs(sv_2mortal(newSViv(wParam)));
        XPUSHs(sv_2mortal(newSViv(LOWORD(lParam))));
        XPUSHs(sv_2mortal(newSViv(HIWORD(lParam))));
        PUTBACK ;
        count = perl_call_pv(Name, G_EVAL|G_ARRAY);
        SPAGAIN ;
        if(!ProcessEventError(NOTXSCALL Name, &PerlResult)) {
            if(count > 0) PerlResult = POPi;
        }
        PUTBACK ;
        FREETMPS ;
        LEAVE ;
    }
    return PerlResult;
}

    /*
     ##########################################################################
     # (@)INTERNAL:DoEvent_MouseButton(name, wparam, lparam)
     # calls a WM_(L/R)BUTTON(UP/DOWN) event
     # Name must be pre-filled
     */
int DoEvent_MouseButton(NOTXSPROC char *Name, WPARAM wParam, LPARAM lParam) {
    int PerlResult;
    int count;
    PerlResult = 1;
#ifdef PERLWIN32GUI_DEBUG
    printf("!XS(DoEvent_MouseButton): EVENT: %s\n", Name);
#endif
    if(perl_get_cv(Name, FALSE) != NULL) {
        dSP;
        dTARG;
        ENTER ;
        SAVETMPS;
        PUSHMARK(SP) ;
        XPUSHs(sv_2mortal(newSViv(wParam)));
        XPUSHs(sv_2mortal(newSViv(LOWORD(lParam))));
        XPUSHs(sv_2mortal(newSViv(HIWORD(lParam))));
        PUTBACK ;
        count = perl_call_pv(Name, G_EVAL|G_ARRAY);
        SPAGAIN ;
        if(!ProcessEventError(NOTXSCALL Name, &PerlResult)) {
            if(count > 0) PerlResult = POPi;
        }
        PUTBACK ;
        FREETMPS ;
        LEAVE ;
    }
    return PerlResult;
}


    /*
     ##########################################################################
     # (@)INTERNAL:DoEvent_NeetText(name, id)
     # calls a TTN_NEEDTEXT event ("callback"?)
     # adds "_NeedText" to Name
     */
char * DoEvent_NeedText(NOTXSPROC char *Name, UINT id) {
    int PerlResult;
    static char *textneeded;
    SV* svt;
    int count;
    strcat(Name, "_NeedText");
    if(textneeded != NULL) {
        safefree(textneeded);
        textneeded = NULL;
    }
#ifdef PERLWIN32GUI_DEBUG
    printf("!XS(DoEvent_NeedText): EVENT: %s\n", Name);
#endif
    if(perl_get_cv(Name, FALSE) != NULL) {
        dSP;
        dTARG;
        ENTER ;
        SAVETMPS;
        PUSHMARK(SP) ;
        XPUSHs(sv_2mortal(newSViv(id)));
        PUTBACK ;
        count = perl_call_pv(Name, G_EVAL|G_ARRAY);
        SPAGAIN ;
        if(!ProcessEventError(NOTXSCALL Name, &PerlResult)) {
            if(count > 0) {
                svt = POPs;
                textneeded = (char *) safemalloc(sv_len(svt));
                strcpy(textneeded, SvPV_nolen(svt));
            } else {
#ifdef PERLWIN32GUI_STRONGDEBUG
                printf("!XS(DoEvent_NeedText): sub returned nothing\n");
#endif
            }
        }
        PUTBACK ;
        FREETMPS ;
        LEAVE ;
    }
#ifdef PERLWIN32GUI_DEBUG
    printf("!XS(DoEvent_NeedText): returning '%s'\n", textneeded);
#endif
    return textneeded;
}


/*
    ###########################################################################
    # message loops
    ###########################################################################
*/


    /*
    ###########################################################################
    # (@)INTERNAL:SplitterMsgLoop(hwnd, uMsg, wParam, lParam)
    # message loop for Win32::GUI::Splitter objects
    */
LRESULT CALLBACK SplitterMsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    int PerlResult;
    char Name[MAX_EVENT_NAME];
    HV* self;
    SV** fetching;
    SV* storing;
    long tracking, horizontal;
    int min;
    int max;
    POINT pt;
    HWND phwnd;
    HDC hdc;
    RECT rc;
	LPPERLWIN32GUI_USERDATA perlud;

#ifdef PERLWIN32GUI_STRONGDEBUG
    printf("!XS(SplitterMsgLoop) got (%ld, 0x%x, %ld, %ld)\n", hwnd, uMsg, wParam, lParam);
#endif

    if(uMsg == WM_DESTROY) {
		safefree( (LPPERLWIN32GUI_USERDATA) GetWindowLong(hwnd, GWL_USERDATA));
		return DefWindowProc(hwnd, uMsg, wParam, lParam);
	}

#ifdef PERL_OBJECT
	pPerl = ((LPPERLWIN32GUI_USERDATA) GetWindowLong(hwnd, GWL_USERDATA))->pPerl;
#endif

    PerlResult = 1;
    strcpy(Name, "main::");
    if(GetObjectName(NOTXSCALL hwnd, Name)) {
        switch(uMsg) {
        case WM_MOUSEMOVE:
        	self = HV_SELF_FROM_WINDOW(hwnd);
			fetching = hv_fetch(self, "-tracking", 9, FALSE);
			if(SvMAGICAL(self)) mg_get(*fetching);
			if(fetching != NULL) {
				tracking = SvIV(*fetching);
				if(tracking) {
					fetching = hv_fetch(self, "-horizontal", 11, FALSE);
					if(SvMAGICAL(self)) mg_get(*fetching);
					if(fetching != NULL && SvOK(*fetching)) {
						horizontal = SvIV(*fetching);
					}
					if(horizontal > 0) {
						phwnd = GetParent(hwnd);
						GetCursorPos(&pt);
						ScreenToClient(phwnd, &pt);
						pt.y = AdjustSplitterCoord(NOTXSCALL self, pt.y, phwnd);
						DrawSplitter(NOTXSCALL hwnd);
						GetClientRect(hwnd, &rc);
						SetWindowPos(hwnd, NULL, rc.left, pt.y, 0, 0, SWP_NOZORDER | SWP_NOSIZE);
						DrawSplitter(NOTXSCALL hwnd);
					} else {
						phwnd = GetParent(hwnd);
						GetCursorPos(&pt);
						ScreenToClient(phwnd, &pt);
						pt.x = AdjustSplitterCoord(NOTXSCALL self, pt.x, phwnd);
						DrawSplitter(NOTXSCALL hwnd);
						GetClientRect(hwnd, &rc);
						SetWindowPos(hwnd, NULL, pt.x, rc.top, 0, 0, SWP_NOZORDER | SWP_NOSIZE);
						DrawSplitter(NOTXSCALL hwnd);
					}
				}
			}
            break;
        case WM_LBUTTONDOWN:
        	self = HV_SELF_FROM_WINDOW(hwnd);
			storing = newSViv((long) 1);
			hv_store(self, "-tracking", 9, storing, 0);
			if(SvMAGICAL(self)) mg_set(storing);
			fetching = hv_fetch(self, "-horizontal", 11, FALSE);
			if(SvMAGICAL(self)) mg_get(*fetching);
			if(fetching != NULL && SvOK(*fetching)) {
				horizontal = SvIV(*fetching);
			}
			if(horizontal > 0) {
				phwnd = GetParent(hwnd);
				GetCursorPos(&pt);
				ScreenToClient(phwnd, &pt);
				pt.y = AdjustSplitterCoord(NOTXSCALL self, pt.y, phwnd);
				DrawSplitter(NOTXSCALL hwnd);
				SetCapture(hwnd);
			} else {
				phwnd = GetParent(hwnd);
				GetCursorPos(&pt);
				ScreenToClient(phwnd, &pt);
				pt.x = AdjustSplitterCoord(NOTXSCALL self, pt.x, phwnd);
				DrawSplitter(NOTXSCALL hwnd);
				SetCapture(hwnd);
			}
            break;
		case WM_LBUTTONUP:
        	self = HV_SELF_FROM_WINDOW(hwnd);
			fetching = hv_fetch(self, "-tracking", 9, FALSE);
			if(SvMAGICAL(self)) mg_get(*fetching);
			if(fetching != NULL) {
				tracking = SvIV(*fetching);
				if(tracking) {
					fetching = hv_fetch(self, "-horizontal", 11, FALSE);
					if(SvMAGICAL(self)) mg_get(*fetching);
					if(fetching != NULL && SvOK(*fetching)) {
						horizontal = SvIV(*fetching);
					}
					/*
					 * (@)EVENT:Release(COORD)
					 * Sent when the Splitter is released after being
					 * dragged to a new location (identified by the
					 * COORD parameter).
					 * (@)APPLIES_TO:Splitter
					 */
					if(horizontal > 0) {
						phwnd = GetParent(hwnd);
						GetCursorPos(&pt);
						ScreenToClient(phwnd, &pt);
						pt.y = AdjustSplitterCoord(NOTXSCALL self, pt.y, phwnd);
						DrawSplitter(NOTXSCALL hwnd);
						strcat(Name, "_Release");
						PerlResult = DoEvent_Long(NOTXSCALL Name, (long) pt.y);
					} else {
						phwnd = GetParent(hwnd);
						GetCursorPos(&pt);
						ScreenToClient(phwnd, &pt);
						pt.x = AdjustSplitterCoord(NOTXSCALL self, pt.x, phwnd);
						DrawSplitter(NOTXSCALL hwnd);
						strcat(Name, "_Release");
						PerlResult = DoEvent_Long(NOTXSCALL Name, (long) pt.x);
					}
				}
			}
			ReleaseCapture();
			storing = newSViv((long) 0);
			hv_store(self, "-tracking", 9, storing, 0);
			if(SvMAGICAL(self)) mg_set(storing);
            break;
        }
    }
    if(PerlResult == 0) {
        return 0;
    } else {
        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }
}

    /*
    ###########################################################################
    # (@)INTERNAL:ButtonMsgLoop(hwnd, uMsg, wParam, lParam)
    # message loop for subclassed Win32::GUI::Button objects
    */
LRESULT CALLBACK ButtonMsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
#ifdef PERL_OBJECT
    CPerl *pPerl;
    PerlData *pData;
    if(uMsg == WM_CREATE || uMsg == WM_NCCREATE) {
        pData = (PerlData *) ((CREATESTRUCT *) lParam)->lpCreateParams;
        if(pData != NULL) {
            pPerl = pData->pPerl;
            SetWindowLong(hwnd, GWL_USERDATA, (long) pData);
        }
        return DefButtonProc(hwnd, uMsg, wParam, lParam);
    } else {
        pPerl = PERL_OBJECT_FROM_WINDOW(hwnd);
    }
#endif
    int PerlResult;
    char Name[MAX_EVENT_NAME];
    PerlResult = 1;
    strcpy(Name, "main::");
    if(GetObjectName(NOTXSCALL hwnd, Name)) {
        switch(uMsg) {
        case WM_MOUSEMOVE:
            PerlResult = DoEvent_MouseMove(NOTXSCALL Name, wParam, lParam);
            break;
        // to implement:
        // MouseUp
        // MouseDown
        // KeyPress
        }
    }
    if(PerlResult == 0) {
        return 0;
    } else {
        return DefButtonProc(hwnd, uMsg, wParam, lParam);
    }
}

    /*
    ###########################################################################
    # (@)INTERNAL:ListboxMsgLoop(hwnd, uMsg, wParam, lParam)
    # message loop for subclassed Win32::GUI::Listbox objects
    */
LRESULT CALLBACK ListboxMsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
#ifdef PERL_OBJECT
    CPerl *pPerl;
    PerlData *pData;
    if(uMsg == WM_CREATE || uMsg == WM_NCCREATE) {
        pData = (PerlData *) ((CREATESTRUCT *) lParam)->lpCreateParams;
        if(pData != NULL) {
            pPerl = pData->pPerl;
            SetWindowLong(hwnd, GWL_USERDATA, (long) pData);
        }
        return DefListboxProc(hwnd, uMsg, wParam, lParam);
    } else {
        pPerl = PERL_OBJECT_FROM_WINDOW(hwnd);
    }
#endif
    int PerlResult;
    char Name[MAX_EVENT_NAME];
    PerlResult = 1;
    strcpy((char *) Name, "main::");
    if(GetObjectName(NOTXSCALL hwnd, Name)) {
        switch(uMsg) {
        case WM_MOUSEMOVE:
            PerlResult = DoEvent_MouseMove(NOTXSCALL Name, wParam, lParam);
            break;
        // to implement:
        // MouseUp
        // MouseDown
        // KeyPress
        }
    }
    if(PerlResult == 0) {
        return 0;
    } else {
        return DefListboxProc(hwnd, uMsg, wParam, lParam);
    }

}

    /*
    ###########################################################################
    # (@)INTERNAL:RichEditMsgLoop(hwnd, uMsg, wParam, lParam)
    # message loop for subclassed Win32::GUI::RichEdit objects
    */
LRESULT CALLBACK RichEditMsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
#ifdef PERLWIN32GUI_STRONGDEBUG
    printf("!XS(RichEditMsgLoop) got (%ld, 0x%x, %ld, %ld)\n", hwnd, uMsg, wParam, lParam);
#endif
#ifdef PERL_OBJECT
    CPerl *pPerl;
    PerlData *pData;
    if(uMsg == WM_CREATE || uMsg == WM_NCCREATE) {
        pData = (PerlData *) ((CREATESTRUCT *) lParam)->lpCreateParams;
        if(pData != NULL) {
            pPerl = pData->pPerl;
            SetWindowLong(hwnd, GWL_USERDATA, (long) pData);
        }
        return DefRichEditProc(hwnd, uMsg, wParam, lParam);
    } else {
        pPerl = PERL_OBJECT_FROM_WINDOW(hwnd);
    }
#endif
    int PerlResult;
    char Name[MAX_EVENT_NAME];
    PerlResult = 1;
    strcpy((char *) Name, "main::");
    if(GetObjectName(NOTXSCALL hwnd, Name)) {
        switch(uMsg) {
        case WM_MOUSEMOVE:
            PerlResult = DoEvent_MouseMove(NOTXSCALL Name, wParam, lParam);
            break;
        case WM_LBUTTONDOWN:
            strcat((char *) Name, "_LButtonDown");
            PerlResult = DoEvent_MouseButton(NOTXSCALL Name, wParam, lParam);
            break;
        case WM_LBUTTONUP:
            strcat((char *) Name, "_LButtonUp");
            PerlResult = DoEvent_MouseButton(NOTXSCALL Name, wParam, lParam);
            break;
        case WM_RBUTTONDOWN:
            strcat((char *) Name, "_RButtonDown");
            PerlResult = DoEvent_MouseButton(NOTXSCALL Name, wParam, lParam);
            break;
        case WM_RBUTTONUP:
            strcat((char *) Name, "_RButtonUp");
            PerlResult = DoEvent_MouseButton(NOTXSCALL Name, wParam, lParam);
            break;
        case WM_CHAR:
            strcat(Name, "_KeyPress");
            PerlResult = DoEvent_Long(NOTXSCALL Name, wParam);
            break;
        // to implement:
        // MouseUp
        // MouseDown
        }
    }
    if(PerlResult == 0) {
        return 0;
    } else {
        return DefRichEditProc(hwnd, uMsg, wParam, lParam);
    }

}

    /*
    ###########################################################################
    # (@)INTERNAL:TabStripMsgLoop(hwnd, uMsg, wParam, lParam)
    # message loop for subclassed Win32::GUI::TabStrip objects
    */
LRESULT CALLBACK TabStripMsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
    // a TabStrip acts like a container, so we simply
    // redirect the messages to our parent and call the default Proc.
    HWND hwndParent;

    if(uMsg == WM_COMMAND || uMsg == WM_NOTIFY) {
        hwndParent = (HWND) GetWindowLong(hwnd, GWL_HWNDPARENT);
        SendMessage(hwndParent, uMsg, wParam, lParam);
        return 0;
    } else {
        return DefTabStripProc(hwnd, uMsg, wParam, lParam);
    }
}

    /*
    ###########################################################################
    # (@)INTERNAL:GraphicMsgLoop(hwnd, uMsg, wParam, lParam)
    # message loop for Win32::GUI::Graphic objects
    */
LRESULT CALLBACK GraphicMsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
#ifdef PERL_OBJECT
    CPerl *pPerl;
    PerlData *pData;
    if(uMsg == WM_CREATE || uMsg == WM_NCCREATE) {
        pData = (PerlData *) ((CREATESTRUCT *) lParam)->lpCreateParams;
        if(pData != NULL) {
            pPerl = pData->pPerl;
            SetWindowLong(hwnd, GWL_USERDATA, (long) pData);
        }
        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    } else {
        pPerl = PERL_OBJECT_FROM_WINDOW(hwnd);
    }
#endif
    int PerlResult;
    int count;
    char Name[MAX_EVENT_NAME];
	HV* self;
	SV* storing;
	SV* newdc;
	SV* newgraphic;
	HV* graphicclass;

    PerlResult = 1;

#ifdef PERLWIN32GUI_STRONGDEBUG
	    printf("!XS(GraphicMsgLoop) got (%ld, 0x%x, %ld, %ld)\n", hwnd, uMsg, wParam, lParam);
#endif
    if(uMsg == WM_PAINT) {
	    strcpy((char *) Name, "main::");
    	if(GetObjectName(NOTXSCALL hwnd, Name)) {
#ifdef PERLWIN32GUI_STRONGDEBUG
			    printf("!XS(GraphicMsgLoop) name=%s\n", Name);
#endif
			strcat((char *) Name, "_Paint");
    		if(perl_get_cv(Name, FALSE) != NULL) {
                /*
                 * (@)EVENT:Paint()
                 * Sent when the Graphic object needs to be repainted.
                 * Note that you need to use GetDC() to get the DC
                 * of the Graphic object where you do your paint
                 * work, and then Validate() the DC to inform Windows
                 * that you painted the DC area (otherwise it will
                 * continue to call the Paint event continuously).
                 * Example:
                 *   sub Graphic_Paint {
                 *       my $DC = $Window->Graphic->GetDC();
                 *       $DC->MoveTo(0, 0);
                 *       $DC->LineTo(100, 100);
                 *       $DC->Validate();
                 *   }
                 * (@)APPLIES_TO:Graphic
                 */

				/*
 				self = HV_SELF_FROM_WINDOW(hwnd);
				storing = newSViv((long) GetDC(hwnd));
 				hv_store(self, "-handle", 7, storing, 0);
 				if(SvMAGICAL(self)) mg_set(storing);
				storing = newSViv((long) hwnd);
 				hv_store(self, "-window", 7, storing, 0);
 				if(SvMAGICAL(self)) mg_set(storing);
                */

        		dSP;
        		dTARG;
        		ENTER;
        		SAVETMPS;
        		PUSHMARK(SP);
#ifdef PERLWIN32GUI_STRONGDEBUG
				    printf("!XS(GraphicMsgLoop) pushing parameters...\n");
#endif
				XPUSHs(sv_2mortal(newSVpv("Win32::GUI::DC", 0)));
#ifdef PERLWIN32GUI_STRONGDEBUG
				    printf("!XS(GraphicMsgLoop) done parameter 1...\n");
#endif
				XPUSHs(SV_SELF_FROM_WINDOW(hwnd));
#ifdef PERLWIN32GUI_STRONGDEBUG
				    printf("!XS(GraphicMsgLoop) done parameter 2...\n");
#endif
        		PUTBACK ;
#ifdef PERLWIN32GUI_STRONGDEBUG
				    printf("!XS(GraphicMsgLoop) doing perl_call...\n");
#endif
				count = perl_call_pv("Win32::GUI::DC::new", 0);
        		SPAGAIN ;
				newdc = newSVsv(POPs);
#ifdef PERLWIN32GUI_STRONGDEBUG
				    printf("!XS(GraphicMsgLoop) perl_call got(%d): %s\n", count, SvPV_nolen(newdc));
#endif
				PUTBACK;
				FREETMPS;
				LEAVE;

				ENTER;
				SAVETMPS;
	       		PUSHMARK(SP);
				XPUSHs(sv_2mortal(newdc));
				// XPUSHs(sv_2mortal(newdc));
#ifdef PERLWIN32GUI_STRONGDEBUG
				    printf("!XS(GraphicMsgLoop) doing perl_call_pv...\n");
#endif
				PUTBACK;
        		count = perl_call_pv(Name, G_EVAL|G_ARRAY);
        		SPAGAIN;
         		if(!ProcessEventError(NOTXSCALL Name, &PerlResult)) {
            		if(count > 0) PerlResult = POPi;
        		}
        		PUTBACK;
        		FREETMPS;
        		LEAVE;
				/*
				storing = newSViv((long) hwnd);
 				hv_store(self, "-handle", 7, storing, 0);
 				if(SvMAGICAL(self)) mg_set(storing);
 				*/
    		}
    	}
    	return PerlResult;
    } else {
        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }
}


    /*
    ###########################################################################
    # (@)INTERNAL:InteractiveGraphicMsgLoop(hwnd, uMsg, wParam, lParam)
    # message loop for Win32::GUI::Graphic objects (with -interactive => 1
    # option).
    */
LRESULT CALLBACK InteractiveGraphicMsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
#ifdef PERL_OBJECT
    CPerl *pPerl;
    PerlData *pData;
    if(uMsg == WM_CREATE || uMsg == WM_NCCREATE) {
        pData = (PerlData *) ((CREATESTRUCT *) lParam)->lpCreateParams;
        if(pData != NULL) {
            pPerl = pData->pPerl;
            SetWindowLong(hwnd, GWL_USERDATA, (long) pData);
        }
        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    } else {
        pPerl = PERL_OBJECT_FROM_WINDOW(hwnd);
    }
#endif
    int PerlResult;
    int count;
    char Name[MAX_EVENT_NAME];
	HV* self;
	SV* storing;
	SV* newdc;
	SV* newgraphic;
	HV* graphicclass;

    PerlResult = 1;

#ifdef PERLWIN32GUI_STRONGDEBUG
	    printf("!XS(InteractiveGraphicMsgLoop) got (%ld, 0x%x, %ld, %ld)\n", hwnd, uMsg, wParam, lParam);
#endif

	strcpy((char *) Name, "main::");

	if(GetObjectName(NOTXSCALL hwnd, Name)) {
		switch(uMsg) {
		case WM_PAINT:
			strcat((char *) Name, "_Paint");
    		if(perl_get_cv(Name, FALSE) != NULL) {
                /*
                 * (@)EVENT:Paint()
                 * Sent when the Graphic object needs to be repainted.
                 * Note that you need to use GetDC() to get the DC
                 * of the Graphic object where you do your paint
                 * work, and then Validate() the DC to inform Windows
                 * that you painted the DC area (otherwise it will
                 * continue to call the Paint event continuously).
                 * Example:
                 *   sub Graphic_Paint {
                 *       my $DC = $Window->Graphic->GetDC();
                 *       $DC->MoveTo(0, 0);
                 *       $DC->LineTo(100, 100);
                 *       $DC->Validate();
                 *   }
                 * (@)APPLIES_TO:Graphic
                 */
        		dSP;
        		dTARG;
        		ENTER;
        		SAVETMPS;
        		PUSHMARK(SP);
				XPUSHs(sv_2mortal(newSVpv("Win32::GUI::DC", 0)));
				XPUSHs(SV_SELF_FROM_WINDOW(hwnd));
        		PUTBACK ;
				count = perl_call_pv("Win32::GUI::DC::new", 0);
        		SPAGAIN ;
				newdc = newSVsv(POPs);
				PUTBACK;
				FREETMPS;
				LEAVE;

				ENTER;
				SAVETMPS;
	       		PUSHMARK(SP);
				XPUSHs(sv_2mortal(newdc));
				PUTBACK;
        		count = perl_call_pv(Name, G_EVAL|G_ARRAY);
        		SPAGAIN;
         		if(!ProcessEventError(NOTXSCALL Name, &PerlResult)) {
            		if(count > 0) PerlResult = POPi;
        		}
        		PUTBACK;
        		FREETMPS;
        		LEAVE;
			}
			break;
		case WM_MOUSEMOVE:
            PerlResult = DoEvent_MouseMove(NOTXSCALL Name, wParam, lParam);
            break;
        case WM_LBUTTONDOWN:
            strcat((char *) Name, "_LButtonDown");
            PerlResult = DoEvent_MouseButton(NOTXSCALL Name, wParam, lParam);
            break;
        case WM_LBUTTONUP:
            strcat((char *) Name, "_LButtonUp");
            PerlResult = DoEvent_MouseButton(NOTXSCALL Name, wParam, lParam);
            break;
        case WM_RBUTTONDOWN:
            strcat((char *) Name, "_RButtonDown");
            PerlResult = DoEvent_MouseButton(NOTXSCALL Name, wParam, lParam);
            break;
        case WM_RBUTTONUP:
            strcat((char *) Name, "_RButtonUp");
            PerlResult = DoEvent_MouseButton(NOTXSCALL Name, wParam, lParam);
            break;
		}
	}
    if(PerlResult == -1) {
        PostMessage(hwnd, WM_EXITLOOP, -1, 0);
        return 0;
    } else {
        if(PerlResult == 0) {
            return 0;
        } else {
            return DefWindowProc(hwnd, uMsg, wParam, lParam);
        }
    }
}


    /*
    ###########################################################################
    # (@)INTERNAL:WindowMsgLoop(hwnd, uMsg, wParam, lParam)
    # this is the main message loop (WndProc)
    */
LRESULT CALLBACK WindowMsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam)
{
	dSP;
    int PerlResult;
    char Name[MAX_EVENT_NAME];
    int obj_class;
    LPNMHDR notify;
    LPNM_TREEVIEW tv_notify;
    TV_KEYDOWN FAR * tv_keydown;
	LPPERLWIN32GUI_USERDATA perlud;

#ifdef PERLWIN32GUI_STRONGDEBUG
	    printf("!XS(WindowMsgLoop) got (%ld, 0x%x, %ld, %ld)\n", hwnd, uMsg, wParam, lParam);
#endif

    if(uMsg == WM_CREATE || uMsg == WM_NCCREATE) {
        perlud = (LPPERLWIN32GUI_USERDATA) ((CREATESTRUCT *) lParam)->lpCreateParams;
        if(perlud!= NULL) {
            SetWindowLong(hwnd, GWL_USERDATA, (long) perlud);
        }
        return DefWindowProc(hwnd, uMsg, wParam, lParam);
    }

    if(uMsg == WM_DESTROY) {
		safefree( (LPPERLWIN32GUI_USERDATA) GetWindowLong(hwnd, GWL_USERDATA));
		return DefWindowProc(hwnd, uMsg, wParam, lParam);
	}
#ifdef PERL_OBJECT
	pPerl = ((LPPERLWIN32GUI_USERDATA) GetWindowLong(hwnd, GWL_USERDATA))->pPerl;
#endif

	ENTER;
	SAVETMPS;

    PerlResult = 1;
    strcpy(Name, "main::");

    switch(uMsg) {
    case WM_ACTIVATE:
        if(GetObjectName(NOTXSCALL hwnd, Name)) {
            if(LOWORD(wParam) == WA_INACTIVE) {
                /*
                 * (@)EVENT:Deactivate()
                 * Sent when the window is deactivated.
                 * (@)APPLIES_TO:Window, DialogBox
                 */
                strcat(Name, "_Deactivate");
            } else {
                /*
                 * (@)EVENT:Activate()
                 * Sent when the window is activated.
                 * (@)APPLIES_TO:Window, DialogBox
                 */
                strcat(Name, "_Activate");
            }
            PerlResult = DoEvent_Generic(NOTXSCALL Name);
        }
        break;

    case WM_SYSCOMMAND:
        if(GetObjectName(NOTXSCALL hwnd, Name)) {
            switch(wParam & 0xFFF0) {
            case SC_CLOSE:
                /*
                 * (@)EVENT:Terminate()
                 * Sent when the window is closed.
                 * The event should return -1 to terminate the interaction
                 * and return control to the perl script; see Dialog().
                 * (@)APPLIES_TO:Window, DialogBox
                 */
                strcat(Name, "_Terminate");
                PerlResult = DoEvent_Generic(NOTXSCALL Name);
                break;
            case SC_MINIMIZE:
                /*
                 * (@)EVENT:Minimize()
                 * Sent when the window is minimized.
                 * (@)APPLIES_TO:Window, DialogBox
                 */
                strcat(Name, "_Minimize");
                PerlResult = DoEvent_Generic(NOTXSCALL Name);
                break;
            case SC_MAXIMIZE:
                /*
                 * (@)EVENT:Maximize()
                 * Sent when the window is maximized.
                 * (@)APPLIES_TO:Window, DialogBox
                 */
                strcat(Name, "_Maximize");
                PerlResult = DoEvent_Generic(NOTXSCALL Name);
                break;
            }
        }
        break;

    case WM_SIZE:
        if(GetObjectName(NOTXSCALL hwnd, Name)) {
            /*
             * (@)EVENT:Resize()
             * Sent when the window is resized.
             * (@)APPLIES_TO:Window, DialogBox
             */
            strcat(Name, "_Resize");
            PerlResult = DoEvent_Generic(NOTXSCALL Name);
        }
        break;

    case WM_COMMAND:
        if(HIWORD(wParam) == 0 && lParam == NULL) {
            // menu command processing
#ifdef PERLWIN32GUI_STRONGDEBUG
				printf("!XS(WindowMsgLoop) got WM_COMMAND for a menu...\n");
#endif
            if(GetMenuName(NOTXSCALL LOWORD(wParam), Name)) {
                /*
                 * (@)EVENT:Click()
				 * Sent when the users choose a menu point.
                 * (@)APPLIES_TO:Menu
                 */
                strcat(Name, "_Click");
                PerlResult = DoEvent_Generic(NOTXSCALL Name);
            }
        } else if(HIWORD(wParam) == 1 && lParam == NULL) {
            // accelerator processing
#ifdef PERLWIN32GUI_STRONGDEBUG
				printf("!XS(WindowMsgLoop) got WM_COMMAND for an accelerator...\n");
#endif
            if(GetAcceleratorName(NOTXSCALL LOWORD(wParam), Name)) {
                /*
                 * (@)EVENT:Click()
				 * Sent when the users triggers an Accelerator object.
                 * (@)APPLIES_TO:AcceleratorTable
                 */
                strcat(Name, "_Click");
                PerlResult = DoEvent_Generic(NOTXSCALL Name);
            }
        } else {
#ifdef PERLWIN32GUI_STRONGDEBUG
				printf("!XS(WindowMsgLoop) got WM_COMMAND, doing GetObjectNameAndClass...\n");
#endif
            if(GetObjectNameAndClass(NOTXSCALL (HWND) lParam, Name, &obj_class)) {
#ifdef PERLWIN32GUI_STRONGDEBUG
					printf("!XS(WindowMsgLoop) GetObjectNameAndClass succeeded (Name=%s, class=%d)...\n", Name, obj_class);
#endif
                switch(obj_class) {

                case WIN32__GUI__BUTTON:
                case WIN32__GUI__CHECKBOX:
                case WIN32__GUI__RADIOBUTTON:
                    switch(HIWORD(wParam)) {
                    case BN_SETFOCUS:
                        /*
                         * (@)EVENT:GotFocus()
						 * Sent when the control is activated.
                         * (@)APPLIES_TO:Button, Checkbox, RadioButton
                         */
                        strcat((char *) Name, "_GotFocus");
                        PerlResult = DoEvent_Generic(NOTXSCALL Name);
                        break;
                    case BN_KILLFOCUS:
                        /*
                         * (@)EVENT:LostFocus()
						 * Sent when the control is deactivated.
                         * (@)APPLIES_TO:Button, Checkbox, RadioButton
                         */
                        strcat((char *) Name, "_LostFocus");
                        PerlResult = DoEvent_Generic(NOTXSCALL Name);
                        break;
                    case BN_CLICKED:
                        /*
                         * (@)EVENT:Click()
						 * Sent when the control is selected (eg.
						 * the button pushed, the checkbox checked, etc.).
                         * (@)APPLIES_TO:Button, Checkbox, RadioButton
                         */
                        strcat((char *) Name, "_Click");
                        PerlResult = DoEvent_Generic(NOTXSCALL Name);
                        break;
                    case BN_DBLCLK:
                        /*
                         * (@)EVENT:DblClick()
						 * Sent when the user double clicks on the control.
                         * (@)APPLIES_TO:Button, Checkbox, RadioButton
                         */
                        strcat((char *) Name, "_DblClick");
                        PerlResult = DoEvent_Generic(NOTXSCALL Name);
                        break;
			  		case BN_PUSHED:
                        /*
                         * (@)EVENT:MouseDown()
                         * Sent when the user down clicks on the control.
                         * (@)APPLIES_TO:Button, Checkbox, RadioButton
                         */
						strcat((char *) Name, "_MouseDown");
						PerlResult = DoEvent_Generic(NOTXSCALL Name);
						break;
					case BN_UNPUSHED:
                        /*
                         * (@)EVENT:MouseUp()
                         * Sent when the user releases a down click on the control.
                         * (@)APPLIES_TO:Button, Checkbox, RadioButton
                         */
						strcat((char *) Name, "_MouseUp");
						PerlResult = DoEvent_Generic(NOTXSCALL Name);
						break;
                    default:
                        strcat((char *) Name, "_Anonymous");
#ifdef PERLWIN32GUI_STRONGDEBUG
	                        printf("!XS(WindowMsgLoop): BUTTON WM_COMMAND NotifyCode=%d\n", HIWORD(wParam));
#endif
                        PerlResult = DoEvent_Generic(NOTXSCALL Name);
                        break;
		    }
                    break;

                case WIN32__GUI__LISTBOX:
                    switch(HIWORD(wParam)) {
                    case LBN_SETFOCUS:
                        /*
                         * (@)EVENT:GotFocus()
						 * Sent when the control is activated.
                         * (@)APPLIES_TO:Listbox
                         */
                        strcat((char *) Name, "_GotFocus");
                        PerlResult = DoEvent_Generic(NOTXSCALL Name);
                        break;
                    case LBN_KILLFOCUS:
                        /*
                         * (@)EVENT:LostFocus()
						 * Sent when the control is deactivated.
						 * (@)APPLIES_TO:Listbox
                         */
                        strcat((char *) Name, "_LostFocus");
                        PerlResult = DoEvent_Generic(NOTXSCALL Name);
                        break;
                    case LBN_SELCHANGE:
                        /*
                         * (@)EVENT:Click()
                         * (@)APPLIES_TO:Listbox
                         */
                        strcat((char *) Name, "_Click");
                        PerlResult = DoEvent_Generic(NOTXSCALL Name);
                        break;
                    case LBN_DBLCLK:
                        /*
                         * (@)EVENT:DblClick()
						 * Sent when the user double clicks on the control.
						 * (@)APPLIES_TO:Listbox
                         */
                        strcat((char *) Name, "_DblClick");
                        PerlResult = DoEvent_Generic(NOTXSCALL Name);
                        break;
                    default:
                        strcat((char *) Name, "_Anonymous");
#ifdef PERLWIN32GUI_STRONGDEBUG
	                        printf("!XS(WindowMsgLoop): LISTBOX WM_COMMAND NotifyCode=%d\n", HIWORD(wParam));
#endif
                        PerlResult = DoEvent_Generic(NOTXSCALL Name);
                        break;
                    }
                    break;

                case WIN32__GUI__EDIT:
                case WIN32__GUI__RICHEDIT:
                    switch(HIWORD(wParam)) {
                    case EN_SETFOCUS:
                        /*
                         * (@)EVENT:GotFocus()
                         * Sent when the control is activated.
                         * (@)APPLIES_TO:Textfield, RichEdit
                         */
                        strcat((char *) Name, "_GotFocus");
                        PerlResult = DoEvent_Generic(NOTXSCALL Name);
                        break;
                    case EN_KILLFOCUS:
                        /*
                         * (@)EVENT:LostFocus()
                         * Sent when the control is deactivated.
                         * (@)APPLIES_TO:Textfield, RichEdit
                         */
                        strcat((char *) Name, "_LostFocus");
                        PerlResult = DoEvent_Generic(NOTXSCALL Name);
                        break;
                    case EN_CHANGE:
                        /*
                         * (@)EVENT:Change()
                         * Sent when the text in the field is changed by the user.
                         * (@)APPLIES_TO:Textfield, RichEdit
                         */
                        strcat((char *) Name, "_Change");
                        PerlResult = DoEvent_Generic(NOTXSCALL Name);
                        break;
                    default:
                        strcat((char *) Name, "_Anonymous");
#ifdef PERLWIN32GUI_STRONGDEBUG
	                        printf("!XS(WindowMsgLoop): EDIT WM_COMMAND NotifyCode=%d\n", HIWORD(wParam));
#endif
                        PerlResult = DoEvent_Generic(NOTXSCALL Name);
                        break;
                    }
                    break;

                case WIN32__GUI__STATIC:
                    switch(HIWORD(wParam)) {
                    case STN_CLICKED:
                        /*
                         * (@)EVENT:Click()
                         * (@)APPLIES_TO:Label
                         */
                        strcat((char *) Name, "_Click");
                        PerlResult = DoEvent_Generic(NOTXSCALL Name);
                        break;
                    case STN_DBLCLK:
                        /*
                         * (@)EVENT:DblClick()
                         * (@)APPLIES_TO:Label
                         */
                        strcat((char *) Name, "_DblClick");
                        PerlResult = DoEvent_Generic(NOTXSCALL Name);
                        break;
                    default:
                        strcat((char *) Name, "_Anonymous");
#ifdef PERLWIN32GUI_STRONGDEBUG
	                        printf("!XS(WindowMsgLoop): STATIC WM_COMMAND NotifyCode=%d\n", HIWORD(wParam));
#endif
                        PerlResult = DoEvent_Generic(NOTXSCALL Name);
                        break;
                    }
                    break;

                case WIN32__GUI__COMBOBOX:
                case WIN32__GUI__COMBOBOXEX:
                    switch(HIWORD(wParam)) {
                    case CBN_SETFOCUS:
                        /*
                         * (@)EVENT:GotFocus()
						 * Sent when the control is activated.
                         * (@)APPLIES_TO:Combobox, ComboboxEx
                         */
                        strcat((char *) Name, "_GotFocus");
                        PerlResult = DoEvent_Generic(NOTXSCALL Name);
                        break;
                    case CBN_KILLFOCUS:
                        /*
                         * (@)EVENT:LostFocus()
						 * Sent when the control is deactivated.
						 * (@)APPLIES_TO:Combobox, ComboboxEx
                         */
                        strcat((char *) Name, "_LostFocus");
                        PerlResult = DoEvent_Generic(NOTXSCALL Name);
                        break;
					case CBN_SELCHANGE:
                        /*
                         * (@)EVENT:Change()
                         * Sent when the user selects an item from the Combobox
                         * (@)APPLIES_TO:Combobox, ComboboxEx
                         */
                        strcat((char *) Name, "_Change");
                        PerlResult = DoEvent_Generic(NOTXSCALL Name);
                        break;
                    default:
                        strcat((char *) Name, "_Anonymous");
#ifdef PERLWIN32GUI_STRONGDEBUG
	                        printf("!XS(WindowMsgLoop): COMBOBOX WM_COMMAND NotifyCode=%d\n", HIWORD(wParam));
#endif
#ifdef PERLWIN32GUI_STRONGDEBUG
	                        printf("!XS(WindowMsgLoop): COMBOBOX WM_COMMAND hWnd=%ld\n", lParam);
#endif
                        PerlResult = DoEvent_Long(NOTXSCALL Name, HIWORD(wParam));
                        break;
                    }
                    break;

                case WIN32__GUI__TOOLBAR:
                    /*
                     * (@)EVENT:ButtonClick(INDEX)
                     * Sent when the user presses a button of the Toolbar
                     * the INDEX argument identifies the zero-based index of
                     * the pressed button
                     * (@)APPLIES_TO:Toolbar
                     */
                    strcat((char *) Name, "_ButtonClick");
                    PerlResult = DoEvent_Long(NOTXSCALL Name, LOWORD(wParam));
                    break;

                }
            }
        }
        break;


    case WM_NOTIFY:
        notify = (LPNMHDR) lParam;
        if(GetObjectNameAndClass(NOTXSCALL notify->hwndFrom, Name, &obj_class)) {
            switch(obj_class) {

            case WIN32__GUI__TOOLBAR:
                {
                    LPTBNOTIFY tbn;
                    tbn = (LPTBNOTIFY) lParam;
#ifdef PERLWIN32GUI_STRONGDEBUG
	                printf("!XS(WindowMsgLoop): TOOLBAR WM_NOTIFY Code=%ud\n", tbn->hdr.code);
#endif
                }
                break;

            case WIN32__GUI__LISTVIEW:
                {
                    LPNM_LISTVIEW lv_notify;
                    lv_notify = (LPNM_LISTVIEW) lParam;
                    switch(notify->code) {
                    case LVN_ITEMCHANGED:
                        if(lv_notify->uChanged & LVIF_STATE
                        && lv_notify->uNewState & LVIS_SELECTED) {
                            /*
                             * (@)EVENT:ItemClick(ITEM)
                             * Sent when the user selects an item in the ListView;
                             * ITEM specifies the zero-based index of the selected item.
                             * (@)APPLIES_TO:ListView
                             */
                            strcat((char *) Name, "_ItemClick");
                            PerlResult = DoEvent_Long(NOTXSCALL Name, lv_notify->iItem);
                        }
                        break;
                    case LVN_COLUMNCLICK:
                        /*
                         * (@)EVENT:ColumnClick(ITEM)
                         * Sent when the user clicks on a column header in the
                         * ListView; ITEM specifies the one-based index of the
                         * selected column.
                         * (@)APPLIES_TO:ListView
                         */
                        strcat((char *) Name, "_ColumnClick");
                        PerlResult = DoEvent_Long(NOTXSCALL Name, lv_notify->iSubItem);
                        break;
                    case LVN_KEYDOWN:
                        {
                            LV_KEYDOWN FAR * lv_keydown;
                            lv_keydown = (LV_KEYDOWN FAR *) lParam;
                            /*
                             * (@)EVENT:KeyDown(KEY)
							 * Sent when the user presses a key while the ListView
							 * control has focus; KEY is the ASCII code of the
							 * key being pressed.
                             * (@)APPLIES_TO:ListView
                             */
                            strcat((char *) Name, "_KeyDown");
                            PerlResult = DoEvent_Long(NOTXSCALL Name, lv_keydown->wVKey);
                        }
                        break;
                    }
                }
                break;

            case WIN32__GUI__TREEVIEW:
                tv_notify = (LPNM_TREEVIEW) lParam;
                switch(notify->code) {
                case TVN_ITEMEXPANDED:
                    if(tv_notify->action == TVE_COLLAPSE)
                        /*
                         * (@)EVENT:Collapse(NODE)
                         * Sent when the user closes the specified NODE of the TreeView.
                         * (@)APPLIES_TO:TreeView
                         */
                        strcat(Name, "_Collapse");
                    else
                        /*
                         * (@)EVENT:Expand(NODE)
                         * Sent when the user opens the specified NODE of the TreeView.
                         * (@)APPLIES_TO:TreeView
                         */
                        strcat(Name, "_Expand");
                    PerlResult = DoEvent_Long(NOTXSCALL Name, (long) tv_notify->itemNew.hItem);
                    break;

                case TVN_ITEMEXPANDING:
                    if(tv_notify->action == TVE_COLLAPSE)
                        /*
                         * (@)EVENT:Collapsing(NODE)
                         * Sent when the user is about to close the
                         * specified NODE of the TreeView.
                         * The event should return 0 to prevent the
                         * action, 1 to allow it.
                         * (@)APPLIES_TO:TreeView
                         */
                        strcat(Name, "_Collapsing");
                    else
                        /*
                         * (@)EVENT:Expanding(NODE)
                         * Sent when the user is about to open the
                         * specified NODE of the TreeView
                         * The event should return 0 to prevent the
                         * action, 1 to allow it.
                         * (@)APPLIES_TO:TreeView
                         */
                        strcat(Name, "_Expanding");
                    PerlResult = DoEvent_Long(NOTXSCALL Name, (long) tv_notify->itemNew.hItem);
                    FREETMPS;
                    LEAVE;
                    if(PerlResult == 0) return TRUE;
                    else                return FALSE;
                    break;

                case TVN_SELCHANGED:
                    /*
                     * (@)EVENT:NodeClick(NODE)
                     * Sent when the user clicks on the specified NODE of the TreeView.
                     * (@)APPLIES_TO:TreeView
                     */
                    strcat(Name, "_NodeClick");
                    PerlResult = DoEvent_Long(NOTXSCALL Name, (long) tv_notify->itemNew.hItem);
                    break;

                case TVN_KEYDOWN:
                    /*
                     * (@)EVENT:KeyDown(KEY)
					 * Sent when the user presses a key while the TreeView
					 * control has focus; KEY is the ASCII code of the
					 * key being pressed.
					 * (@)APPLIES_TO:TreeView
                     */
                    tv_keydown = (TV_KEYDOWN FAR *) lParam;
                    strcat((char *) Name, "_KeyDown");
                    PerlResult = DoEvent_Long(NOTXSCALL Name, tv_keydown->wVKey);
                    break;
                }
                break;

            case WIN32__GUI__TAB:
                switch(notify->code) {
                case TCN_SELCHANGING:
                    /*
                     * (@)EVENT:Changing()
                     * Sent before the current selection changes.
					 * Use SelectedItem() to determine the
					 * current selection.
                     * The event should return 0 to prevent
                     * the selection changing, 1 to allow it.
                     * (@)APPLIES_TO:TabStrip
                     */
                    strcat((char *) Name, "_Changing");
                    PerlResult = DoEvent_Generic(NOTXSCALL Name);
                    FREETMPS;
                    LEAVE;
                    if(PerlResult == 0) return TRUE;
                    else                return FALSE;
                    break;
                case TCN_SELCHANGE:
                    /*
                     * (@)EVENT:Change()
                     * Sent when the current
                     * selection has changed. Use SelectedItem()
                     * to determine the current selection.
                     * (@)APPLIES_TO:TabStrip
				 	 */
                    strcat((char *) Name, "_Change");
                    PerlResult = DoEvent_Generic(NOTXSCALL Name);
                    break;
                }
                break;

            case WIN32__GUI__TOOLTIP:
                if(((LPNMHDR)lParam)->code == TTN_NEEDTEXT) {
                    /*
                     * (@)EVENT:NeedText(ID)
                     * (@)APPLIES_TO:Tooltip
                     */
                    LPTOOLTIPTEXT lptt;
                    lptt = (LPTOOLTIPTEXT) lParam;
                    lptt->lpszText = (LPTSTR) DoEvent_NeedText(NOTXSCALL Name, lptt->hdr.idFrom);
#ifdef PERLWIN32GUI_STRONGDEBUG
	                    printf("!XS(WindowMsgLoop): TTN_NEEDTEXT got '%s'\n", lptt->lpszText);
#endif
                    PerlResult = 1;

                }
                break;

            case WIN32__GUI__REBAR:
                if(((LPNMHDR)lParam)->code == RBN_HEIGHTCHANGE) {
                    /*
                     * (@)EVENT:HeightChange()
                     * Sent when the height of the Rebar control has changed.
                     * (@)APPLIES_TO:Rebar
                     */
                    strcat((char *) Name, "_HeightChange");
                    PerlResult = DoEvent_Generic(NOTXSCALL Name);
                }
                break;

            case WIN32__GUI__HEADER:
                if(((LPNMHDR)lParam)->code == HDN_BEGINTRACK) {
                    /*
                     * (@)EVENT:BeginTrack(INDEX, WIDTH)
                     * Sent when a divider of the Header control
                     * is being moved; the event must return 0 to
                     * prevent moving the divider, 1 to allow it.
                     * Passes the zero-based INDEX
                     * of the item being resized and its current
                     * WIDTH.
                     * (@)APPLIES_TO:Header
                     */
                    LPNMHEADER nmh;
                    nmh = (LPNMHEADER) lParam;
                    strcat((char *) Name, "_BeginTrack");
                    PerlResult = DoEvent_TwoLongs(
                        NOTXSCALL Name,
                        nmh->iItem,
                        nmh->pitem->cxy
                    );
                    FREETMPS;
                    LEAVE;
                    if(PerlResult == 0) return TRUE;
                    else                return FALSE;
                } else if(((LPNMHDR)lParam)->code == HDN_ENDTRACK) {
                    /*
                     * (@)EVENT:EndTrack(INDEX, WIDTH)
                     * Sent when a divider of the Header control
                     * has been moved. Passes the zero-based INDEX
                     * of the item being resized and its current
                     * WIDTH.
                     * (@)APPLIES_TO:Header
                     */
                    LPNMHEADER nmh;
                    nmh = (LPNMHEADER) lParam;
                    strcat((char *) Name, "_EndTrack");
                    PerlResult = DoEvent_TwoLongs(
                        NOTXSCALL Name,
                        nmh->iItem,
                        nmh->pitem->cxy
                    );
                } else if(((LPNMHDR)lParam)->code == HDN_TRACK) {
                    /*
                     * (@)EVENT:Track(INDEX, WIDTH)
                     * Sent while a divider of the Header control
                     * is being moved; the event must return 1 to
                     * continue moving the divider, 0 to end its
                     * movement.
                     * Passes the zero-based INDEX
                     * of the item being resized and its current
                     * WIDTH.
                     * (@)APPLIES_TO:Header
                     */
                    LPNMHEADER nmh;
                    nmh = (LPNMHEADER) lParam;
                    strcat((char *) Name, "_Track");
                    PerlResult = DoEvent_TwoLongs(
                        NOTXSCALL Name,
                        nmh->iItem,
                        nmh->pitem->cxy
                    );
                    FREETMPS;
                    LEAVE;
                    if(PerlResult == 0) return TRUE;
                    else                return FALSE;
                } else if(((LPNMHDR)lParam)->code == HDN_DIVIDERDBLCLICK) {
                    /*
                     * (@)EVENT:DividerDblClick(INDEX)
                     * Sent when the user double-clicked on a
                     * divider of the Header control.
                     * (@)APPLIES_TO:Header
                     */
                    LPNMHEADER nmh;
                    nmh = (LPNMHEADER) lParam;
                    strcat((char *) Name, "_DividerDblClick");
                    PerlResult = DoEvent_Long(NOTXSCALL Name, nmh->iItem);
                } else if(((LPNMHDR)lParam)->code == HDN_ITEMCLICK) {
                    /*
                     * (@)EVENT:ItemClick(INDEX)
                     * Sent when the user clicked on a Header
                     * item.
                     * (@)APPLIES_TO:Header
                     */
                    LPNMHEADER nmh;
                    nmh = (LPNMHEADER) lParam;
                    strcat((char *) Name, "_ItemClick");
                    PerlResult = DoEvent_Long(NOTXSCALL Name, nmh->iItem);
                } else if(((LPNMHDR)lParam)->code == HDN_ITEMDBLCLICK) {
                    /*
                     * (@)EVENT:ItemDblClick(INDEX)
                     * Sent when the user double-clicked on a Header
                     * item.
                     * (@)APPLIES_TO:Header
                     */
                    LPNMHEADER nmh;
                    nmh = (LPNMHEADER) lParam;
                    strcat((char *) Name, "_ItemDblClick");
                    PerlResult = DoEvent_Long(NOTXSCALL Name, nmh->iItem);
                }
                break;

            }
            /*
             * ###############################################
             * standard notifications (true for all controls?)
             * ###############################################
             */
            switch(notify->code) {
            case NM_CLICK:
                /*
                 * (@)EVENT:Click()
                 * (@)APPLIES_TO:*
                 */
                strcat((char *) Name, "_Click");
                PerlResult = DoEvent_Generic(NOTXSCALL Name);
                break;
            case NM_RCLICK:
                /*
                 * (@)EVENT:RightClick()
                 * (@)APPLIES_TO:*
                 */
                strcat((char *) Name, "_RightClick");
                PerlResult = DoEvent_Generic(NOTXSCALL Name);
                break;
            case NM_DBLCLK:
                /*
                 * (@)EVENT:DblClick()
                 * (@)APPLIES_TO:*
                 */
                strcat((char *) Name, "_DblClick");
                PerlResult = DoEvent_Generic(NOTXSCALL Name);
                break;
            case NM_RDBLCLK:
                /*
                 * (@)EVENT:DblRightClick()
                 * (@)APPLIES_TO:*
                 */
                strcat((char *) Name, "_DblRightClick");
                PerlResult = DoEvent_Generic(NOTXSCALL Name);
                break;
            case NM_SETFOCUS:
                /*
                 * (@)EVENT:GotFocus()
                 * (@)APPLIES_TO:*
                 */
                strcat((char *) Name, "_GotFocus");
                PerlResult = DoEvent_Generic(NOTXSCALL Name);
                break;
            case NM_KILLFOCUS:
                /*
                 * (@)EVENT:LostFocus()
                 * (@)APPLIES_TO:*
                 */
                strcat((char *) Name, "_LostFocus");
                PerlResult = DoEvent_Generic(NOTXSCALL Name);
                break;
            }
        }
        break;

    case WM_TIMER:
        /* (@)EVENT:Timer() */
        if(GetTimerName(NOTXSCALL hwnd, wParam, Name)) {
            strcat((char *) Name, "_Timer");
            PerlResult = DoEvent_Generic(NOTXSCALL Name);
        } else {
            PerlResult = 0;
        }
        break;

    case WM_HSCROLL:
    case WM_VSCROLL:
        if(GetObjectNameAndClass(NOTXSCALL (HWND) lParam, Name, &obj_class)) {
            switch(obj_class) {
            case WIN32__GUI__TRACKBAR:
                /*
                 * (@)EVENT:Scroll()
                 * Sent when the user moves the slider handle.
                 * (@)APPLIES_TO:Slider
                 */
                strcat((char *) Name, "_Scroll");
                PerlResult = DoEvent_Generic(NOTXSCALL Name);
                break;
            case WIN32__GUI__UPDOWN:
                /*
                 * (@)EVENT:Scroll()
                 * Sent when the user presses either the up or down button
                 * of the UpDown control.
                 * (@)APPLIES_TO:UpDown
                 */
                strcat((char *) Name, "_Scroll");
                PerlResult = DoEvent_Generic(NOTXSCALL Name);
                break;
            }
        }
        break;

    case WM_MOUSEMOVE:
    case WM_LBUTTONDOWN:
    case WM_LBUTTONUP:
    case WM_RBUTTONDOWN:
    case WM_RBUTTONUP:
        {
            HV* self;
            SV** rtts;
            AV* tts;
            I32 ttsi;
            SV** rtt;
            HWND tt;
            MSG ttmsg;
            self = HV_SELF_FROM_WINDOW(hwnd);
            if(self != NULL) {
                rtts = hv_fetch(self, "-tooltips", 9, FALSE);
                if(SvMAGICAL(self)) mg_get(*rtts);
                if(rtts != NULL && SvOK(*rtts)) {
                	if(SvROK(*rtts) && SvTYPE(SvRV(*rtts)) == SVt_PVAV) {
	                    tts = (AV*) SvRV(*rtts);
#ifdef PERLWIN32GUI_STRONGDEBUG
		                printf("!XS(WindowMsgLoop): found -tooltips (%d)...\n", av_len(tts));
#endif
	                    for(ttsi=0;ttsi<av_len(tts);ttsi++) {
                        	rtt = av_fetch(tts, ttsi, 0);
                        	if(rtt != NULL) {
	                            tt = (HWND) SvIV(*rtt);
#ifdef PERLWIN32GUI_STRONGDEBUG
		                        printf("!XS(WindowMsgLoop): relaying to tooltip %ld...\n", tt);
#endif
	                            ttmsg.hwnd = hwnd;
                            	ttmsg.lParam = lParam;
                            	ttmsg.wParam = wParam;
                            	ttmsg.message = uMsg;
                            	SendMessage(tt, TTM_RELAYEVENT, 0, (LPARAM) &ttmsg);
                        	}
                        }
                    }
                }
            }
        }
        break;


    case WM_CTLCOLOREDIT:
    case WM_CTLCOLORSTATIC:
    case WM_CTLCOLORBTN:
    case WM_CTLCOLORLISTBOX:
        {
			LPPERLWIN32GUI_USERDATA perlud;

            if(uMsg == WM_CTLCOLORSTATIC
            && GetWindowLong((HWND) lParam, GWL_STYLE) & SS_SIMPLE) {
				FREETMPS;
				LEAVE;
                return FALSE;
            }

			perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLong((HWND) lParam, GWL_USERDATA);
			if(perlud == NULL || perlud->dwSize != sizeof(PERLWIN32GUI_USERDATA)) {
				HBRUSH defBrush;
				switch(uMsg) {
				case WM_CTLCOLOREDIT:
				case WM_CTLCOLORLISTBOX:
					defBrush = GetSysColorBrush(COLOR_WINDOW);
					break;
				default:
					defBrush = GetSysColorBrush(COLOR_BTNFACE);
					break;
				}
				FREETMPS;
				LEAVE;
				return ((LRESULT) defBrush);
			}

			if(uMsg == WM_CTLCOLORSTATIC) SetBkMode((HDC) wParam, TRANSPARENT);
			if(perlud->clrForeground != CLR_INVALID) {
				SetTextColor((HDC) wParam, perlud->clrForeground);
			}
			if(perlud->clrBackground != CLR_INVALID) {
				SetBkColor((HDC) wParam, perlud->clrBackground);
				FREETMPS;
				LEAVE;
				return ((LRESULT) perlud->hBackgroundBrush);
			} else {
				HBRUSH defBrush;
				switch(uMsg) {
				case WM_CTLCOLOREDIT:
				case WM_CTLCOLORLISTBOX:
					defBrush = GetSysColorBrush(COLOR_WINDOW);
					break;
				default:
					defBrush = GetSysColorBrush(COLOR_BTNFACE);
					break;
				}
				FREETMPS;
				LEAVE;
				return ((LRESULT) defBrush);
			}
        }
        break;


    case WM_NOTIFYICON:
        if(GetNotifyIconName(NOTXSCALL hwnd, (UINT) wParam, Name)) {
            switch(lParam) {
            case WM_LBUTTONDOWN:
                /*
                 * (@)EVENT:Click()
                 * Sent when the user clicks the left mouse button on
                 * a NotifyIcon.
                 * (@)APPLIES_TO:NotifyIcon
                 */
                strcat(Name, "_Click");
                PerlResult = DoEvent_Generic(NOTXSCALL Name);
                break;
            case WM_RBUTTONDOWN:
                /*
                 * (@)EVENT:RightClick()
                 * Sent when the user clicks the right mouse button on
                 * a NotifyIcon.
                 * (@)APPLIES_TO:NotifyIcon
                 */
                strcat(Name, "_RightClick");
                PerlResult = DoEvent_Generic(NOTXSCALL Name);
                break;
            default:
                /*
                 * (@)EVENT:MouseEvent(MSG)
                 * Sent when the user performs a mouse event on
                 * a NotifyIcon; MSG is the message code.
                 * (@)APPLIES_TO:NotifyIcon
                 */
                strcat(Name, "_MouseEvent");
                PerlResult = DoEvent_Long(NOTXSCALL Name, (long)lParam);
                break;
            }
        }
        break;

    case WM_GETMINMAXINFO:
        {
            LPMINMAXINFO minmax;
            LPPERLWIN32GUI_USERDATA perlud;
            perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLong(hwnd, GWL_USERDATA);
#ifdef PERLWIN32GUI_STRONGDEBUG
	        printf("!XS(WindowMsgLoop): WM_GETMINMAXINFO perlud=%ld\n", perlud);
#endif
            if(NULL != perlud && perlud->dwSize == sizeof(PERLWIN32GUI_USERDATA)) {
	            minmax = (LPMINMAXINFO) lParam;
				if(perlud->iMinWidth != 0) minmax->ptMinTrackSize.x = (LONG) perlud->iMinWidth;
				if(perlud->iMaxWidth != 0) minmax->ptMaxTrackSize.x = (LONG) perlud->iMaxWidth;
				if(perlud->iMinHeight != 0) minmax->ptMinTrackSize.y = (LONG) perlud->iMinHeight;
				if(perlud->iMaxHeight != 0) minmax->ptMaxTrackSize.y = (LONG) perlud->iMaxHeight;
				PerlResult = 1;
			}
		}
        break;
    }
	FREETMPS;
	LEAVE;

    if(PerlResult == -1) {
        PostMessage(hwnd, WM_EXITLOOP, -1, 0);
        return 0;
    } else {
        if(PerlResult == 0) {
            return 0;
        } else {
            return DefWindowProc(hwnd, uMsg, wParam, lParam);
        }
    }
}

    /*
    ###########################################################################
    # (@)INTERNAL:MsgLoop(hwnd, uMsg, wParam, lParam)
    # obsolete (?) Win32::GUI::Window message loop
    */
LRESULT CALLBACK MsgLoop(HWND hwnd, UINT uMsg, WPARAM wParam, LPARAM lParam) {
#ifdef PERL_OBJECT
    CPerl *pPerl = PERL_OBJECT_FROM_WINDOW(hwnd);
#endif
    HV* cb_hash;
    SV** cb_ref;
    int i;
    int *Items;
    int Count;
    int PerlResult = 1;
    char temp[80];
    int send_to = 0;
    // 0 = DefWindowProc
    // 1 = function: perl_call_sv(cb_ref...
    // 2 = function or DefWindowProc

    dSP;
    dTARG;

    ENTER ;
    SAVETMPS;

    PUSHMARK(SP) ;
    EXTEND(SP,4) ;
    PUSHs(sv_2mortal(newSViv((long)hwnd)));
    PUSHs(sv_2mortal(newSViv((long)uMsg)));
    PUSHs(sv_2mortal(newSViv((long)wParam)));
    PUSHs(sv_2mortal(newSViv((long)lParam)));
    PUTBACK ;

    if(uMsg == WM_COMMAND) {

        if(lParam == NULL) {
            // Menu Option
            if(HIWORD(wParam) == 0) {
                cb_hash = perl_get_hv("Win32::GUI::menucallbacks", FALSE);
                ltoa((long) LOWORD(wParam), temp, 10);
                if(hv_exists(cb_hash, temp, strlen(temp))) {
                    cb_ref = hv_fetch(cb_hash, temp, strlen(temp), FALSE);
                    send_to = 1; // cb_ref
                } else {
                    send_to = 2;
                }
            } else {
                send_to = 2; // ...hwnd or Def
            }
        } else {
            cb_hash = perl_get_hv("Win32::GUI::callbacks", FALSE);
            ltoa((long)lParam, temp, 10);
            if(hv_exists(cb_hash, temp, strlen(temp))) {
                cb_ref = hv_fetch(cb_hash, temp, strlen(temp), FALSE);
                send_to = 1; // cb_ref
            } else {
                send_to = 2; // ...hwnd or Def
            }
        }
    } else if(uMsg == WM_NOTIFY) {
        LPNMHDR nmhdr = (LPNMHDR) lParam;
        HWND hwnd = nmhdr->hwndFrom;
        UINT id = nmhdr->idFrom;
        UINT code = nmhdr->code;
        cb_hash = perl_get_hv("Win32::GUI::callbacks", FALSE);
        ltoa((long)hwnd, temp, 10);
        if(hv_exists(cb_hash, temp, strlen(temp))) {
            cb_ref = hv_fetch(cb_hash, temp, strlen(temp), FALSE);
            send_to = 1; // cb_ref
        } else {
            send_to = 2; // ...hwnd or Def
        }
    } else {
        send_to = 2;
    }

    switch(send_to) {
    case 2:
        cb_hash = perl_get_hv("Win32::GUI::callbacks", FALSE);
        ltoa((long)hwnd, temp, 10);
        if(hv_exists(cb_hash, temp, strlen(temp))) {

            cb_ref = hv_fetch(cb_hash, temp, strlen(temp), FALSE);

            perl_call_pv((char *)SvPV_nolen(*cb_ref), G_ARRAY);

            SPAGAIN ;
            PerlResult = POPi;
            PUTBACK ;
        }
        break;
    case 1:
        perl_call_pv((char *)SvPV_nolen(*cb_ref), G_ARRAY);
        SPAGAIN ;
        PerlResult = POPi;
        PUTBACK ;
        break;
    }
    FREETMPS ;
    LEAVE ;

    if(PerlResult == -1) {
#ifdef PERLWIN32GUI_DEBUG
	        printf("!XS(MsgLoop): posting WM_EXITLOOP to %ld...\n", hwnd);
#endif
        PostMessage(hwnd, WM_EXITLOOP, -1, 0);
        return 0;
    } else {
        if(PerlResult == 0) {
            return 0;
        } else {
            return DefWindowProc(hwnd, uMsg, wParam, lParam);
        }
    }
}

/*
    ###########################################################################
    # options parsing routines
    ###########################################################################
*/

    /*
    ###########################################################################
    # (@)INTERNAL:ParseWindowOptions(sp, mark, ax ,items, from_i, *perlcs)
    */
void ParseWindowOptions(
    NOTXSPROC
    register SV **sp,
    register SV **mark,
    I32 ax,
    I32 items,
    int from_i,
    LPPERLWIN32GUI_CREATESTRUCT perlcs
) {
    dTHR;
	int i, next_i;
    char * option;
    char * classname;
    SV** stored;
    SV* storing;
#ifdef PERLWIN32GUI_STRONGDEBUG
    printf("!XS(ParseWindowOptions): from_i=%d\n", from_i);
    printf("!XS(ParseWindowOptions): items=%d\n", items);
#endif
    next_i = -1;
    for(i=from_i; i<items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
#ifdef PERLWIN32GUI_STRONGDEBUG
            printf("!XS(ParseWindowOptions): got option '%s'\n", option);
#endif
            if(strcmp(option, "-class") == 0) {
                next_i = i + 1;
                perlcs->cs.lpszClass = (LPCTSTR) classname_From(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-text") == 0
            ||        strcmp(option, "-caption") == 0
            ||        strcmp(option, "-title") == 0) {
                next_i = i + 1;
                perlcs->cs.lpszName = (LPCTSTR) SvPV_nolen(ST(next_i));
            } else if(strcmp(option, "-style") == 0) {
                next_i = i + 1;
                perlcs->cs.style = (DWORD) SvIV(ST(next_i));
            } else if(strcmp(option, "-pushstyle") == 0
            ||        strcmp(option, "-addstyle") == 0) {
                next_i = i + 1;
                perlcs->cs.style |= (DWORD) SvIV(ST(next_i));
            } else if(strcmp(option, "-popstyle") == 0
            ||        strcmp(option, "-remstyle") == 0
            ||        strcmp(option, "-notstyle") == 0
            ||        strcmp(option, "-negstyle") == 0) {
                next_i = i + 1;
                perlcs->cs.style ^= (DWORD) SvIV(ST(next_i));
            } else if(strcmp(option, "-exstyle") == 0) {
                next_i = i + 1;
                perlcs->cs.dwExStyle = (DWORD) SvIV(ST(next_i));
            } else if(strcmp(option, "-pushexstyle") == 0
            ||        strcmp(option, "-addexstyle") == 0) {
                next_i = i + 1;
                perlcs->cs.dwExStyle |= (DWORD) SvIV(ST(next_i));
            } else if(strcmp(option, "-popexstyle") == 0
            ||        strcmp(option, "-remexstyle") == 0
            ||        strcmp(option, "-notexstyle") == 0
            ||        strcmp(option, "-negexstyle") == 0) {
                next_i = i + 1;
                perlcs->cs.dwExStyle ^= (DWORD) SvIV(ST(next_i));
            } else if(strcmp(option, "-left") == 0) {
                next_i = i + 1;
                perlcs->cs.x = (int) SvIV(ST(next_i));
            } else if(strcmp(option, "-top") == 0) {
                next_i = i + 1;
                perlcs->cs.y = (int) SvIV(ST(next_i));
            } else if(strcmp(option, "-width") == 0) {
                next_i = i + 1;
                perlcs->cs.cx = (int) SvIV(ST(next_i));
            } else if(strcmp(option, "-height") == 0) {
                next_i = i + 1;
                perlcs->cs.cy = (int) SvIV(ST(next_i));
            } else if(strcmp(option, "-parent") == 0) {
                next_i = i + 1;
                perlcs->cs.hwndParent = (HWND) handle_From(NOTXSCALL ST(next_i));
                perlcs->hvParent = (HV*) SvRV(ST(next_i));
            } else if(strcmp(option, "-menu") == 0) {
                next_i = i + 1;
                perlcs->cs.hMenu = (HMENU) handle_From(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-instance") == 0) {
                next_i = i + 1;
                perlcs->cs.hInstance = (HINSTANCE) SvIV(ST(next_i));
            } else if(strcmp(option, "-data") == 0) {
                next_i = i + 1;
/* ! */
                // pPointer = (LPVOID) SvPV_nolen(ST(next_i));
            } else if(strcmp(option, "-name") == 0) {
                next_i = i + 1;
                perlcs->szWindowName = SvPV_nolen(ST(next_i));
            } else if(strcmp(option, "-function") == 0) {
                next_i = i + 1;
                perlcs->szWindowFunction = SvPV_nolen(ST(next_i));
            } else if(strcmp(option, "-font") == 0) {
                next_i = i + 1;
                perlcs->hFont = (HFONT) handle_From(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-visible") == 0) {
                next_i = i + 1;
                SwitchFlag(perlcs->cs.style, WS_VISIBLE, SvIV(ST(next_i)));
            } else if(strcmp(option, "-disabled") == 0) {
                next_i = i + 1;
                SwitchFlag(perlcs->cs.style, WS_DISABLED, SvIV(ST(next_i)));
            } else if(strcmp(option, "-group") == 0) {
                next_i = i + 1;
                SwitchFlag(perlcs->cs.style, WS_GROUP, SvIV(ST(next_i)));
            } else if(strcmp(option, "-tabstop") == 0) {
                next_i = i + 1;
                SwitchFlag(perlcs->cs.style, WS_TABSTOP, SvIV(ST(next_i)));
            } else if(strcmp(option, "-foreground") == 0) {
                next_i = i + 1;
                perlcs->clrForeground = SvCOLORREF(NOTXSCALL ST(next_i));
                storing = newSViv((long) perlcs->clrForeground);
				stored = hv_store(perlcs->hvSelf, "-foreground", 11, storing, 0);
				if(SvMAGICAL(perlcs->hvSelf)) mg_set(storing);
            } else if(strcmp(option, "-background") == 0) {
                next_i = i + 1;
                perlcs->clrBackground = SvCOLORREF(NOTXSCALL ST(next_i));
                {
					LOGBRUSH lb;
					ZeroMemory(&lb, sizeof(LOGBRUSH));
			        lb.lbStyle = BS_SOLID;
        			lb.lbColor = perlcs->clrBackground;
					if(perlcs->hBackgroundBrush != NULL) {
						DeleteObject((HGDIOBJ) perlcs->hBackgroundBrush);
					}
        			perlcs->hBackgroundBrush = CreateBrushIndirect(&lb);
				}
                storing = newSViv((long) perlcs->clrBackground);
				stored = hv_store(perlcs->hvSelf, "-background", 11, storing, 0);
				if(SvMAGICAL(perlcs->hvSelf)) mg_set(storing);
                storing = newSViv((long) perlcs->hBackgroundBrush);
				stored = hv_store(perlcs->hvSelf, "-backgroundbrush", 16, storing, 0);
				if(SvMAGICAL(perlcs->hvSelf)) mg_set(storing);
            } else if(strcmp(option, "-hscroll") == 0) {
                next_i = i + 1;
                SwitchFlag(perlcs->cs.style, WS_HSCROLL, SvIV(ST(next_i)));
			} else if(strcmp(option, "-vscroll") == 0) {
                next_i = i + 1;
                SwitchFlag(perlcs->cs.style, WS_VSCROLL, SvIV(ST(next_i)));
            } else if(strcmp(option, "-size") == 0) {
				next_i = i + 1;
				if(SvROK(ST(next_i)) && SvTYPE(SvRV(ST(next_i))) == SVt_PVAV) {
					SV** t;
					t = av_fetch((AV*)SvRV(ST(next_i)), 0, 0);
					if(t != NULL) {
						perlcs->cs.cx = (int) SvIV(*t);
					}
					t = av_fetch((AV*)SvRV(ST(next_i)), 1, 0);
					if(t != NULL) {
						perlcs->cs.cy = (int) SvIV(*t);
					}
				} else {
					if(PL_dowarn)
						warn("Win32::GUI: Argument to -size is not an array reference!");
				}
            } else if(strcmp(option, "-pos") == 0) {
				next_i = i + 1;
				if(SvROK(ST(next_i)) && SvTYPE(SvRV(ST(next_i))) == SVt_PVAV) {
					SV** t;
					t = av_fetch((AV*)SvRV(ST(next_i)), 0, 0);
					if(t != NULL) {
						perlcs->cs.x = (int) SvIV(*t);
					}
					t = av_fetch((AV*)SvRV(ST(next_i)), 1, 0);
					if(t != NULL) {
						perlcs->cs.y = (int) SvIV(*t);
					}
				} else {
					if(PL_dowarn)
						warn("Win32::GUI: Argument to -pos is not an array reference!");
				}
			}
            // ######################
            // class-specific parsing
            // ######################
            switch(perlcs->iClass) {

            case WIN32__GUI__WINDOW:
            case WIN32__GUI__DIALOG:
                if(strcmp(option, "-minsize") == 0) {
                    next_i = i + 1;
                    if(SvROK(ST(next_i)) && SvTYPE(SvRV(ST(next_i))) == SVt_PVAV) {
                        SV** t;
                        t = av_fetch((AV*)SvRV(ST(next_i)), 0, 0);
                        if(t != NULL) {
							perlcs->iMinWidth = (int) SvIV(*t);
                            storing = newSViv((LONG) SvIV(*t));
                            stored = hv_store(perlcs->hvSelf, "-minwidth", 9, storing, 0);
                            if(SvMAGICAL(perlcs->hvSelf)) mg_set(storing);
                        }
                        t = av_fetch((AV*)SvRV(ST(next_i)), 1, 0);
                        if(t != NULL) {
							perlcs->iMinHeight = (int) SvIV(*t);
                            storing = newSViv((LONG) SvIV(*t));
                            stored = hv_store(perlcs->hvSelf, "-minheight", 10, storing, 0);
                            if(SvMAGICAL(perlcs->hvSelf)) mg_set(storing);
                        }
                    } else {
                        if(PL_dowarn)
                            warn("Win32::GUI: Argument to -minsize is not an array reference!");
                    }
                } else if(strcmp(option, "-maxsize") == 0) {
                    next_i = i + 1;
                    if(SvROK(ST(next_i)) && SvTYPE(SvRV(ST(next_i))) == SVt_PVAV) {
                        SV** t;
                        t = av_fetch((AV*)SvRV(ST(next_i)), 0, 0);
                        if(t != NULL) {
							perlcs->iMaxWidth = (int) SvIV(*t);
                            storing = newSViv((LONG) SvIV(*t));
                            stored = hv_store(perlcs->hvSelf, "-maxwidth", 9, storing, 0);
                            if(SvMAGICAL(perlcs->hvSelf)) mg_set(storing);
                        }
                        t = av_fetch((AV*)SvRV(ST(next_i)), 1, 0);
                        if(t != NULL) {
							perlcs->iMaxHeight = (int) SvIV(*t);
                            storing = newSViv((LONG) SvIV(*t));
                            stored = hv_store(perlcs->hvSelf, "-maxheight", 10, storing, 0);
                            if(SvMAGICAL(perlcs->hvSelf)) mg_set(storing);
                        }
                    } else {
                        if(PL_dowarn)
                            warn("Win32::GUI: Argument to -maxsize is not an array reference!");
                    }
                } else if(strcmp(option, "-minwidth") == 0) {
                    next_i = i + 1;
                    perlcs->iMinWidth = (int) SvIV(ST(next_i));
                    storing = newSViv((LONG) SvIV(ST(next_i)));
                    stored = hv_store(perlcs->hvSelf, "-minwidth", 9, storing, 0);
                    if(SvMAGICAL(perlcs->hvSelf)) mg_set(storing);
                } else if(strcmp(option, "-minheight") == 0) {
                    next_i = i + 1;
                    perlcs->iMinHeight = (int) SvIV(ST(next_i));
                    storing = newSViv((LONG) SvIV(ST(next_i)));
                    stored = hv_store(perlcs->hvSelf, "-minheight", 10, storing, 0);
                    if(SvMAGICAL(perlcs->hvSelf)) mg_set(storing);
                } else if(strcmp(option, "-maxwidth") == 0) {
                    next_i = i + 1;
                    perlcs->iMaxWidth = (int) SvIV(ST(next_i));
                    storing = newSViv((LONG) SvIV(ST(next_i)));
                    stored = hv_store(perlcs->hvSelf, "-maxwidth", 9, storing, 0);
                    if(SvMAGICAL(perlcs->hvSelf)) mg_set(storing);
                } else if(strcmp(option, "-maxheight") == 0) {
                    next_i = i + 1;
                    perlcs->iMaxHeight = (int) SvIV(ST(next_i));
                    storing = newSViv((LONG) SvIV(ST(next_i)));
                    stored = hv_store(perlcs->hvSelf, "-maxheight", 10, storing, 0);
                    if(SvMAGICAL(perlcs->hvSelf)) mg_set(storing);
                } else if(strcmp(option, "-topmost") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.dwExStyle, WS_EX_TOPMOST, SvIV(ST(next_i)));
                } else if(strcmp(option, "-controlparent") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.dwExStyle, WS_EX_CONTROLPARENT, SvIV(ST(next_i)));
				} else if(strcmp(option, "-hasmaximize") == 0
				||        strcmp(option, "-maximizebox") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, WS_MAXIMIZEBOX, SvIV(ST(next_i)));
				} else if(strcmp(option, "-hasminimize") == 0
				||        strcmp(option, "-minimizebox") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, WS_MINIMIZEBOX, SvIV(ST(next_i)));
				} else if(strcmp(option, "-sizable") == 0
				||        strcmp(option, "-resizable") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, WS_THICKFRAME, SvIV(ST(next_i)));
				} else if(strcmp(option, "-sysmenu") == 0
				||        strcmp(option, "-menubox") == 0
				||        strcmp(option, "-controlbox") == 0) {
					next_i = i + 1;
					SwitchFlag(perlcs->cs.style, WS_SYSMENU, SvIV(ST(next_i)));
				} else if(strcmp(option, "-helpbutton") == 0
				||        strcmp(option, "-helpbox") == 0
				||        strcmp(option, "-hashelp") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.dwExStyle, WS_EX_CONTEXTHELP, SvIV(ST(next_i)));
				} else if(strcmp(option, "-accel") == 0
				||        strcmp(option, "-accelerators") == 0
				||        strcmp(option, "-acceleratortable") == 0) {
					next_i = i + 1;
					perlcs->hAcc = (HACCEL) handle_From(NOTXSCALL ST(next_i));
                    storing = newSViv((LONG) handle_From(NOTXSCALL ST(next_i)));
                    stored = hv_store(perlcs->hvSelf, "-accel", 6, storing, 0);
                    if(SvMAGICAL(perlcs->hvSelf)) mg_set(storing);
				}
				break;

            case WIN32__GUI__STATIC:
                if(strcmp(option, "-align") == 0) {
                    next_i = i + 1;
                    if(strcmp(SvPV_nolen(ST(next_i)), "left") == 0) {
                        SwitchFlag(perlcs->cs.style, SS_LEFT, 1);
                        SwitchFlag(perlcs->cs.style, SS_CENTER, 0);
                        SwitchFlag(perlcs->cs.style, SS_RIGHT, 0);
                    } else if(strcmp(SvPV_nolen(ST(next_i)), "center") == 0) {
                        SwitchFlag(perlcs->cs.style, SS_LEFT, 0);
                        SwitchFlag(perlcs->cs.style, SS_CENTER, 1);
                        SwitchFlag(perlcs->cs.style, SS_RIGHT, 0);
                    } else if(strcmp(SvPV_nolen(ST(next_i)), "right") == 0) {
                        SwitchFlag(perlcs->cs.style, SS_LEFT, 0);
                        SwitchFlag(perlcs->cs.style, SS_CENTER, 0);
                        SwitchFlag(perlcs->cs.style, SS_RIGHT, 1);
                    } else {
                        if(PL_dowarn) warn("Win32::GUI: Invalid value for -align!");
                    }
                } else if(strcmp(option, "-bitmap") == 0
                ||        strcmp(option, "-picture") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, SS_BITMAP, 1);
                    perlcs->hImageList = (HIMAGELIST) handle_From(NOTXSCALL ST(next_i));
                } else if(strcmp(option, "-truncate") == 0) {
                    next_i = i + 1;
                    if(strcmp(SvPV_nolen(ST(next_i)), "path") == 0) {
                        SwitchFlag(perlcs->cs.style, SS_PATHELLIPSIS, 1);
                        SwitchFlag(perlcs->cs.style, SS_ENDELLIPSIS, 0);
                        SwitchFlag(perlcs->cs.style, SS_WORDELLIPSIS, 0);
                    } else if(strcmp(SvPV_nolen(ST(next_i)), "word") == 0) {
                        SwitchFlag(perlcs->cs.style, SS_PATHELLIPSIS, 0);
                        SwitchFlag(perlcs->cs.style, SS_ENDELLIPSIS, 0);
                        SwitchFlag(perlcs->cs.style, SS_WORDELLIPSIS, 1);
                    } else if(SvIV(ST(next_i))) {
                        SwitchFlag(perlcs->cs.style, SS_PATHELLIPSIS, 0);
                        SwitchFlag(perlcs->cs.style, SS_ENDELLIPSIS, 1);
                        SwitchFlag(perlcs->cs.style, SS_WORDELLIPSIS, 0);
                    } else {
                        SwitchFlag(perlcs->cs.style, SS_PATHELLIPSIS, 0);
                        SwitchFlag(perlcs->cs.style, SS_ENDELLIPSIS, 0);
                        SwitchFlag(perlcs->cs.style, SS_WORDELLIPSIS, 0);
                    }
                } else if(strcmp(option, "-frame") == 0) {
                    next_i = i + 1;
                    if(strcmp(SvPV_nolen(ST(next_i)), "black") == 0) {
                        SwitchFlag(perlcs->cs.style, SS_BLACKFRAME, 1);
                        SwitchFlag(perlcs->cs.style, SS_GRAYFRAME, 0);
                        SwitchFlag(perlcs->cs.style, SS_WHITEFRAME, 0);
                        SwitchFlag(perlcs->cs.style, SS_ETCHEDFRAME, 0);
                    } else if(strcmp(SvPV_nolen(ST(next_i)), "gray") == 0) {
                        SwitchFlag(perlcs->cs.style, SS_BLACKFRAME, 0);
                        SwitchFlag(perlcs->cs.style, SS_GRAYFRAME, 1);
                        SwitchFlag(perlcs->cs.style, SS_WHITEFRAME, 0);
                        SwitchFlag(perlcs->cs.style, SS_ETCHEDFRAME, 0);
                    } else if(strcmp(SvPV_nolen(ST(next_i)), "white") == 0) {
                        SwitchFlag(perlcs->cs.style, SS_BLACKFRAME, 0);
                        SwitchFlag(perlcs->cs.style, SS_GRAYFRAME, 0);
                        SwitchFlag(perlcs->cs.style, SS_WHITEFRAME, 1);
                        SwitchFlag(perlcs->cs.style, SS_ETCHEDFRAME, 0);
                    } else if(strcmp(SvPV_nolen(ST(next_i)), "etched") == 0) {
                        SwitchFlag(perlcs->cs.style, SS_BLACKFRAME, 0);
                        SwitchFlag(perlcs->cs.style, SS_GRAYFRAME, 0);
                        SwitchFlag(perlcs->cs.style, SS_WHITEFRAME, 0);
                        SwitchFlag(perlcs->cs.style, SS_ETCHEDFRAME, 1);
                    } else {
                        SwitchFlag(perlcs->cs.style, SS_BLACKFRAME, 0);
                        SwitchFlag(perlcs->cs.style, SS_GRAYFRAME, 0);
                        SwitchFlag(perlcs->cs.style, SS_WHITEFRAME, 0);
                        SwitchFlag(perlcs->cs.style, SS_ETCHEDFRAME, 0);
                    }
                } else if(strcmp(option, "-fill") == 0) {
                    next_i = i + 1;
                    if(strcmp(SvPV_nolen(ST(next_i)), "black") == 0) {
                        SwitchFlag(perlcs->cs.style, SS_BLACKRECT, 1);
                        SwitchFlag(perlcs->cs.style, SS_GRAYRECT, 0);
                        SwitchFlag(perlcs->cs.style, SS_WHITERECT, 0);
                    } else if(strcmp(SvPV_nolen(ST(next_i)), "gray") == 0) {
                        SwitchFlag(perlcs->cs.style, SS_BLACKRECT, 0);
                        SwitchFlag(perlcs->cs.style, SS_GRAYRECT, 1);
                        SwitchFlag(perlcs->cs.style, SS_WHITERECT, 0);
                    } else if(strcmp(SvPV_nolen(ST(next_i)), "white") == 0) {
                        SwitchFlag(perlcs->cs.style, SS_BLACKRECT, 0);
                        SwitchFlag(perlcs->cs.style, SS_GRAYRECT, 0);
                        SwitchFlag(perlcs->cs.style, SS_WHITERECT, 1);
                    } else if(strcmp(SvPV_nolen(ST(next_i)), "etched") == 0) {
                        SwitchFlag(perlcs->cs.style, SS_BLACKRECT, 0);
                        SwitchFlag(perlcs->cs.style, SS_GRAYRECT, 0);
                        SwitchFlag(perlcs->cs.style, SS_WHITERECT, 0);
                    } else {
                        SwitchFlag(perlcs->cs.style, SS_BLACKRECT, 0);
                        SwitchFlag(perlcs->cs.style, SS_GRAYRECT, 0);
                        SwitchFlag(perlcs->cs.style, SS_WHITERECT, 0);
                    }
                } else if(strcmp(option, "-sunken") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, SS_SUNKEN, SvIV(ST(next_i)));
                } else if(strcmp(option, "-wrap") == 0) {
                    next_i = i + 1;
                    if(SvIV(ST(next_i))) {
                        SwitchFlag(perlcs->cs.style, SS_LEFTNOWORDWRAP, 0);
                    } else {
                        SwitchFlag(perlcs->cs.style, SS_LEFTNOWORDWRAP, 1);
                    }
                } else if(strcmp(option, "-notify") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, SS_NOTIFY, SvIV(ST(next_i)));
                }
                break;

            case WIN32__GUI__EDIT:
            case WIN32__GUI__RICHEDIT:
                if(strcmp(option, "-align") == 0) {
                    next_i = i + 1;
                    if(strcmp(SvPV_nolen(ST(next_i)), "left") == 0) {
                        SwitchFlag(perlcs->cs.style, ES_LEFT, 1);
                        SwitchFlag(perlcs->cs.style, ES_CENTER, 0);
                        SwitchFlag(perlcs->cs.style, ES_RIGHT, 0);
                    } else if(strcmp(SvPV_nolen(ST(next_i)), "center") == 0) {
                        SwitchFlag(perlcs->cs.style, ES_LEFT, 0);
                        SwitchFlag(perlcs->cs.style, ES_CENTER, 1);
                        SwitchFlag(perlcs->cs.style, ES_RIGHT, 0);
                    } else if(strcmp(SvPV_nolen(ST(next_i)), "right") == 0) {
                        SwitchFlag(perlcs->cs.style, ES_LEFT, 0);
                        SwitchFlag(perlcs->cs.style, ES_CENTER, 0);
                        SwitchFlag(perlcs->cs.style, ES_RIGHT, 1);
                    } else {
                        if(PL_dowarn) warn("Win32::GUI: Invalid value for -align!");
                    }
                } else if(strcmp(option, "-multiline") == 0) {
                    next_i = i + 1;
                    if(SvIV(ST(next_i))) {
                    	SwitchFlag(perlcs->cs.style, ES_MULTILINE, 1);
                    	SwitchFlag(perlcs->cs.style, ES_AUTOHSCROLL, 0);
                    } else {
                    	SwitchFlag(perlcs->cs.style, ES_MULTILINE, 0);
                    	SwitchFlag(perlcs->cs.style, ES_AUTOHSCROLL, 1);
					}
                } else if(strcmp(option, "-keepselection") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, ES_NOHIDESEL, SvIV(ST(next_i)));
                } else if(strcmp(option, "-readonly") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, ES_READONLY, SvIV(ST(next_i)));
                } else if(strcmp(option, "-password") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, ES_PASSWORD, SvIV(ST(next_i)));
                } else if(strcmp(option, "-lowercase") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, ES_LOWERCASE, SvIV(ST(next_i)));
                } else if(strcmp(option, "-uppercase") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, ES_UPPERCASE, SvIV(ST(next_i)));
                } else if(strcmp(option, "-autohscroll") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, ES_AUTOHSCROLL, SvIV(ST(next_i)));
                } else if(strcmp(option, "-autovscroll") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, ES_AUTOVSCROLL, SvIV(ST(next_i)));
                } else if(strcmp(option, "-number") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, ES_NUMBER, SvIV(ST(next_i)));
                }
                break;

            case WIN32__GUI__BUTTON:
            case WIN32__GUI__RADIOBUTTON:
            case WIN32__GUI__CHECKBOX:
                if(strcmp(option, "-align") == 0) {
                    next_i = i + 1;
                    if(strcmp(SvPV_nolen(ST(next_i)), "left") == 0) {
                        SwitchFlag(perlcs->cs.style, BS_LEFT, 1);
                        SwitchFlag(perlcs->cs.style, BS_CENTER, 0);
                        SwitchFlag(perlcs->cs.style, BS_RIGHT, 0);
                    } else if(strcmp(SvPV_nolen(ST(next_i)), "center") == 0) {
                        SwitchFlag(perlcs->cs.style, BS_LEFT, 0);
                        SwitchFlag(perlcs->cs.style, BS_CENTER, 1);
                        SwitchFlag(perlcs->cs.style, BS_RIGHT, 0);
                    } else if(strcmp(SvPV_nolen(ST(next_i)), "right") == 0) {
                        SwitchFlag(perlcs->cs.style, BS_LEFT, 0);
                        SwitchFlag(perlcs->cs.style, BS_CENTER, 0);
                        SwitchFlag(perlcs->cs.style, BS_RIGHT, 1);
                    } else {
                        if(PL_dowarn) warn("Win32::GUI: Invalid value for -align!");
                    }
                } else if(strcmp(option, "-valign") == 0) {
                    next_i = i + 1;
                    if(strcmp(SvPV_nolen(ST(next_i)), "top") == 0) {
                        SwitchFlag(perlcs->cs.style, BS_TOP, 1);
                        SwitchFlag(perlcs->cs.style, BS_VCENTER, 0);
                        SwitchFlag(perlcs->cs.style, BS_BOTTOM, 0);
                    } else if(strcmp(SvPV_nolen(ST(next_i)), "center") == 0) {
                        SwitchFlag(perlcs->cs.style, BS_TOP, 0);
                        SwitchFlag(perlcs->cs.style, BS_VCENTER, 1);
                        SwitchFlag(perlcs->cs.style, BS_BOTTOM, 0);
                    } else if(strcmp(SvPV_nolen(ST(next_i)), "bottom") == 0) {
                        SwitchFlag(perlcs->cs.style, BS_TOP, 0);
                        SwitchFlag(perlcs->cs.style, BS_VCENTER, 0);
                        SwitchFlag(perlcs->cs.style, BS_BOTTOM, 1);
                    } else {
                        if(PL_dowarn) warn("Win32::GUI: Invalid value for -valign!");
                    }
                } else if(strcmp(option, "-ok") == 0) {
                    next_i = i + 1;
                    if(SvIV(ST(next_i)) != 0) {
                        perlcs->cs.hMenu = (HMENU) IDOK;
                    }
                } else if(strcmp(option, "-cancel") == 0) {
                    next_i = i + 1;
                    if(SvIV(ST(next_i)) != 0) {
                        perlcs->cs.hMenu = (HMENU) IDCANCEL;
                    }
                } else if(strcmp(option, "-default") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, BS_DEFPUSHBUTTON, SvIV(ST(next_i)));
                } else if(strcmp(option, "-bitmap") == 0
                ||        strcmp(option, "-picture") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, BS_BITMAP, 1);
                    perlcs->hImageList = (HIMAGELIST) handle_From(NOTXSCALL ST(next_i));
                } else if(strcmp(option, "-icon") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, BS_BITMAP, 1);
                    perlcs->hImageList = (HIMAGELIST) handle_From(NOTXSCALL ST(next_i));
                }
                break;

            case WIN32__GUI__LISTBOX:
                if(strcmp(option, "-multisel") == 0) {
                    next_i = i + 1;
                    if(SvIV(ST(next_i)) == 0) {
                        SwitchFlag(perlcs->cs.style, LBS_MULTIPLESEL, 0);
                        SwitchFlag(perlcs->cs.style, LBS_EXTENDEDSEL, 0);
                    } else if(SvIV(ST(next_i)) == 1) {
                        SwitchFlag(perlcs->cs.style, LBS_MULTIPLESEL, 1);
                        SwitchFlag(perlcs->cs.style, LBS_EXTENDEDSEL, 0);
                    } else if(SvIV(ST(next_i)) == 2) {
                        SwitchFlag(perlcs->cs.style, LBS_MULTIPLESEL, 1);
                        SwitchFlag(perlcs->cs.style, LBS_EXTENDEDSEL, 1);
                    } else {
                        if(PL_dowarn) warn("Win32::GUI: Invalid value for -multisel!");
                    }
                } else if(strcmp(option, "-sort") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, LBS_SORT, SvIV(ST(next_i)));
                }
                break;

            case WIN32__GUI__TAB:
                if(strcmp(option, "-imagelist") == 0) {
                    next_i = i + 1;
                    perlcs->hImageList = (HIMAGELIST) handle_From(NOTXSCALL ST(next_i));
                } else if(strcmp(option, "-multiline") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, TCS_MULTILINE, SvIV(ST(next_i)));
                } else if(strcmp(option, "-vertical") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, TCS_VERTICAL, SvIV(ST(next_i)));
                    SwitchFlag(perlcs->cs.style, TCS_MULTILINE, SvIV(ST(next_i)));
                } else if(strcmp(option, "-bottom") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, TCS_BOTTOM, SvIV(ST(next_i)));
                } else if(strcmp(option, "-right") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, TCS_RIGHT, SvIV(ST(next_i)));
                } else if(strcmp(option, "-hottrack") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, TCS_HOTTRACK, SvIV(ST(next_i)));
                } else if(strcmp(option, "-buttons") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, TCS_BUTTONS, SvIV(ST(next_i)));
                } else if(strcmp(option, "-justify") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, TCS_RIGHTJUSTIFY, SvIV(ST(next_i)));
                } else if(strcmp(option, "-flat") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, TCS_FLATBUTTONS, SvIV(ST(next_i)));
                }
                break;

            /*
            case WIN32__GUI__TOOLBAR:
                if(strcmp(option, "-imagelist") == 0) {
                    next_i = i + 1;
                    perlcs->hImageList = (HIMAGELIST) handle_From(NOTXSCALL ST(next_i));
                } else if(strcmp(option, "-flat") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, TBSTYLE_FLAT, SvIV(ST(next_i)));
                } else if(strcmp(option, "-nodivider") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, CCS_NODIVIDER, SvIV(ST(next_i)));
                } else if(strcmp(option, "-multiline") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, TBSTYLE_WRAPABLE, SvIV(ST(next_i)));

                }

                break;
            */

            case WIN32__GUI__LISTVIEW:
                if(strcmp(option, "-align") == 0) {
                    next_i = i + 1;
                    if(strcmp(SvPV_nolen(ST(next_i)), "left") == 0) {
                        SwitchFlag(perlcs->cs.style, LVS_ALIGNLEFT, 1);
                        SwitchFlag(perlcs->cs.style, LVS_ALIGNTOP, 0);
                    } else if(strcmp(SvPV_nolen(ST(next_i)), "top") == 0) {
                        SwitchFlag(perlcs->cs.style, LVS_ALIGNLEFT, 0);
                        SwitchFlag(perlcs->cs.style, LVS_ALIGNTOP, 1);
                    } else {
                        if(PL_dowarn) warn("Win32::GUI: Invalid value for -align!");
                    }
                } else if(strcmp(option, "-imagelist") == 0) {
                    next_i = i + 1;
                    perlcs->hImageList = (HIMAGELIST) handle_From(NOTXSCALL ST(next_i));
                } else if(strcmp(option, "-nocolumnheader") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, LVS_NOCOLUMNHEADER, SvIV(ST(next_i)));
                } else if(strcmp(option, "-nosortheader") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, LVS_NOSORTHEADER, SvIV(ST(next_i)));
                } else if(strcmp(option, "-singlesel") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, LVS_SINGLESEL, SvIV(ST(next_i)));
                } else if(strcmp(option, "-autoarrange") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, LVS_AUTOARRANGE, SvIV(ST(next_i)));
                } else if(strcmp(option, "-showselalways") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, LVS_SHOWSELALWAYS, SvIV(ST(next_i)));
                } else if(strcmp(option, "-sortascending") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, LVS_SORTASCENDING, SvIV(ST(next_i)));
                } else if(strcmp(option, "-sortdescending") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, LVS_SORTDESCENDING, SvIV(ST(next_i)));
                } else if(strcmp(option, "-fullrowselect") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.dwExStyle, LVS_EX_FULLROWSELECT, SvIV(ST(next_i)));
                } else if(strcmp(option, "-gridlines") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.dwExStyle, LVS_EX_GRIDLINES, SvIV(ST(next_i)));
                } else if(strcmp(option, "-reordercolumns") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.dwExStyle, LVS_EX_HEADERDRAGDROP, SvIV(ST(next_i)));
                } else if(strcmp(option, "-checkboxes") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.dwExStyle, LVS_EX_CHECKBOXES, SvIV(ST(next_i)));
                } else if(strcmp(option, "-hottrack") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.dwExStyle, LVS_EX_TRACKSELECT, SvIV(ST(next_i)));
                }
                break;

            case WIN32__GUI__TREEVIEW:
                if(strcmp(option, "-lines") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, TVS_HASLINES, SvIV(ST(next_i)));
                } else if(strcmp(option, "-rootlines") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, TVS_LINESATROOT, SvIV(ST(next_i)));
                } else if(strcmp(option, "-buttons") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, TVS_HASBUTTONS, SvIV(ST(next_i)));
                } else if(strcmp(option, "-imagelist") == 0) {
                    next_i = i + 1;
                    perlcs->hImageList = (HIMAGELIST) handle_From(NOTXSCALL ST(next_i));
                } else if(strcmp(option, "-showselalways") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, TVS_SHOWSELALWAYS, SvIV(ST(next_i)));
                } else if(strcmp(option, "-checkboxes") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, TVS_CHECKBOXES, SvIV(ST(next_i)));
                } else if(strcmp(option, "-hottrack") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, TVS_TRACKSELECT, SvIV(ST(next_i)));
                }
                break;

            case WIN32__GUI__TRACKBAR:
                if(strcmp(option, "-vertical") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, TBS_VERT, SvIV(ST(next_i)));
                } else if(strcmp(option, "-noticks") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, TBS_NOTICKS, SvIV(ST(next_i)));
                } else if(strcmp(option, "-nothumb") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, TBS_NOTHUMB, SvIV(ST(next_i)));
                }
                break;

            case WIN32__GUI__UPDOWN:
                if(strcmp(option, "-align") == 0) {
                    next_i = i + 1;
                    if(strcmp(SvPV_nolen(ST(next_i)), "left") == 0) {
                        SwitchFlag(perlcs->cs.style, UDS_ALIGNLEFT, 1);
                        SwitchFlag(perlcs->cs.style, UDS_ALIGNRIGHT, 0);
                    } else if(strcmp(SvPV_nolen(ST(next_i)), "right") == 0) {
                        SwitchFlag(perlcs->cs.style, UDS_ALIGNLEFT, 0);
                        SwitchFlag(perlcs->cs.style, UDS_ALIGNRIGHT, 1);
                    } else {
                        if(PL_dowarn) warn("Win32::GUI: Invalid value for -align!");
                    }
                } else if(strcmp(option, "-nothousands") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, UDS_NOTHOUSANDS, SvIV(ST(next_i)));
                } else if(strcmp(option, "-wrap") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, UDS_WRAP, SvIV(ST(next_i)));
                } else if(strcmp(option, "-horizontal") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, UDS_HORZ, SvIV(ST(next_i)));
                } else if(strcmp(option, "-autobuddy") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, UDS_AUTOBUDDY, SvIV(ST(next_i)));
                } else if(strcmp(option, "-setbuddy") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, UDS_SETBUDDYINT, SvIV(ST(next_i)));
                }
                break;

            case WIN32__GUI__ANIMATION:
                if(strcmp(option, "-autoplay") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, ACS_AUTOPLAY, SvIV(ST(next_i)));
                } else if(strcmp(option, "-center") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, ACS_CENTER, SvIV(ST(next_i)));
                } else if(strcmp(option, "-transparent") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, ACS_TRANSPARENT, SvIV(ST(next_i)));
                }
                break;

            case WIN32__GUI__REBAR:
                if(strcmp(option, "-imagelist") == 0) {
                    next_i = i + 1;
                    perlcs->hImageList = (HIMAGELIST) handle_From(NOTXSCALL ST(next_i));
                } else if(strcmp(option, "-bandborders") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, RBS_BANDBORDERS, SvIV(ST(next_i)));
                } else if(strcmp(option, "-fixedorder") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, RBS_FIXEDORDER, SvIV(ST(next_i)));
                } else if(strcmp(option, "-varheight") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, RBS_VARHEIGHT, SvIV(ST(next_i)));
                } else if(strcmp(option, "-autosize") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, RBS_AUTOSIZE, SvIV(ST(next_i)));
                } else if(strcmp(option, "-vertical") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, CCS_VERT, SvIV(ST(next_i)));
                } else if(strcmp(option, "-doubleclick") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, RBS_DBLCLKTOGGLE, SvIV(ST(next_i)));
                } else if(strcmp(option, "-vgripper") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, RBS_VERTICALGRIPPER, SvIV(ST(next_i)));
                }
                break;

            case WIN32__GUI__PROGRESS:
                if(strcmp(option, "-smooth") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, PBS_SMOOTH, SvIV(ST(next_i)));
                } else if(strcmp(option, "-vertical") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, PBS_VERTICAL, SvIV(ST(next_i)));
                }
                break;

            case WIN32__GUI__HEADER:
                if(strcmp(option, "-imagelist") == 0) {
                    next_i = i + 1;
                    perlcs->hImageList = (HIMAGELIST) handle_From(NOTXSCALL ST(next_i));
                } else if(strcmp(option, "-buttons") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, HDS_BUTTONS, SvIV(ST(next_i)));
                } else if(strcmp(option, "-hottrack") == 0) {
                    next_i = i + 1;
                    SwitchFlag(perlcs->cs.style, HDS_HOTTRACK, SvIV(ST(next_i)));
                }
                break;

			case WIN32__GUI__COMBOBOXEX:
                if(strcmp(option, "-imagelist") == 0) {
                    next_i = i + 1;
				    perlcs->hImageList = (HIMAGELIST) handle_From(NOTXSCALL ST(next_i));
				}
				break;

            case WIN32__GUI__GRAPHIC:
                if(strcmp(option, "-interactive") == 0) {
                    next_i = i + 1;
                    if(SvIV(ST(next_i))) {
			        	perlcs->cs.lpszClass = "Win32::GUI::InteractiveGraphic";
					} else {
						perlcs->cs.lpszClass = "Win32::GUI::Graphic";
					}
				}
				break;

            case WIN32__GUI__SPLITTER:
                if(strcmp(option, "-horizontal") == 0) {
                    next_i = i + 1;
                    if(SvIV(ST(next_i))) {
			        	perlcs->cs.lpszClass = "Win32::GUI::Splitter(horizontal)";
					} else {
						perlcs->cs.lpszClass = "Win32::GUI::Splitter(vertical)";
					}
					storing = newSViv((LONG) SvIV(ST(next_i)));
					stored = hv_store(perlcs->hvSelf, "-horizontal", 11, storing, 0);
					if(SvMAGICAL(perlcs->hvSelf)) mg_set(storing);
                } else if(strcmp(option, "-min") == 0) {
                    next_i = i + 1;
                    storing = newSViv((LONG) SvIV(ST(next_i)));
                    stored = hv_store(perlcs->hvSelf, "-min", 4, storing, 0);
                    if(SvMAGICAL(perlcs->hvSelf)) mg_set(storing);
				} else if(strcmp(option, "-max") == 0) {
                    next_i = i + 1;
                    storing = newSViv((LONG) SvIV(ST(next_i)));
                    stored = hv_store(perlcs->hvSelf, "-max", 4, storing, 0);
                    if(SvMAGICAL(perlcs->hvSelf)) mg_set(storing);
				} else if(strcmp(option, "-range") == 0) {
                    if(SvROK(ST(next_i)) && SvTYPE(SvRV(ST(next_i))) == SVt_PVAV) {
                        SV** t;
                        t = av_fetch((AV*)SvRV(ST(next_i)), 0, 0);
                        if(t != NULL) {
                            storing = newSViv((LONG) SvIV(*t));
                            stored = hv_store(perlcs->hvSelf, "-min", 4, storing, 0);
                            if(SvMAGICAL(perlcs->hvSelf)) mg_set(storing);
                        }
                        t = av_fetch((AV*)SvRV(ST(next_i)), 1, 0);
                        if(t != NULL) {
                            storing = newSViv((LONG) SvIV(*t));
                            stored = hv_store(perlcs->hvSelf, "-max", 4, storing, 0);
                            if(SvMAGICAL(perlcs->hvSelf)) mg_set(storing);
                        }
                    } else {
                        if(PL_dowarn)
                            warn("Win32::GUI: Argument to -range is not an array reference!");
                    }
				}
				break;
            }
        } else {
            next_i = -1;
        }
    }
}

    /*
    ###########################################################################
    # (@)INTERNAL:ParseMenuItemOptions(sp, mark, ax, items, from_i, mii, *item)
    */
void ParseMenuItemOptions(
    NOTXSPROC
    register SV **sp,
    register SV **mark,
    I32 ax,
    I32 items,
    int from_i,
    LPMENUITEMINFO mii,
    UINT* myItem
) {
    dTHR;
	int i, next_i;
    char * option;
    unsigned int textlength;
    next_i = -1;
#ifdef PERLWIN32GUI_STRONGDEBUG
    printf("!XS(ParseMenuItemOptions): items='%d'\n", items);
#endif
    for(i = from_i; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
#ifdef PERLWIN32GUI_STRONGDEBUG
            printf("!XS(ParseMenuItemOptions): got option '%s'\n", option);
#endif
            if(strcmp(option, "-mask") == 0) {
                next_i = i + 1;
                mii->fMask = (UINT) SvIV(ST(next_i));
            }
            if(strcmp(option, "-flag") == 0) {
                next_i = i + 1;
                mii->fType = (UINT) SvIV(ST(next_i));
            }
            if(strcmp(option, "-state") == 0) {
                SwitchFlag(mii->fMask, MIIM_STATE, 1);
                next_i = i + 1;
                mii->fState = (UINT) SvIV(ST(next_i));
            }
            if(strcmp(option, "-id") == 0) {
                SwitchFlag(mii->fMask, MIIM_ID, 1);
                next_i = i + 1;
                mii->wID = (UINT) SvIV(ST(next_i));
            }
            if(strcmp(option, "-submenu") == 0) {
                SwitchFlag(mii->fMask, MIIM_SUBMENU, 1);
                next_i = i + 1;
                mii->hSubMenu = (HMENU) handle_From(NOTXSCALL ST(next_i));
            }
            if(strcmp(option, "-data") == 0) {
                SwitchFlag(mii->fMask, MIIM_DATA, 1);
                next_i = i + 1;
                mii->dwItemData = (DWORD) SvIV(ST(next_i));
            }
            if(strcmp(option, "-text") == 0) {
                SwitchFlag(mii->fMask, MIIM_TYPE, 1);
                SwitchFlag(mii->fType, MFT_STRING, 1);
                next_i = i + 1;
                mii->dwTypeData = SvPV(ST(next_i), textlength);
                mii->cch = textlength;
#ifdef PERLWIN32GUI_STRONGDEBUG
                printf("!XS(ParseMenuItemOptions): dwTypeData='%s' cch=%d\n", mii->dwTypeData, mii->cch);
#endif
            }
            if(strcmp(option, "-item") == 0) {
                next_i = i + 1;
                *myItem = SvIV(ST(next_i));
            }
            if(strcmp(option, "-separator") == 0) {
                SwitchFlag(mii->fMask, MIIM_TYPE, 1);
                next_i = i + 1;
                SwitchFlag(mii->fType, MFT_SEPARATOR, SvIV(ST(next_i)));
            }
            if(strcmp(option, "-default") == 0) {
                SwitchFlag(mii->fMask, MIIM_STATE, 1);
                next_i = i + 1;
                SwitchFlag(mii->fState, MFS_DEFAULT, SvIV(ST(next_i)));
            }
            if(strcmp(option, "-checked") == 0) {
                SwitchFlag(mii->fMask, MIIM_STATE, 1);
                next_i = i + 1;
                SwitchFlag(mii->fState, MFS_CHECKED, SvIV(ST(next_i)));
            }
            if(strcmp(option, "-enabled") == 0) {
                SwitchFlag(mii->fMask, MIIM_STATE, 1);
                next_i = i + 1;
                SwitchFlag(mii->fState, MFS_ENABLED, SvIV(ST(next_i)));
            }

        } else {
            next_i = -1;
        }
    }
}

    /*
    ###########################################################################
    # (@)INTERNAL:ParseHeaderItemOptions(sp, mark, ax ,items, from_i, *hditem, *index)
    */
void ParseHeaderItemOptions(
    NOTXSPROC
    register SV **sp,
    register SV **mark,
    I32 ax,
    I32 items,
    int from_i,
    LPHDITEMA hditem,
    int * index
) {
    dTHR;
	int i, next_i;
    char * option;
    unsigned int tlen;

    next_i = -1;
    for(i = from_i; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-text") == 0) {
                next_i = i + 1;
                hditem->pszText = SvPV(ST(next_i), tlen);
                hditem->cchTextMax = tlen;
                SwitchFlag(hditem->mask, HDI_TEXT, 1);
                SwitchFlag(hditem->fmt, HDF_STRING, 1);
            } else if(strcmp(option, "-image") == 0) {
                next_i = i + 1;
                hditem->iImage = SvIV(ST(next_i));
                SwitchFlag(hditem->mask, HDI_IMAGE, 1);
                SwitchFlag(hditem->fmt, HDF_IMAGE, 1);
            } else if(strcmp(option, "-bitmap") == 0) {
                next_i = i + 1;
                hditem->hbm = (HBITMAP) handle_From(NOTXSCALL ST(next_i));
                SwitchFlag(hditem->mask, HDI_BITMAP, 1);
                SwitchFlag(hditem->fmt, HDF_BITMAP, 1);
            } else if(strcmp(option, "-bitmaponright") == 0) {
                next_i = i + 1;
                SwitchFlag(hditem->fmt, HDF_BITMAP_ON_RIGHT, SvIV(ST(next_i)));
            } else if(strcmp(option, "-width") == 0) {
                next_i = i + 1;
                hditem->cxy = SvIV(ST(next_i));
                SwitchFlag(hditem->mask, HDI_WIDTH, 1);
                SwitchFlag(hditem->mask, HDI_HEIGHT, 0);
            } else if(strcmp(option, "-height") == 0) {
                next_i = i + 1;
                hditem->cxy = SvIV(ST(next_i));
                SwitchFlag(hditem->mask, HDI_WIDTH, 0);
                SwitchFlag(hditem->mask, HDI_HEIGHT, 1);
            } else if(strcmp(option, "-order") == 0) {
                next_i = i + 1;
                hditem->iOrder = SvIV(ST(next_i));
                SwitchFlag(hditem->mask, HDI_ORDER, 1);
            } else if(strcmp(option, "-align") == 0) {
                next_i = i + 1;
                if(strcmp(SvPV_nolen(ST(next_i)), "left") == 0) {
                    SwitchFlag(hditem->fmt, HDF_LEFT, 1);
                    SwitchFlag(hditem->fmt, HDF_CENTER, 0);
                    SwitchFlag(hditem->fmt, HDF_RIGHT, 0);
                } else if(strcmp(SvPV_nolen(ST(next_i)), "center") == 0) {
                    SwitchFlag(hditem->fmt, HDF_LEFT, 0);
                    SwitchFlag(hditem->fmt, HDF_CENTER, 1);
                    SwitchFlag(hditem->fmt, HDF_RIGHT, 0);
                } else if(strcmp(SvPV_nolen(ST(next_i)), "right") == 0) {
                    SwitchFlag(hditem->fmt, HDF_LEFT, 0);
                    SwitchFlag(hditem->fmt, HDF_CENTER, 0);
                    SwitchFlag(hditem->fmt, HDF_RIGHT, 1);
                } else {
                    if(PL_dowarn) warn("Win32::GUI: Invalid value for -align!");
                }
            } else
            if(strcmp(option, "-item") == 0
            || strcmp(option, "-index") == 0) {
                next_i = i + 1;
                *index = SvIV(ST(next_i));
            }

        } else {
            next_i = -1;
        }
    }
}

    /*
    ###########################################################################
    # (@)INTERNAL:ParseComboboxExItemOptions(sp, mark, ax ,items, from_i, *item)
    */
void ParseComboboxExItemOptions(
    NOTXSPROC
    register SV **sp,
    register SV **mark,
    I32 ax,
    I32 items,
    int from_i,
    COMBOBOXEXITEM *item
) {
    dTHR;
    int i, next_i;
    char * option;
    unsigned int tlen;

    next_i = -1;
    for(i = from_i; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-text") == 0) {
                next_i = i + 1;
                item->pszText = SvPV(ST(next_i), tlen);
                item->cchTextMax = tlen;
                SwitchFlag(item->mask, CBEIF_TEXT, 1);
            } else if(strcmp(option, "-image") == 0) {
                next_i = i + 1;
                item->iImage = SvIV(ST(next_i));
                SwitchFlag(item->mask, CBEIF_IMAGE, 1);
            } else if(strcmp(option, "-selectedimage") == 0) {
                next_i = i + 1;
                item->iSelectedImage = SvIV(ST(next_i));
                SwitchFlag(item->mask, CBEIF_SELECTEDIMAGE, 1);
            } else
            if(strcmp(option, "-item") == 0
            || strcmp(option, "-index") == 0) {
                next_i = i + 1;
                item->iItem = SvIV(ST(next_i));
            }
        } else {
            next_i = -1;
        }
    }
}


    /*
    ###########################################################################
    # (@)PACKAGE:Win32::GUI
    ###########################################################################
     */

MODULE = Win32::GUI     PACKAGE = Win32::GUI

PROTOTYPES: DISABLE


     ##########################################################################
     # (@)INTERNAL:constant(NAME, ARG)
DWORD
constant(name,arg)
    char *name
    int arg
CODE:
    RETVAL = constant(NOTXSCALL name, arg);
OUTPUT:
    RETVAL


     ##########################################################################
     # (@)INTERNAL:LoadLibrary(NAME)
HINSTANCE
LoadLibrary(name)
    char *name;
CODE:
    RETVAL = LoadLibrary(name);
OUTPUT:
    RETVAL

     ##########################################################################
     # (@)INTERNAL:FreeLibrary(LIBRARY)
bool
FreeLibrary(library)
    HINSTANCE library;
CODE:
    RETVAL = FreeLibrary(library);
OUTPUT:
    RETVAL


     ##########################################################################
     # (@)METHOD:GetPerlWindow()
void
GetPerlWindow()
PPCODE:
    char OldPerlWindowTitle[1024];
    char NewPerlWindowTitle[1024];
    HWND hwndFound;
    HINSTANCE hinstanceFound;
    // this is an hack from M$'s Knowledge Base
    // to get the HWND of the console in which
    // Perl is running (and Hide() it :-).
    GetConsoleTitle(OldPerlWindowTitle, 1024);
    wsprintf(NewPerlWindowTitle,
             "PERL-%d-%d",
             GetTickCount(),
             GetCurrentProcessId());

    SetConsoleTitle(NewPerlWindowTitle);
    Sleep(40);
    hwndFound = FindWindow(NULL, NewPerlWindowTitle);

    // another hack to get the program's instance
#ifdef NT_BUILD_NUMBER
    hinstanceFound = GetModuleHandle("GUI.PLL");
#else
    hinstanceFound = GetModuleHandle("GUI.DLL");
#endif
    // hinstanceFound = (HINSTANCE) GetWindowLong(hwndFound, GWL_HINSTANCE);
    // sv_hinstance = perl_get_sv("Win32::GUI::hinstance", TRUE);
    // sv_setiv(sv_hinstance, (IV) hinstanceFound);
    SetConsoleTitle(OldPerlWindowTitle);
    if(GIMME == G_ARRAY) {
        EXTEND(SP, 2);
        XST_mIV(0, (long) hwndFound);
        XST_mIV(1, (long) hinstanceFound);
        XSRETURN(2);
    } else {
        XSRETURN_IV((long) hwndFound);
    }


     ##########################################################################
     # (@)INTERNAL:RegisterClassEx(%OPTIONS)
     # used by new Win32::GUI::Class
void
RegisterClassEx(...)
PPCODE:
    WNDCLASSEX wcx;
    SV* sv_hinstance;
    HINSTANCE hinstance;
    char * option;
    int i, next_i;

    ZeroMemory(&wcx, sizeof(WNDCLASSEX));
    wcx.cbSize = sizeof(WNDCLASSEX);

    wcx.style = CS_HREDRAW | CS_VREDRAW; // TODO (default class style...)
    wcx.cbClsExtra = 0;
    wcx.cbWndExtra = 0;
    wcx.lpfnWndProc = WindowMsgLoop;
#ifdef NT_BUILD_NUMBER
    hinstance = GetModuleHandle("GUI.PLL");
#else
    hinstance = GetModuleHandle("GUI.DLL");
#endif
    wcx.hIcon = LoadIcon(hinstance, MAKEINTRESOURCE(IDI_DEFAULTICON));
    wcx.hIconSm = NULL;
    wcx.hCursor = LoadCursor(NULL, IDC_ARROW);
    wcx.lpszMenuName = NULL;

    for(i = 0; i < items; i++) {
        if(strcmp(SvPV_nolen(ST(i)), "-extends") == 0) {
            next_i = i + 1;
            if(!GetClassInfoEx((HINSTANCE) NULL, (LPCTSTR) SvPV_nolen(ST(next_i)), &wcx)) {
                if(PL_dowarn) warn("Win32::GUI: Class '%s' not found!\n", SvPV_nolen(ST(next_i)));
                XSRETURN_NO;
            }
        }
    }

    next_i = -1;
    for(i = 0; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-name") == 0) {
                next_i = i + 1;
                wcx.lpszClassName = (char *) SvPV_nolen(ST(next_i));
            } else if(strcmp(option, "-color") == 0) {
                next_i = i + 1;
                wcx.hbrBackground = (HBRUSH) SvCOLORREF(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-visual") == 0) {
                next_i = i + 1;
                // -visual => 0 is obsolete
                if(SvIV(ST(next_i)) == 0) {
                    wcx.lpfnWndProc = MsgLoop;
                }
            } else if(strcmp(option, "-widget") == 0) {
                next_i = i + 1;
                if(strcmp(SvPV_nolen(ST(next_i)), "Button") == 0) {
                    DefButtonProc = wcx.lpfnWndProc;
                    wcx.lpfnWndProc = ButtonMsgLoop;
                } else if(strcmp(SvPV_nolen(ST(next_i)), "Listbox") == 0) {
                    DefListboxProc = wcx.lpfnWndProc;
                    wcx.lpfnWndProc = ListboxMsgLoop;
                } else if(strcmp(SvPV_nolen(ST(next_i)), "TabStrip") == 0) {
                    DefTabStripProc = wcx.lpfnWndProc;
                    wcx.lpfnWndProc = TabStripMsgLoop;
                } else if(strcmp(SvPV_nolen(ST(next_i)), "RichEdit") == 0) {
                    DefRichEditProc = wcx.lpfnWndProc;
                    wcx.lpfnWndProc = RichEditMsgLoop;
                } else if(strcmp(SvPV_nolen(ST(next_i)), "Graphic") == 0) {
                    wcx.lpfnWndProc = GraphicMsgLoop;
                } else if(strcmp(SvPV_nolen(ST(next_i)), "InteractiveGraphic") == 0) {
                    wcx.lpfnWndProc = InteractiveGraphicMsgLoop;
                } else if(strcmp(SvPV_nolen(ST(next_i)), "Splitter") == 0) {
                    wcx.lpfnWndProc = SplitterMsgLoop;
                    wcx.hCursor = LoadCursor(hinstance, MAKEINTRESOURCE(IDC_HSPLIT));
                } else if(strcmp(SvPV_nolen(ST(next_i)), "SplitterH") == 0) {
                    wcx.lpfnWndProc = SplitterMsgLoop;
                    wcx.hCursor = LoadCursor(hinstance, MAKEINTRESOURCE(IDC_VSPLIT));
                }
            } else if(strcmp(option, "-style") == 0) {
                next_i = i + 1;
                wcx.style = SvIV(ST(next_i));
            } else if(strcmp(option, "-icon") == 0) {
                next_i = i + 1;
                wcx.hIcon = (HICON) handle_From(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-cursor") == 0) {
                next_i = i + 1;
                wcx.hCursor = (HCURSOR) handle_From(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-menu") == 0) {
                next_i = i + 1;
                wcx.lpszMenuName = (char *) SvPV_nolen(ST(next_i));
            }
        } else {
            next_i = -1;
        }
    }

    // Register the window class.
    if(RegisterClassEx(&wcx)) {
        XSRETURN_YES;
    } else {
        XSRETURN_NO;
    }



     ##########################################################################
     # (@)INTERNAL:CreateWindowEx(%OPTIONS)
     # obsoleted, use Create() instead
void
CreateWindowEx(...)
PPCODE:
    HWND myhandle;
    int i, next_i;
    HWND  hParent;
    HMENU hMenu;
    HINSTANCE hInstance;
    LPVOID pPointer;
    DWORD dwStyle;
    DWORD dwExStyle;
    LPCTSTR szClassname;
    LPCTSTR szText;
    int nX, nY, nWidth, nHeight;
	char * option;

    hParent = NULL;
    hMenu = NULL;
    hInstance = NULL;
    pPointer = NULL;
    dwStyle = 0;
    dwExStyle = 0;
    szText = NULL;

    next_i = -1;
    for(i = 0; i < items; i++) {
        if(next_i == -1) {
			option = SvPV_nolen(ST(i));
            if(strcmp(option, "-exstyle") == 0) {
                next_i = i + 1;
                dwExStyle = (DWORD) SvIV(ST(next_i));
            }
            if(strcmp(option, "-class") == 0) {
                next_i = i + 1;
                szClassname = (LPCTSTR) SvPV_nolen(ST(next_i));
            }
            if(strcmp(option, "-text") == 0
            || strcmp(option, "-title") == 0) {
                next_i = i + 1;
                szText = (LPCTSTR) SvPV_nolen(ST(next_i));
            }
            if(strcmp(option, "-style") == 0) {
                next_i = i + 1;
                dwStyle = (DWORD) SvIV(ST(next_i));
            }

            if(strcmp(option, "-left") == 0) {
                next_i = i + 1;
                nX = (int) SvIV(ST(next_i));
            }
            if(strcmp(option, "-top") == 0) {
                next_i = i + 1;
                nY = (int) SvIV(ST(next_i));
            }
            if(strcmp(option, "-height") == 0) {
                next_i = i + 1;
                nHeight = (int) SvIV(ST(next_i));
            }
            if(strcmp(option, "-width") == 0) {
                next_i = i + 1;
                nWidth = (int) SvIV(ST(next_i));
            }
            if(strcmp(option, "-parent") == 0) {
                next_i = i + 1;
                hParent = (HWND) handle_From(NOTXSCALL ST(next_i));
            }
            if(strcmp(option, "-menu") == 0) {
                next_i = i + 1;
                hMenu = (HMENU) handle_From(NOTXSCALL ST(next_i));
            }
            if(strcmp(option, "-instance") == 0) {
                next_i = i + 1;
                hInstance = (HINSTANCE) SvIV(ST(next_i));
            }
            if(strcmp(option, "-data") == 0) {
                next_i = i + 1;
                pPointer = (LPVOID) SvPV_nolen(ST(next_i));
            }

        } else {
            next_i = -1;
        }
    }
#ifdef PERLWIN32GUI_DEBUG
    printf("XS(CreateWindowEx): Done parsing parameters...\n");
    printf("XS(CreateWindowEx): dwExStyle = %ld\n", dwExStyle);
    printf("XS(CreateWindowEx): szClassname = %s\n", szClassname);
    printf("XS(CreateWindowEx): szText = %s\n", szText);
    printf("XS(CreateWindowEx): dwStyle = %ld\n", dwStyle);
    printf("XS(CreateWindowEx): nX = %d\n", nX);
    printf("XS(CreateWindowEx): nY = %d\n", nY);
    printf("XS(CreateWindowEx): nWidth = %d\n", nWidth);
    printf("XS(CreateWindowEx): nHeight = %d\n", nHeight);
    printf("XS(CreateWindowEx): hParent = %ld\n", hParent);
    printf("XS(CreateWindowEx): hMenu = %ld\n", hMenu);
    printf("XS(CreateWindowEx): hInstance = %ld\n", hInstance);
    printf("XS(CreateWindowEx): pPointer = %ld\n", pPointer);
#endif
    if(myhandle = CreateWindowEx(dwExStyle,
                                 szClassname,
                                 szText,
                                 dwStyle,
                                 nX,
                                 nY,
                                 nWidth,
                                 nHeight,
                                 hParent,
                                 hMenu,
                                 hInstance,
                                 pPointer)) {
        XSRETURN_IV((long) myhandle);
    } else {
        XSRETURN_NO;
    }


    ###########################################################################
    # (@)INTERNAL:Create(%OPTIONS)
    # this is where all the windows are created
void
Create(...)
PPCODE:
    HWND myhandle;
    int first_i;
    PERLWIN32GUI_CREATESTRUCT perlcs;
    int iClass;
    LPVOID pPointer;
    SV* tempsv;
    HV* windows;
    SV* self;
    HV* parent;
    SV** stored;
    SV* storing;
    SV** font;
    char temp[80];
	LPPERLWIN32GUI_USERDATA perlud;
#ifdef PERL_OBJECT
    PerlData *pData;
#endif

    ZeroMemory(&perlcs, sizeof(PERLWIN32GUI_CREATESTRUCT));

    self = newSVsv(ST(0));
    perlcs.hvSelf = (HV*) SvRV(self);
    perlcs.iClass = SvIV(ST(1));
	perlcs.clrForeground = CLR_INVALID;
	perlcs.clrBackground = CLR_INVALID;
    /*
     * #######################################
     * fill the default parameters for classes
     * #######################################
     */
    switch(perlcs.iClass) {
    case WIN32__GUI__WINDOW:
        perlcs.cs.style = WS_OVERLAPPEDWINDOW;
        break;
    case WIN32__GUI__DIALOG:
        perlcs.cs.style = WS_BORDER | DS_MODALFRAME | WS_POPUP | WS_CAPTION | WS_SYSMENU;
        perlcs.cs.dwExStyle = WS_EX_DLGMODALFRAME | WS_EX_WINDOWEDGE
                            | WS_EX_CONTEXTHELP | WS_EX_CONTROLPARENT;
        break;
    case WIN32__GUI__BUTTON:
        perlcs.cs.lpszClass = "BUTTON";
        perlcs.cs.style = WS_VISIBLE | WS_CHILD | BS_PUSHBUTTON;
        break;
    case WIN32__GUI__CHECKBOX:
        perlcs.cs.lpszClass = "BUTTON";
        perlcs.cs.style = WS_VISIBLE | WS_CHILD | BS_AUTOCHECKBOX;
        break;
    case WIN32__GUI__RADIOBUTTON:
        perlcs.cs.lpszClass = "BUTTON";
        perlcs.cs.style = WS_VISIBLE | WS_CHILD | BS_AUTORADIOBUTTON;
        break;
    case WIN32__GUI__GROUPBOX:
        perlcs.cs.lpszClass = "BUTTON";
        perlcs.cs.style = WS_VISIBLE | WS_CHILD | BS_GROUPBOX;
        break;
    case WIN32__GUI__STATIC:
        perlcs.cs.lpszClass = "STATIC";
        perlcs.cs.style = WS_VISIBLE | WS_CHILD | SS_LEFT;
        break;
    case WIN32__GUI__EDIT:
        perlcs.cs.lpszClass = "EDIT";
        perlcs.cs.style = WS_VISIBLE | WS_CHILD | WS_BORDER | ES_LEFT
                        | ES_AUTOHSCROLL | ES_AUTOVSCROLL; // evtl. DS_3DLOOK?
        perlcs.cs.dwExStyle = WS_EX_CLIENTEDGE;
        break;
    case WIN32__GUI__LISTBOX:
        perlcs.cs.lpszClass = "LISTBOX";
        perlcs.cs.style = WS_VISIBLE | WS_CHILD | LBS_NOTIFY;
        perlcs.cs.dwExStyle = WS_EX_CLIENTEDGE;
        break;
    case WIN32__GUI__COMBOBOX:
        perlcs.cs.lpszClass = "COMBOBOX";
        perlcs.cs.style = WS_VISIBLE | WS_CHILD;
        perlcs.cs.dwExStyle = WS_EX_CLIENTEDGE;
        break;
    case WIN32__GUI__PROGRESS:
        perlcs.cs.lpszClass = PROGRESS_CLASS;
        perlcs.cs.style = WS_VISIBLE | WS_CHILD;
        perlcs.cs.dwExStyle = WS_EX_CLIENTEDGE;
        break;
    case WIN32__GUI__STATUS:
        perlcs.cs.lpszClass = STATUSCLASSNAME;
        perlcs.cs.style = WS_VISIBLE | WS_CHILD;
        break;
    case WIN32__GUI__TAB:
        perlcs.cs.lpszClass = WC_TABCONTROL;
        perlcs.cs.style = WS_VISIBLE | WS_CHILD;
        break;
    case WIN32__GUI__TOOLBAR:
        perlcs.cs.lpszClass = TOOLBARCLASSNAME;
        perlcs.cs.style = WS_VISIBLE | WS_CHILD;
        break;
    case WIN32__GUI__LISTVIEW:
        perlcs.cs.lpszClass = WC_LISTVIEW;
        perlcs.cs.style = WS_VISIBLE | WS_CHILD | WS_BORDER | LVS_SHOWSELALWAYS;
        perlcs.cs.dwExStyle = WS_EX_CLIENTEDGE;
        break;
    case WIN32__GUI__TREEVIEW:
        perlcs.cs.lpszClass = WC_TREEVIEW;
        perlcs.cs.style = WS_VISIBLE | WS_CHILD | WS_BORDER | TVS_SHOWSELALWAYS;
        perlcs.cs.dwExStyle = WS_EX_CLIENTEDGE;
        break;
    case WIN32__GUI__RICHEDIT:
        perlcs.cs.lpszClass = "RichEdit";
        perlcs.cs.style = WS_VISIBLE | WS_CHILD | ES_MULTILINE | ES_AUTOHSCROLL | ES_AUTOVSCROLL;
        perlcs.cs.dwExStyle = WS_EX_CLIENTEDGE;
        break;
    case WIN32__GUI__TRACKBAR:
        perlcs.cs.lpszClass = TRACKBAR_CLASS;
        perlcs.cs.style = WS_VISIBLE | WS_CHILD | TBS_AUTOTICKS | TBS_ENABLESELRANGE;
        break;
    case WIN32__GUI__UPDOWN:
        perlcs.cs.lpszClass = UPDOWN_CLASS;
        perlcs.cs.style = WS_VISIBLE | WS_CHILD | UDS_SETBUDDYINT | UDS_AUTOBUDDY | UDS_ALIGNRIGHT;
        break;
    case WIN32__GUI__TOOLTIP:
        perlcs.cs.lpszClass = TOOLTIPS_CLASS;
        perlcs.cs.style = WS_VISIBLE | WS_CHILD | TTS_ALWAYSTIP;
        break;
    case WIN32__GUI__ANIMATION:
        perlcs.cs.lpszClass = ANIMATE_CLASS;
        perlcs.cs.style = WS_VISIBLE | WS_CHILD;
        break;
    case WIN32__GUI__REBAR:
        perlcs.cs.lpszClass = REBARCLASSNAME;
        perlcs.cs.style = WS_VISIBLE | WS_CHILD | WS_CLIPSIBLINGS
                        | WS_CLIPCHILDREN | RBS_VARHEIGHT | CCS_NODIVIDER;
        perlcs.cs.dwExStyle = WS_EX_TOOLWINDOW;
        break;
    case WIN32__GUI__HEADER:
        perlcs.cs.lpszClass = WC_HEADER;
        perlcs.cs.style = WS_VISIBLE | WS_CHILD | HDS_HORZ;
        break;
    case WIN32__GUI__COMBOBOXEX:
        perlcs.cs.lpszClass = WC_COMBOBOXEX;
        perlcs.cs.style = WS_VISIBLE | WS_CHILD;
        break;
    case WIN32__GUI__DTPICK:
        perlcs.cs.lpszClass = DATETIMEPICK_CLASS;
        perlcs.cs.style = WS_VISIBLE | WS_CHILD;
        break;
    case WIN32__GUI__GRAPHIC:
        perlcs.cs.lpszClass = "Win32::GUI::Graphic";
        perlcs.cs.style = WS_VISIBLE | WS_CHILD;
        perlcs.cs.dwExStyle = WS_EX_NOPARENTNOTIFY;
        break;
    case WIN32__GUI__SPLITTER:
        perlcs.cs.lpszClass = "Win32::GUI::Splitter(vertical)";
        perlcs.cs.style = WS_VISIBLE | WS_CHILD;
        perlcs.cs.dwExStyle = WS_EX_NOPARENTNOTIFY;
        break;
    case WIN32__GUI__MDICLIENT:
        perlcs.cs.lpszClass = "MDICLIENT";
        perlcs.cs.style = WS_VISIBLE | WS_CHILD | WS_CLIPCHILDREN | WS_VSCROLL | WS_HSCROLL;
        break;
	}
    first_i = 2;
    if(SvROK(ST(2))) {
        perlcs.cs.hwndParent = (HWND) handle_From(NOTXSCALL ST(2));
        perlcs.hvParent = (HV*) SvRV(ST(2));
        first_i = 3;
    }
    /*
     * ####################
     * options parsing loop
     * ####################
     */
    ParseWindowOptions(NOTXSCALL sp, mark, ax, items, first_i, &perlcs);
    /*
     * ##################################
     * post-processing default parameters
     * ##################################
     */
    switch(perlcs.iClass) {
    case WIN32__GUI__WINDOW:
    case WIN32__GUI__DIALOG:
        if(perlcs.cs.lpszClass == NULL) {
            if(perlcs.szWindowName == NULL) {
                tempsv = perl_get_sv("Win32::GUI::StandardWinClass", FALSE);
                perlcs.cs.lpszClass = classname_From(NOTXSCALL tempsv);
            } else {
                tempsv = perl_get_sv("Win32::GUI::StandardWinClassVisual", FALSE);
                perlcs.cs.lpszClass = classname_From(NOTXSCALL tempsv);
            }
#ifdef PERLWIN32GUI_STRONGDEBUG
	            printf("XS(Create): using class '%s'\n", perlcs.cs.lpszClass);
#endif
        }
        break;
    case WIN32__GUI__BUTTON:
    case WIN32__GUI__CHECKBOX:
    case WIN32__GUI__RADIOBUTTON:
        CalcControlSize(NOTXSCALL &perlcs, 16, 8);
        break;
    case WIN32__GUI__STATIC:
        CalcControlSize(NOTXSCALL &perlcs, 0, 0);
        break;
    }
    /*
     * ###############################
     * default styles for all controls
     * ###############################
     */
    if(perlcs.iClass != WIN32__GUI__WINDOW
    && perlcs.iClass != WIN32__GUI__DIALOG) {
        SwitchFlag(perlcs.cs.style, WS_CHILD, 1);
    }
#ifdef PERLWIN32GUI_STRONGDEBUG
    printf("XS(Create): Done parsing parameters...\n");
    printf("XS(Create): dwExStyle = 0x%x\n", perlcs.cs.dwExStyle);
    printf("XS(Create): szClassname = %s\n", perlcs.cs.lpszClass);
    printf("XS(Create): szName = %s\n", perlcs.cs.lpszName);
    printf("XS(Create): dwStyle = 0x%x\n", perlcs.cs.style);
    printf("XS(Create): nX = %d\n", perlcs.cs.x);
    printf("XS(Create): nY = %d\n", perlcs.cs.y);
    printf("XS(Create): nWidth = %d\n", perlcs.cs.cx);
    printf("XS(Create): nHeight = %d\n", perlcs.cs.cy);
    printf("XS(Create): hParent = %ld\n", perlcs.cs.hwndParent);
    printf("XS(Create): hMenu = %ld\n", perlcs.cs.hMenu);
    printf("XS(Create): hInstance = %ld\n", perlcs.cs.hInstance);
//    printf("XS(Create): pPointer = %ld\n", pPointer);
#endif
    /*
     * #################################
     * prepare the ground for the window
     * #################################
     */
#ifdef PERLWIN32GUI_STRONGDEBUG
		printf("XS(Create): initializing pPointer...\n");
#endif
	Newz(0, perlud, 1, PERLWIN32GUI_USERDATA);
	perlud->dwSize = sizeof(PERLWIN32GUI_USERDATA);
#ifdef PERL_OBJECT
	perlud->pPerl = pPerl;
#endif
	perlud->svSelf = self;
	strcpy( (perlud->szWindowName), perlcs.szWindowName);
	perlud->fDialogUI = 0;
	perlud->iClass = perlcs.iClass;
	perlud->hAcc = perlcs.hAcc;
	perlud->iMinWidth = perlcs.iMinWidth;
	perlud->iMaxWidth = perlcs.iMaxWidth;
	perlud->iMinHeight = perlcs.iMinHeight;
	perlud->iMaxHeight = perlcs.iMaxHeight;
	perlud->clrForeground = perlcs.clrForeground;
	perlud->clrBackground = perlcs.clrBackground;
	perlud->hBackgroundBrush = perlcs.hBackgroundBrush;
	pPointer = perlud;
/*
#ifdef PERL_OBJECT
    pData = NULL;
    if(NULL != (pData = new PerlData)) {
        pData->pPerl = pPerl;
        pData->hvSelf = self;
        pData->lpszName = perlcs.cs.lpszName;
    }
    pPointer = pData;
#else
    pPointer = NULL;
#endif
*/

    /* the following can be vital for the window
     * because as soon as it is created the message
     * loop is activated and data needs to be there
     */
#ifdef PERLWIN32GUI_STRONGDEBUG
	printf("XS(Create): storing -type/-name...\n");
#endif
    storing = newSViv((long) perlcs.iClass);
    stored = hv_store(perlcs.hvSelf, "-type", 5, storing, 0);
   	if(SvMAGICAL(perlcs.hvSelf)) mg_set(storing);
    if(perlcs.szWindowName != NULL) {
        storing = newSVpv((char *)perlcs.szWindowName, 0);
        stored = hv_store(perlcs.hvSelf, "-name", 5, storing, 0);
       	if(SvMAGICAL(perlcs.hvSelf)) mg_set(storing);
    }
    /*
     * ###################################
     * and finally, creation of the window
     * ###################################
     */
#ifdef PERLWIN32GUI_STRONGDEBUG
	printf("XS(Create): calling CreateWindowEx...\n");
#endif
    if(myhandle = CreateWindowEx(
        perlcs.cs.dwExStyle,
        perlcs.cs.lpszClass,
        perlcs.cs.lpszName,
        perlcs.cs.style,
        perlcs.cs.x,
        perlcs.cs.y,
        perlcs.cs.cx,
        perlcs.cs.cy,
        perlcs.cs.hwndParent,
        perlcs.cs.hMenu,
        perlcs.cs.hInstance,
        pPointer
    )) {
        /*
         * ##################################
         * ok, we can fill this object's hash
         * ##################################
         */
#ifdef PERLWIN32GUI_STRONGDEBUG
		printf("XS(Create): succeeded, storing -handle...\n");
#endif
        storing = newSViv((long) myhandle);
        stored = hv_store(perlcs.hvSelf, "-handle", 7, storing, 0);
       	if(SvMAGICAL(perlcs.hvSelf)) mg_set(storing);
        // set the font for the control
#ifdef PERLWIN32GUI_STRONGDEBUG
		printf("XS(Create): storing -font...\n");
#endif
        if(perlcs.hFont != NULL) {
	        storing = newSViv((long) perlcs.hFont);
        	stored = hv_store(perlcs.hvSelf, "-font", 5, storing, 0);
       		if(SvMAGICAL(perlcs.hvSelf)) mg_set(storing);
            SendMessage(myhandle, WM_SETFONT, (WPARAM) perlcs.hFont, 0);
        } else if(perlcs.cs.hwndParent != NULL) {
            font = hv_fetch(perlcs.hvParent, "-font", 5, FALSE);
           	if(SvMAGICAL(perlcs.hvParent)) mg_get(*font);
            if(font != NULL && SvOK(*font)) {
                perlcs.hFont = (HFONT) handle_From(NOTXSCALL *font);
                SendMessage(myhandle, WM_SETFONT, (WPARAM) perlcs.hFont, 0);
            } else {
                perlcs.hFont = (HFONT) GetStockObject(DEFAULT_GUI_FONT);
                SendMessage(myhandle, WM_SETFONT, (WPARAM) perlcs.hFont, 0);
            }
        }
        if(NULL == perlcs.hAcc) {
        	stored = hv_store(perlcs.hvSelf, "-accel", 6, newSViv(0), 0);
       		if(SvMAGICAL(perlcs.hvSelf)) mg_set(storing);
		}
        /*
         * ##################################
         * store the child in the parent hash
         * ##################################
         */
#ifdef PERLWIN32GUI_STRONGDEBUG
		printf("XS(Create): storing object in parent...\n");
#endif
        if(perlcs.hvParent != NULL && perlcs.szWindowName != NULL) {
	        storing = self;
        	stored = hv_store(perlcs.hvParent, perlcs.szWindowName, strlen(perlcs.szWindowName), storing, 0);
        	if(SvMAGICAL(perlcs.hvParent)) mg_set(storing);
        }
        /*
         * #####################################################
         * other post-creation class-specific initializations...
         * #####################################################
         */
#ifdef PERLWIN32GUI_STRONGDEBUG
		printf("XS(Create): finalizing...\n");
#endif
        switch(perlcs.iClass) {
        case WIN32__GUI__STATIC:
            if(perlcs.hImageList != NULL) {
				if(perlcs.cs.style & SS_ICON) {
					SendMessage(
						myhandle,
						STM_SETIMAGE,
						(WPARAM) IMAGE_ICON,
						(LPARAM) perlcs.hImageList
					);
				} else {
					SendMessage(
						myhandle,
						STM_SETIMAGE,
						(WPARAM) IMAGE_BITMAP,
						(LPARAM) perlcs.hImageList
					);
				}
			}
            break;
        case WIN32__GUI__BUTTON:
            if(perlcs.hImageList != NULL) {
				if(perlcs.cs.style & BS_ICON) {
					SendMessage(
						myhandle,
						BM_SETIMAGE,
						(WPARAM) IMAGE_ICON,
						(LPARAM) perlcs.hImageList
					);
				} else {
					SendMessage(
						myhandle,
						BM_SETIMAGE,
						(WPARAM) IMAGE_BITMAP,
						(LPARAM) perlcs.hImageList
					);
				}
			}
            break;
        case WIN32__GUI__TOOLBAR:
            SendMessage(myhandle, TB_BUTTONSTRUCTSIZE, (WPARAM) sizeof(TBBUTTON), 0);
            /* SendMessage(myhandle, TB_SETIMAGELIST, 0, (LPARAM) perlcs.hImageList); */
            break;
        case WIN32__GUI__TAB:
            if(perlcs.hImageList != NULL)
                TabCtrl_SetImageList(myhandle, perlcs.hImageList);
            break;
        case WIN32__GUI__LISTVIEW:
            if(perlcs.hImageList != NULL) {
                ListView_SetImageList(myhandle, perlcs.hImageList, LVSIL_NORMAL);
                ListView_SetImageList(myhandle, perlcs.hImageList, LVSIL_SMALL);
			}
            ListView_SetExtendedListViewStyle(myhandle, perlcs.cs.dwExStyle);
            break;
        case WIN32__GUI__TREEVIEW:
            if(perlcs.hImageList != NULL)
                TreeView_SetImageList(myhandle, perlcs.hImageList, TVSIL_NORMAL);
            // TODO: later we'll cope with TVSIL_STATE too...
            break;
        case WIN32__GUI__REBAR:
            {
                // initialize and send the REBARINFO structure.
                REBARINFO rbi;
                rbi.cbSize = sizeof(REBARINFO);
                if(perlcs.hImageList != NULL) {
                    rbi.fMask = RBIM_IMAGELIST;
                    rbi.himl = perlcs.hImageList;
                } else {
                    rbi.fMask = 0;
                    rbi.himl = NULL;
                }
                SendMessage(myhandle, RB_SETBARINFO, 0, (LPARAM) &rbi);
            }
            break;
        case WIN32__GUI__COMBOBOXEX:
            if(perlcs.hImageList != NULL) {
                SendMessage(myhandle, CBEM_SETIMAGELIST, 0, (LPARAM) perlcs.hImageList);
				SetWindowPos(
					myhandle, (HWND) NULL,
					perlcs.cs.x, perlcs.cs.y, perlcs.cs.cx, perlcs.cs.cy,
					SWP_NOZORDER | SWP_NOOWNERZORDER
				);
			}
            break;
		}
        /*
         * ###########################################################
         * store a pointer to the Perl object in the window's USERDATA
         * ###########################################################
         */
/*
#ifdef PERLWIN32GUI_STRONGDEBUG
		printf("XS(Create): doing SetWindowLong(pData)...\n");
#endif
#ifdef PERL_OBJECT
        pData->pPerl = pPerl;
        pData->hvSelf = self;
        pData->lpszName = perlcs.cs.lpszName;
        SetWindowLong(myhandle, GWL_USERDATA, (long) pData);
#else
        SetWindowLong(myhandle, GWL_USERDATA, (long) self);
#endif
*/
		if(perlcs.iClass != WIN32__GUI__WINDOW
		&& perlcs.iClass != WIN32__GUI__DIALOG) {
#ifdef PERLWIN32GUI_STRONGDEBUG
			printf("XS(Create): doing SetWindowLong...\n");
#endif
			/*
			 * POSSIBLE PROBLEM HERE:
			 * since we don't provide a MsgLoop function
			 * for each control, we can't control WM_DESTROY
			 * to deallocate memory perl our USERDATA structure.
			 */
			SetWindowLong(myhandle, GWL_USERDATA, (long) perlud);
		}
        XSRETURN_IV((long) myhandle);
    } else {
#ifdef PERLWIN32GUI_STRONGDEBUG
		printf("XS(Create): failed, returning undef\n");
#endif
        XSRETURN_NO;
    }


    ###########################################################################
    # (@)METHOD:Change(HANDLE, %OPTIONS)
    # Change most of the options used when the object was created.
void
Change(...)
PPCODE:
    HWND handle;
    PERLWIN32GUI_CREATESTRUCT perlcs;
    int visibleSeen;
    SV** tempsv;
    HV* windows;
    HV* hash;
    char temp[80];

    handle = (HWND) handle_From(NOTXSCALL ST(0));
#ifdef PERLWIN32GUI_STRONGDEBUG
    printf("XS(Change): handle=%ld\n", handle);
#endif
#ifdef PERLWIN32GUI_STRONGDEBUG
    printf("XS(Change): items=%d\n", items);
#endif
    ZeroMemory(&perlcs, sizeof(PERLWIN32GUI_CREATESTRUCT));

    perlcs.hvSelf = HV_SELF_FROM_WINDOW(handle);
    if(perlcs.hvSelf != NULL) {
        /*
         * #####################
         * retrieve windows data
         * #####################
         */
        tempsv = hv_fetch(perlcs.hvSelf, "-type", 5, 0);
        if(SvMAGICAL(perlcs.hvSelf)) mg_get(*tempsv);
        if(tempsv == NULL) {
            perlcs.iClass = 0;
        } else {
            perlcs.iClass = SvIV(*tempsv);
        }
#ifdef PERLWIN32GUI_STRONGDEBUG
	    printf("XS(Change): iClass=%d\n", perlcs.iClass);
#endif
        tempsv = hv_fetch(perlcs.hvSelf, "-backgroundbrush", 16, 0);
        if(SvMAGICAL(perlcs.hvSelf)) mg_get(*tempsv);
        if(tempsv == NULL) {
            perlcs.hBackgroundBrush = NULL;
        } else {
            perlcs.hBackgroundBrush = (HBRUSH) SvIV(*tempsv);
        }
#ifdef PERLWIN32GUI_STRONGDEBUG
	    printf("XS(Change): hBackgroundBrush=%ld\n", perlcs.hBackgroundBrush);
#endif
        perlcs.cs.style = GetWindowLong(handle, GWL_STYLE);
        perlcs.cs.dwExStyle = GetWindowLong(handle, GWL_EXSTYLE);
        /*
         * ########################
         * parse new window options
         * ########################
         */
        ParseWindowOptions(NOTXSCALL sp, mark, ax, items, 1, &perlcs);
        /*
         * ###############################
         * default styles for all controls
         * ###############################
         */
        if(perlcs.iClass != WIN32__GUI__WINDOW
        && perlcs.iClass != WIN32__GUI__DIALOG) {
            SwitchFlag(perlcs.cs.style, WS_CHILD, 1);
        }
#ifdef PERLWIN32GUI_STRONGDEBUG
        printf("XS(Change): Done parsing parameters...\n");
        printf("XS(Change): dwExStyle = 0x%x\n", perlcs.cs.dwExStyle);
        printf("XS(Change): szClassname = %s\n", perlcs.cs.lpszClass);
        printf("XS(Change): szName = %s\n", perlcs.cs.lpszName);
        printf("XS(Change): dwStyle = 0x%x\n", perlcs.cs.style);
        printf("XS(Change): nX = %d\n", perlcs.cs.x);
        printf("XS(Change): nY = %d\n", perlcs.cs.y);
        printf("XS(Change): nWidth = %d\n", perlcs.cs.cx);
        printf("XS(Change): nHeight = %d\n", perlcs.cs.cy);
        printf("XS(Change): hParent = %ld\n", perlcs.cs.hwndParent);
        printf("XS(Change): hMenu = %ld\n", perlcs.cs.hMenu);
        printf("XS(Change): hInstance = %ld\n", perlcs.cs.hInstance);
#endif
        /*
         * ###############
         * Perform changes
         * ###############
         */
        if(perlcs.cs.lpszName != NULL)
            SetWindowText(handle, perlcs.cs.lpszName);
        SetWindowLong(handle, GWL_STYLE, perlcs.cs.style);
        SetWindowLong(handle, GWL_EXSTYLE, perlcs.cs.dwExStyle);
        if(perlcs.cs.x != 0 || perlcs.cs.y != 0)
            SetWindowPos(handle, (HWND) NULL, perlcs.cs.x, perlcs.cs.y, 0, 0,
                                 SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOSIZE);
        if(perlcs.cs.cx != 0 || perlcs.cs.cy != 0)
            SetWindowPos(handle, (HWND) NULL, 0, 0, perlcs.cs.cx, perlcs.cs.cy,
                                 SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOMOVE);
        if(perlcs.cs.hMenu != NULL)
            SetMenu(handle, perlcs.cs.hMenu);
        if(perlcs.iClass == WIN32__GUI__LISTVIEW)
            ListView_SetExtendedListViewStyle(handle, perlcs.cs.dwExStyle);
/* TODO: change class ???
		if(perlcs.cs.iClass != NULL)
        	SetWindowLong(handle, GWL_
*/
        XSRETURN_YES;
    } else {
        XSRETURN_NO;
    }

    ###########################################################################
    # (@)METHOD:Dialog()
DWORD
Dialog(hwnd=NULL)
	HWND hwnd
PREINIT:
    MSG msg;
    HWND phwnd;
    HWND thwnd;
    SV** tempsv;
    HV* self;
    int stayhere;
    BOOL fIsDialog;
    HACCEL acc;
    LPPERLWIN32GUI_USERDATA perlud;
CODE:
    stayhere = 1;
    fIsDialog = FALSE;
    while (stayhere) {

		ENTER;
		SAVETMPS;

        stayhere = GetMessage(&msg, hwnd, 0, 0);
#ifdef PERLWIN32GUI_STRONGDEBUG
        printf("XS(Dialog): GetMessage returned %d\n", stayhere);
#endif
        if(msg.message == WM_EXITLOOP) {
            stayhere = 0;
            msg.wParam = -1;
        } else {
            if(stayhere == -1) {
                stayhere = 0;
                msg.wParam = -2; // an error occurred...
            } else {
                // trace back to the window's parent
                phwnd = msg.hwnd;
                while(thwnd = GetParent(phwnd)) {
                    phwnd = thwnd;
                }
                // now see if the parent window is a DialogBox
                fIsDialog = FALSE;
                acc = NULL;
				perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLong(phwnd, GWL_USERDATA);
                /*
                self = HV_SELF_FROM_WINDOW(phwnd);
                */
                if(perlud != NULL && perlud->dwSize == sizeof(PERLWIN32GUI_USERDATA)) {
                    /*
                    // was: tempsv = hv_fetch(self, "-type", 5, FALSE);
                    tempsv = hv_fetch(self, "-dialogui", 9, FALSE);
           			if(SvMAGICAL(self)) mg_get(*tempsv);
                    if(tempsv != NULL) {
                        // was: if(SvIV(*tempsv) == WIN32__GUI__DIALOG) {
                        if(SvIV(*tempsv)) {
                            fIsDialog = TRUE;
                        }
                    }
                    */
                    fIsDialog = perlud->fDialogUI;

                    /*
                    tempsv = hv_fetch(self, "-accel", 6, FALSE);
           			if(SvMAGICAL(self)) mg_get(*tempsv);
                    if(tempsv != NULL) {
                        acc = (HACCEL) SvIV(*tempsv);
                    }
                    */
                    acc = perlud->hAcc;
                }
                if(fIsDialog) {
					if(acc != NULL) {
						if(!TranslateAccelerator(phwnd, acc, &msg)) {
							if(!IsDialogMessage(phwnd, &msg)) {
								TranslateMessage(&msg);
								DispatchMessage(&msg);
							}
						}
					} else {
						if(!IsDialogMessage(phwnd, &msg)) {
							TranslateMessage(&msg);
							DispatchMessage(&msg);
						}
					}
                } else {
					if(acc != NULL) {
						if(!TranslateAccelerator(phwnd, acc, &msg)) {
	                    	TranslateMessage(&msg);
	                    	DispatchMessage(&msg);
						}
					} else {
						TranslateMessage(&msg);
						DispatchMessage(&msg);
					}
                }
            }
        }

        FREETMPS;
        LEAVE;

    }
	RETVAL = msg.wParam;
OUTPUT:
	RETVAL


    ###########################################################################
    # (@)METHOD:DoEvents()
DWORD
DoEvents(hwnd=NULL)
	HWND hwnd
PREINIT:
    MSG msg;
    HWND phwnd;
    HWND thwnd;
    SV** tempsv;
    HV* self;
    int stayhere;
    BOOL fIsDialog;
    HACCEL acc;
CODE:
	stayhere = 1;
    fIsDialog = FALSE;
    while(stayhere) {
        stayhere = PeekMessage(&msg, hwnd, 0, 0, PM_REMOVE);
#ifdef PERLWIN32GUI_STRONGDEBUG
        printf("XS(DoEvents): PeekMessage returned %d\n", stayhere);
#endif
        if(msg.message == WM_EXITLOOP) {
            stayhere = 0;
            msg.wParam = -1;
        } else {
            if(stayhere == -1) {
                stayhere = 0;
                msg.wParam = -2; // an error occurred...
            } else {
                // trace back to the window's parent
                phwnd = msg.hwnd;
                while(thwnd = GetParent(phwnd)) {
                    phwnd = thwnd;
                }
                // now see if the parent window is a DialogBox
                fIsDialog = FALSE;
                self = HV_SELF_FROM_WINDOW(phwnd);
                if(self != NULL) {
                    // was: type = hv_fetch(self, "-type", 5, FALSE);
                    tempsv = hv_fetch(self, "-dialogui", 9, FALSE);
           			if(SvMAGICAL(self)) mg_get(*tempsv);
                    if(tempsv != NULL) {
                        // was: if(SvIV(*type) == WIN32__GUI__DIALOG) {
                        if(SvIV(*tempsv)) {
                            fIsDialog = TRUE;
                        }
                    }
                    tempsv = hv_fetch(self, "-accel", 6, FALSE);
           			if(SvMAGICAL(self)) mg_get(*tempsv);
                    if(tempsv != NULL) {
                        acc = (HACCEL) SvIV(*tempsv);
                    }
                }
                if(fIsDialog) {
					if(acc != NULL) {
						if(!TranslateAccelerator(phwnd, acc, &msg)) {
							if(!IsDialogMessage(phwnd, &msg)) {
								TranslateMessage(&msg);
								DispatchMessage(&msg);
							}
						}
					} else {
						if(!IsDialogMessage(phwnd, &msg)) {
							TranslateMessage(&msg);
							DispatchMessage(&msg);
						}
					}
                } else {
					if(acc != NULL) {
						if(!TranslateAccelerator(phwnd, acc, &msg)) {
	                    	TranslateMessage(&msg);
	                    	DispatchMessage(&msg);
						}
					} else {
						TranslateMessage(&msg);
						DispatchMessage(&msg);
					}
                }
            }
        }
    }
    RETVAL = msg.wParam;
OUTPUT:
	RETVAL

    ###########################################################################
    # (@)INTERNAL:oldDialog()
DWORD
oldDialog(...)
PPCODE:
    HWND hwnd;
    MSG msg;
    int stayhere;
    stayhere = 1;

    if(items > 0) {
        hwnd = (HWND) handle_From(NOTXSCALL ST(0));
    } else {
        hwnd = NULL;
    }

    while (stayhere) {
        stayhere = GetMessage(&msg, hwnd, 0, 0);
        if(msg.message == WM_EXITLOOP) {
            stayhere = 0;
            msg.wParam = -1;
        } else {
            if(stayhere == -1) {
                stayhere = 0;
                msg.wParam = -2; // an error occurred...
            } else {
                // result = GetMessage(&msg, (HWND) handle_From(NOTXSCALL ST(0)), 0, 0);
                TranslateMessage(&msg);
                DispatchMessage(&msg);
            }
        }
    }
    XSRETURN_IV((long) msg.wParam);


    ###########################################################################
    # (@)INTERNAL:LoadCursorFromFile(FILENAME)
HCURSOR
LoadCursorFromFile(filename)
    LPCTSTR filename
CODE:
    RETVAL = LoadCursorFromFile(filename);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:LoadImage(FILENAME, [TYPE, X, Y, FLAGS])
HBITMAP
LoadImage(filename,iType=IMAGE_BITMAP,iX=0,iY=0,iFlags=LR_LOADFROMFILE)
    LPCTSTR filename
    UINT iType
    int iX
    int iY
    UINT iFlags
CODE:
    RETVAL = LoadImage((HINSTANCE) NULL, filename, iType, iX, iY, iFlags);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)INTERNAL:DestroyIcon()
BOOL
DestroyIcon(icon)
    HICON icon
CODE:
    RETVAL = DestroyIcon(icon);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:DestroyCursor()
BOOL
DestroyCursor(cursor)
    HCURSOR cursor
CODE:
    RETVAL = DestroyCursor(cursor);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetCursor(CURSOR)
HCURSOR
SetCursor(cursor)
    HCURSOR cursor
CODE:
    RETVAL = SetCursor(cursor);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetCursor()
	# Returns the handle of the current cursor.
HCURSOR
GetCursor()
CODE:
    RETVAL = GetCursor();
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ChangeCursor(CURSOR)
HCURSOR
ChangeCursor(handle, cursor)
	HWND handle
    HCURSOR cursor
CODE:
    RETVAL = (HCURSOR) SetClassLong(handle, GCL_HCURSOR, (LONG) cursor);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:ChangeIcon(ICON)
	# Changes the default icon for a window to ICON (a Win32::GUI::Icon
	# object). Returns the handle of the previous default icon.
HICON
ChangeIcon(handle, icon)
	HWND handle
    HICON icon
CODE:
    SetClassLong(handle, GCL_HICONSM, (LONG) icon);
	RETVAL = (HICON) SetClassLong(handle, GCL_HICON, (LONG) icon);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:ChangeSmallIcon(ICON)
	# Changes the default small icon for a window to ICON (a Win32::GUI::Icon
	# object). Returns the handle of the previous default small icon.
HICON
ChangeSmallIcon(handle, icon)
	HWND handle
    HICON icon
CODE:
    RETVAL = (HICON) SetClassLong(handle, GCL_HICONSM, (LONG) icon);
OUTPUT:
    RETVAL


	###########################################################################
    # (@)METHOD:GetClassName()
    # Returns the classname of the specified window (undef on errors).
	# See new Win32::GUI::Class.
void
GetClassName(handle)
    HWND handle
PREINIT:
    LPTSTR lpClassName;
    int nMaxCount;
PPCODE:
    nMaxCount = 256;
    lpClassName = (LPTSTR) safemalloc(nMaxCount);
    if(GetClassName(handle, lpClassName, nMaxCount) > 0) {
        EXTEND(SP, 1);
        XST_mPV(0, lpClassName);
        safefree(lpClassName);
        XSRETURN(1);
    } else {
        safefree(lpClassName);
        XSRETURN_NO;
    }


    ###########################################################################
    # (@)METHOD:FindWindow(CLASSNAME, WINDOWNAME)
    # Returns the handle of the window whose class name and window name match
    # the specified strings; both strings can be empty. Note that the function
    # does not search child windows, only top level windows.
    # If no matching windows is found, the return value is zero.
HWND
FindWindow(classname,windowname)
    LPCTSTR classname
    LPCTSTR windowname
CODE:
    if(strlen(classname) == 0) classname = NULL;
    if(strlen(windowname) == 0) windowname = NULL;
    RETVAL = FindWindow(classname, windowname);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetWindowLong(INDEX)
	# Retrieves a windows property; for more info consult the original API
	# documentation.
LONG
GetWindowLong(handle,index)
    HWND handle
    int index
CODE:
    RETVAL = GetWindowLong(handle, index);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:SetWindowLong(INDEX, VALUE)
	# Sets a windows property; for more info consult the original API
	# documentation.
LONG
SetWindowLong(handle,index,value)
    HWND handle
    int  index
    LONG value
CODE:
    RETVAL = SetWindowLong(handle, index, value);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetWindow(COMMAND)
    # Returns handle of the window that has the specified
    # relationship (given by COMMAND) with the specified window.
    # Available COMMANDs are:
    #   GW_CHILD
    #   GW_HWNDFIRST
    #   GW_HWNDLAST
    #   GW_HWNDNEXT
    #   GW_HWNDPREV
    #   GW_OWNER
    #
    # Example:
    #     $Button->GetWindow(GW_OWNER);
HWND
GetWindow(handle,command)
    HWND handle
    UINT command
CODE:
    RETVAL = GetWindow(handle, command);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Show([COMMAND])
    # Shows a window (or change its showing state to COMMAND); available
    # COMMANDs are:
    #   SW_HIDE
    #   SW_MAXIMIZE
    #   SW_MINIMIZE
    #   SW_RESTORE
    #   SW_SHOW
    #   SW_SHOWDEFAULT
    #   SW_SHOWMAXIMIZED
    #   SW_SHOWMINIMIZED
    #   SW_SHOWMINNOACTIVE
    #   SW_SHOWNA
    #   SW_SHOWNOACTIVATE
    #   SW_SHOWNORMAL
    # The default COMMAND, if none specified, is SW_SHOWNORMAL.
BOOL
Show(handle,command=SW_SHOWNORMAL)
    HWND handle
    int command
CODE:
    RETVAL = ShowWindow(handle, command);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Hide()
    # Hides a window.
BOOL
Hide(handle)
    HWND handle
CODE:
    RETVAL = ShowWindow(handle, SW_HIDE);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Maximize()
    # Maximizes a window.
BOOL
Maximize(handle)
    HWND handle
CODE:
    RETVAL = ShowWindow(handle, SW_SHOWMAXIMIZED);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Update()
    # Refreshes the content of a window.
BOOL
Update(handle)
    HWND handle
CODE:
    RETVAL = UpdateWindow(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:InvalidateRect(...)
    # Forces a refresh of a window, or a rectangle of it.
    # The parameters can be (FLAG) for the whole area of the window,
    # or (LEFT, TOP, RIGHT, BOTTOM, [FLAG]) to specify a rectangle.
    # If the FLAG parameter is set to TRUE, the background is erased before the
    # window is refreshed (this is the default).
BOOL
InvalidateRect(handle, ...)
    HWND handle
PREINIT:
    RECT rect;
    LPRECT lpRect;
    BOOL bErase;
CODE:
    if(items != 2 && items && items != 6) {
        CROAK("Usage: InvalidateRect(handle, flag);\n   or: InvalidateRect(handle, left, top, right, bottom, [flag]);\n");
    }
    if(items == 2) {
        lpRect = (LPRECT) NULL;
        bErase = (BOOL) SvIV(ST(1));
    } else {
        rect.left   = SvIV(ST(1));
        rect.top    = SvIV(ST(2));
        rect.right  = SvIV(ST(3));
        rect.bottom = SvIV(ST(4));
        if(items == 5)
            bErase      = TRUE;
        else
            bErase      = (BOOL) SvIV(ST(5));
        lpRect      = &rect;
    }
    RETVAL = InvalidateRect(handle, lpRect, bErase);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:DestroyWindow()
BOOL
DestroyWindow(handle)
    HWND handle
CODE:
    RETVAL = DestroyWindow(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetMessage([MIN, MAX])
    # Retrieves a message sent to the window, optionally considering only
    # messages identifiers in the range MIN..MAX; if a message is found, the
    # function returns a 7 elements array containing:
    #   - the result code of the message
    #   - the message identifier
    #   - the wParam argument
    #   - the lParam argument
    #   - the time when message occurred
    #   - the x coordinate at which message occurred
    #   - the y coordinate at which message occurred
    # If the result code of the message was -1 the function returns undef.
    # Note that this function should not be normally used unless you know
    # very well what you're doing.
void
GetMessage(handle,min=0,max=0)
    HWND handle
    UINT min
    UINT max
PREINIT:
    MSG msg;
    BOOL result;
PPCODE:
    result = GetMessage(&msg, handle, min, max);
    if(result == -1) {
        XSRETURN_NO;
    } else {
        EXTEND(SP, 7);
        XST_mIV(0, result);
        XST_mIV(1, msg.message);
        XST_mIV(2, msg.wParam);
        XST_mIV(3, msg.lParam);
        XST_mIV(4, msg.time);
        XST_mIV(5, msg.pt.x);
        XST_mIV(6, msg.pt.y);
        XSRETURN(7);
    }


    ###########################################################################
    # (@)METHOD:GetCursorPos()
    # Returns a two elements array containing the x and y position of the
    # cursor, or undef on errors.
void
GetCursorPos()
PREINIT:
    POINT point;
PPCODE:
    if(GetCursorPos(&point)) {
        EXTEND(SP, 2);
        XST_mIV(0, point.x);
        XST_mIV(1, point.y);
        XSRETURN(2);
    } else {
        XSRETURN_NO;
    }

    ###########################################################################
    # (@)METHOD:SetCursorPos(X, Y)
    # Moves the cursor to the specified coordinates.
BOOL
SetCursorPos(x, y)
	int x
	int y
CODE:
    RETVAL = SetCursorPos(x, y);
OUTPUT:
	RETVAL

    ###########################################################################
    # (@)METHOD:ClipCursor([LEFT, TOP, RIGHT, BOTTOM])
BOOL
ClipCursor(left=0, top=0, right=0, bottom=0)
	LONG left
	LONG top
	LONG right
	LONG bottom
PREINIT:
	RECT r;
CODE:
	if(items == 0) {
	    RETVAL = ClipCursor(NULL);
	} else {
		r.left = left;
		r.top = top;
		r.right = right;
		r.bottom = bottom;
		RETVAL = ClipCursor(&r);
	}
OUTPUT:
	RETVAL


    ###########################################################################
    # (@)METHOD:SendMessage(MSG, WPARAM, LPARAM)
    # Sends a message to a window.
LRESULT
SendMessage(handle,msg,wparam,lparam)
    HWND handle
    UINT msg
    WPARAM wparam
    LPARAM lparam
CODE:
    RETVAL = SendMessage(handle, msg, wparam, lparam);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:PostMessage(MSG, WPARAM, LPARAM)
    # Posts a message to a window.
LRESULT
PostMessage(handle,msg,wparam,lparam)
    HWND handle
    UINT msg
    WPARAM wparam
    LPARAM lparam
CODE:
    RETVAL = PostMessage(handle, msg, wparam, lparam);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:SendMessageTimeout(MSG, WPARAM, LPARAM, [FLAGS], TIMEOUT)
    # Sends a message to a window and wait for it to be processed or until the
    # specified TIMEOUT (number of milliseconds) elapses; returns the result
    # code of the processed message or undef on errors.
    # If undef is returned and a call to Win32::GetLastError() returns 0,
    # then the window timed out processing the message.
    # The FLAGS parameter is optional, possible values are:
    #  0 SMTO_NORMAL
    #    (the calling thread can process other requests while waiting;
    #    this is the default setting)
    #  1 SMTO_BLOCK
    #    (the calling thread does not process other requests)
    #  2 SMTO_ABORTIFHUNG
    #    (returns without waiting if the receiving process seems to be "hung")
void
SendMessageTimeout(handle,msg,wparam,lparam,flags=SMTO_NORMAL,timeout)
    HWND handle
    UINT msg
    WPARAM wparam
    LPARAM lparam
    UINT flags
    UINT timeout
PREINIT:
    DWORD result;
PPCODE:
    if(SendMessageTimeout(
        handle, msg, wparam, lparam, flags, timeout, &result
    ) == 0) {
        XSRETURN_NO;
    } else {
        XSRETURN_IV(result);
    }


    ###########################################################################
    # (@)METHOD:PostQuitMessage([EXITCODE])
    # Sends a quit message to a window, optionally with an EXITCODE;
    # if no EXITCODE is given, it defaults to 0.
void
PostQuitMessage(...)
PPCODE:
    int exitcode;
    if(items > 0)
        exitcode = SvIV(ST(items-1));
    else
        exitcode = 0;
    PostQuitMessage(exitcode);


    ###########################################################################
    # (@)METHOD:PeekMessage([MIN, MAX, MESSAGE])
    # Inspects the window's message queue and eventually returns data
    # about the message it contains; it can optionally check only for message
    # identifiers in the range MIN..MAX; the last MESSAGE parameter, if
    # specified, must be an array reference.
    # If a message is found, the function puts in that array 7 elements
    # containing:
    #   - the handle of the window to which the message is addressed
    #   - the message identifier
    #   - the wParam argument
    #   - the lParam argument
    #   - the time when message occurs
    #   - the x coordinate at which message occurs
    #   - the y coordinate at which message occurs
    #
BOOL
PeekMessage(handle, min=0, max=0, message=&PL_sv_undef)
    HWND handle
    UINT min
    UINT max
    SV* message
PREINIT:
    MSG msg;
CODE:
    ZeroMemory(&msg, sizeof(msg));
    RETVAL = PeekMessage(&msg, handle, min, max, PM_NOREMOVE);
    if(message != &PL_sv_undef && SvROK(message)) {
        if(SvTYPE(SvRV(message)) == SVt_PVAV) {
            av_clear((AV*) SvRV(message));
            av_push((AV*) SvRV(message), sv_2mortal(newSViv((long) msg.hwnd)));
            av_push((AV*) SvRV(message), sv_2mortal(newSViv(msg.message)));
            av_push((AV*) SvRV(message), sv_2mortal(newSViv(msg.wParam)));
            av_push((AV*) SvRV(message), sv_2mortal(newSViv(msg.lParam)));
            av_push((AV*) SvRV(message), sv_2mortal(newSViv(msg.time)));
            av_push((AV*) SvRV(message), sv_2mortal(newSViv(msg.pt.x)));
            av_push((AV*) SvRV(message), sv_2mortal(newSViv(msg.pt.y)));
        } else {
            if(PL_dowarn) warn("Win32::GUI: fourth parameter to PeekMessage is not an array reference");
        }
    }
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Text([TEXT])
    # Gets or sets the text of a window.

    # (@)METHOD:Caption([TEXT])
    # See Text().
void
Text(handle,...)
    HWND handle
ALIAS:
    Win32::GUI::Caption = 1
PREINIT:
    char *myBuffer;
    int myLength;
PPCODE:
    if(items > 2) {
        CROAK("Usage: Text(handle, [value]);\n");
    }
    if(items == 1) {
        myLength = GetWindowTextLength(handle)+1;
        if(myLength) {
            myBuffer = (char *) safemalloc(myLength);
            if(GetWindowText(handle, myBuffer, myLength)) {
                EXTEND(SP, 1);
                XST_mPV(0, myBuffer);
                safefree(myBuffer);
                XSRETURN(1);
            }
            safefree(myBuffer);
        }
        XSRETURN_NO;
    } else {
        XSRETURN_IV((long) SetWindowText(handle, (LPCTSTR) SvPV_nolen(ST(1))));
    }


    ###########################################################################
    # (@)METHOD:Move(X, Y)
    # Moves the window to the specified position.
BOOL
Move(handle,x,y)
    HWND handle
    int x
    int y
CODE:
    RETVAL = SetWindowPos(handle, (HWND) NULL, x, y, 0, 0,
                          SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOSIZE);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Resize(X, Y)
    # Resizes the window to the specified dimension.
BOOL
Resize(handle,x,y)
    HWND handle
    int x
    int y
CODE:
    RETVAL = SetWindowPos(handle, (HWND) NULL, 0, 0, x, y,
                          SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOMOVE);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetClientRect()
void
GetClientRect(handle)
    HWND handle
PREINIT:
    RECT myRect;
PPCODE:
    if(GetClientRect(handle, &myRect)) {
        EXTEND(SP, 4);
        XST_mIV(0, myRect.left);
        XST_mIV(1, myRect.top);
        XST_mIV(2, myRect.right);
        XST_mIV(3, myRect.bottom);
        XSRETURN(4);
    } else {
        XSRETURN_NO;
    }


    ###########################################################################
    # (@)METHOD:GetWindowRect()
void
GetWindowRect(handle)
    HWND handle
PREINIT:
    RECT myRect;
PPCODE:
    if(GetWindowRect(handle, &myRect)) {
        EXTEND(SP, 4);
        XST_mIV(0, myRect.left);
        XST_mIV(1, myRect.top);
        XST_mIV(2, myRect.right);
        XST_mIV(3, myRect.bottom);
        XSRETURN(4);
    } else {
        XSRETURN_NO;
    }


    ###########################################################################
    # (@)METHOD:Width([WIDTH])
    # Gets or sets the window width.
void
Width(handle,...)
    HWND handle
PREINIT:
    RECT myRect;
PPCODE:
    if(items > 2) {
        croak("Usage: Width(handle, [value]);\n");
    }

    if(!GetWindowRect(handle, &myRect)) XSRETURN_NO;

    if(items == 1) {
        EXTEND(SP, 1);
        XST_mIV(0, (myRect.right-myRect.left));
        XSRETURN(1);
    } else {
        if(SetWindowPos(handle, (HWND) NULL, 0, 0,
                        (int) SvIV(ST(1)),
                        (int) (myRect.bottom-myRect.top),
                        SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOMOVE)) {
            XSRETURN_YES;
        } else {
            XSRETURN_NO;
        }
    }


    ###########################################################################
    # (@)METHOD:Height([HEIGHT])
    # Gets or sets the window height.
void
Height(handle,...)
    HWND handle
PREINIT:
    RECT myRect;
PPCODE:
    if(items > 2) {
        croak("Usage: Height(handle, [value]);\n");
    }

    if(!GetWindowRect(handle, &myRect)) XSRETURN_NO;

    if(items == 1) {
        EXTEND(SP, 1);
        XST_mIV(0, (myRect.bottom-myRect.top));
        XSRETURN(1);
    } else {
        if(SetWindowPos(handle, (HWND) NULL, 0, 0,
                        (int) (myRect.right-myRect.left),
                        (int) SvIV(ST(1)),
                        SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOMOVE)) {
            XSRETURN_YES;
        } else {
            XSRETURN_NO;
        }
    }


    ###########################################################################
    # (@)METHOD:Left([LEFT])
    # Gets or sets the window x coordinate.
void
Left(handle,...)
    HWND handle
PREINIT:
    RECT myRect;
	HWND parent;
	POINT myPt;
PPCODE:
    if(items > 2) {
        croak("Usage: Left(handle, [value]);\n");
    }
    if(!GetWindowRect(handle, &myRect)) XSRETURN_NO;
    myPt.x = myRect.left;
    myPt.y = myRect.top;
    parent = GetParent(handle);
    if (parent) ScreenToClient(parent, &myPt);
    if(items == 1) {
        EXTEND(SP, 1);
        XST_mIV(0, myPt.x);
        XSRETURN(1);
    } else {
        if(SetWindowPos(
			handle, (HWND) NULL,
			(int) SvIV(ST(1)), (int) myPt.y,
			0, 0,
			SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOSIZE
		)) {
            XSRETURN_YES;
        } else {
            XSRETURN_NO;
        }
    }


    ###########################################################################
    # (@)METHOD:Top([TOP])
    # Gets or sets the window y coordinate.
void
Top(handle,...)
    HWND handle
PREINIT:
    RECT myRect;
	HWND parent;
	POINT myPt;
PPCODE:
    if(items > 2) {
        croak("Usage: Top(handle, [value]);\n");
    }
    if(!GetWindowRect(handle, &myRect)) XSRETURN_NO;
    myPt.x = myRect.left;
    myPt.y = myRect.top;
    parent = GetParent(handle);
    if (parent) ScreenToClient(parent, &myPt);
	if(items == 1) {
		EXTEND(SP, 1);
		XST_mIV(0, myPt.y);
		XSRETURN(1);
    } else {
        if(SetWindowPos(
			handle, (HWND) NULL,
			(int) myPt.x, (int) SvIV(ST(1)),
			0, 0,
			SWP_NOZORDER | SWP_NOOWNERZORDER | SWP_NOSIZE
		)) {
            XSRETURN_YES;
        } else {
            XSRETURN_NO;
        }
    }

    ###########################################################################
    # (@)METHOD:AbsLeft()
int
AbsLeft(handle)
    HWND handle
PREINIT:
    RECT myRect;
CODE:
    if(!GetWindowRect(handle, &myRect)) {
		RETVAL = -1;
	} else {
    	RETVAL = myRect.left;
	}
OUTPUT:
	RETVAL

    ###########################################################################
    # (@)METHOD:AbsTop()
int
AbsTop(handle)
    HWND handle
PREINIT:
    RECT myRect;
CODE:
    if(!GetWindowRect(handle, &myRect)) {
		RETVAL = -1;
	} else {
    	RETVAL = myRect.top;
	}
OUTPUT:
	RETVAL


    ###########################################################################
    # (@)METHOD:ScaleWidth()
DWORD
ScaleWidth(handle)
    HWND handle
PREINIT:
    RECT myRect;
CODE:
    if(GetClientRect(handle, &myRect)) {
        RETVAL = myRect.right;
    } else {
        RETVAL = 0;
    }
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:ScaleHeight()
DWORD
ScaleHeight(handle)
    HWND handle
PREINIT:
    RECT myRect;
CODE:
    if(GetClientRect(handle, &myRect)) {
        RETVAL = myRect.bottom;
    } else {
        RETVAL = 0;
    }
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:BringWindowToTop()
BOOL
BringWindowToTop(handle)
    HWND handle
CODE:
    RETVAL = BringWindowToTop(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:ArrangeIconicWindows()
    # Arranges all the minimized child windows of the specified parent window.
UINT
ArrangeIconicWindows(handle)
    HWND handle
CODE:
    RETVAL = ArrangeIconicWindows(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetDesktopWindow()
    # Returns the handle of the desktop window.
HWND
GetDesktopWindow(...)
CODE:
   RETVAL = GetDesktopWindow();
OUTPUT:
   RETVAL


    ###########################################################################
    # (@)METHOD:GetForegroundWindow()
    # Returns the handle of the foreground window.
HWND
GetForegroundWindow(...)
CODE:
   RETVAL = GetForegroundWindow();
OUTPUT:
   RETVAL


    ###########################################################################
    # (@)METHOD:SetForegroundWindow()
    # Brings the window to the foreground.
BOOL
SetForegroundWindow(handle)
    HWND handle
CODE:
    RETVAL = SetForegroundWindow(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:IsZoomed()
BOOL
IsZoomed(handle)
    HWND handle
CODE:
    RETVAL = IsZoomed(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:IsIconic()
    # Returns TRUE if the window is minimized, FALSE otherwise.
BOOL
IsIconic(handle)
    HWND handle
CODE:
    RETVAL = IsIconic(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:IsWindow()
BOOL
IsWindow(handle)
    HWND handle
CODE:
    RETVAL = IsWindow(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:IsVisible()
BOOL
IsVisible(handle)
    HWND handle
CODE:
    RETVAL = IsWindowVisible(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:IsEnabled()
BOOL
IsEnabled(handle)
    HWND handle
CODE:
    RETVAL = IsWindowEnabled(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Enable([FLAG])
BOOL
Enable(handle,flag=TRUE)
    HWND handle
    BOOL flag
CODE:
    RETVAL = EnableWindow(handle, flag);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Disable()
BOOL
Disable(handle)
    HWND handle
CODE:
    RETVAL = EnableWindow(handle, FALSE);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:OpenIcon()
    # (@)METHOD:Restore()
BOOL
OpenIcon(handle)
    HWND handle
ALIAS:
    Win32::GUI::Restore = 1
CODE:
    RETVAL = OpenIcon(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:CloseWindow()
    # (@)METHOD:Minimize()
BOOL
CloseWindow(handle)
    HWND handle
ALIAS:
    Win32::GUI::Minimize = 1
CODE:
    RETVAL = CloseWindow(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:WindowFromPoint(X, Y)
    # Returns the handle of the window at the specified screen position.
HWND
WindowFromPoint(x,y)
    LONG x
    LONG y
PREINIT:
    POINT myPoint;
CODE:
    myPoint.x = x;
    myPoint.y = y;
    RETVAL = WindowFromPoint(myPoint);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetTopWindow()
    # Returns the handle of the foreground window.
HWND
GetTopWindow(handle)
    HWND handle
CODE:
    RETVAL = GetTopWindow(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetActiveWindow()
    # Returns the handle of the active window.
HWND
GetActiveWindow(...)
CODE:
    RETVAL = GetActiveWindow();
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetDlgItem(ID)
    # Returns the handle of a control in the dialog box given its ID.
HWND
GetDlgItem(handle,identifier)
    HWND handle
    int identifier
CODE:
    RETVAL = GetDlgItem(handle, identifier);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetFocus()
    # Returns the handle of the window that has the keyboard focus.
HWND
GetFocus(...)
CODE:
    RETVAL = GetFocus();
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:SetFocus()
    # Activates a window.
HWND
SetFocus(handle)
    HWND handle
CODE:
    RETVAL = SetFocus(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:SetCapture()
    # Assigns the mouse capture to a window.
HWND
SetCapture(handle)
    HWND handle
CODE:
    RETVAL = SetCapture(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:ReleaseCapture()
    # Releases the mouse capture.
BOOL
ReleaseCapture(...)
CODE:
    RETVAL = ReleaseCapture();
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetWindowThreadProcessId()
    # Returns a two elements array containing the thread and the process
    # identifier for the specified window.
void
GetWindowThreadProcessId(handle)
    HWND handle
PREINIT:
    DWORD tid;
    DWORD pid;
PPCODE:
    tid = GetWindowThreadProcessId(handle, &pid);
    EXTEND(SP, 2);
    XST_mIV(0, tid);
    XST_mIV(1, pid);
    XSRETURN(2);


    ###########################################################################
    # (@)METHOD:AttachThreadInput(FROM, TO, [FLAG])
BOOL
AttachThreadInput(from,to,flag=TRUE)
    DWORD from
    DWORD to
    BOOL flag
CODE:
    RETVAL = AttachThreadInput(from, to, flag);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetTextExtentPoint32(STRING, [FONT])
    # Returns a two elements array containing the x and y size of the
    # specified STRING in the window (eventually with the speficied FONT), or
    # undef on errors.
void
GetTextExtentPoint32(handle,string,font=NULL)
    HWND handle
    char * string
    HFONT font
PREINIT:
    STRLEN cbString;
    char *szString;
    HDC hdc;
    SIZE mySize;
PPCODE:
    szString = SvPV(ST(1), cbString);
    hdc = GetDC(handle);
#ifdef PERLWIN32GUI_DEBUG
    printf("XS(GetTextExtentPoint32).font=%ld\n", font);
    printf("XS(GetTextExtentPoint32).string=%s\n", string);
#endif
    if(font)
        SelectObject(hdc, (HGDIOBJ) font);
    if(GetTextExtentPoint32(hdc, szString, (int)cbString, &mySize)) {
        EXTEND(SP, 2);
        XST_mIV(0, mySize.cx);
        XST_mIV(1, mySize.cy);
        ReleaseDC(handle, hdc);
        XSRETURN(2);
    } else {
        ReleaseDC(handle, hdc);
        XSRETURN_NO;
    }


    ###########################################################################
    # (@)METHOD:TrackPopupMenu(MENU, X, Y, [FLAGS])
BOOL
TrackPopupMenu(handle,hmenu,x,y,flags=TPM_LEFTALIGN|TPM_TOPALIGN|TPM_LEFTBUTTON)
    HWND handle
    HMENU hmenu
    int x
    int y
    UINT flags
CODE:
	SetForegroundWindow(handle);
	RETVAL = TrackPopupMenu(hmenu, flags, x, y, 0, handle, (CONST RECT*) NULL);
	SetForegroundWindow(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:SetTimer(HANDLE, ID, ELAPSE)
UINT
SetTimer(handle,id,elapse)
    HWND handle
    UINT id
    UINT elapse
CODE:
    RETVAL = SetTimer(handle, id, elapse, NULL);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:KillTimer(HANDLE, ID)
UINT
KillTimer(handle,id)
    HWND handle
    UINT id
CODE:
    RETVAL = KillTimer(handle, id);
OUTPUT:
    RETVAL

    # void
    # EnumChilds(handle)
    #     HWND handle
    # PREINIT:
    #     UINT number;
    # PPCODE:
    #     if(EnumChildWindows(handle, EnumChildsProc, (LPARAM) &number))
    #         XSRETURN(number);
    #     else
    #         XSRETURN_NO;


    ###########################################################################
    # (@)METHOD:GetEffectiveClientRect(HANDLE, ID)
void
GetEffectiveClientRect(handle,...)
    HWND handle
PREINIT:
    LPINT controls;
    int i, c;
    RECT r;
PPCODE:
    c = 0;
    controls = (LPINT) safemalloc(sizeof(INT)*items*2);
    for(i=1;i<items;i++) {
        controls[c++] = 1;
        controls[c++] = (INT) SvIV(ST(i));
    }
    controls[c++] = 0;
    controls[c++] = 0;
    GetEffectiveClientRect(handle, &r, controls);
    EXTEND(SP, 4);
    XST_mIV(0, r.left);
    XST_mIV(1, r.top);
    XST_mIV(2, r.right);
    XST_mIV(3, r.bottom);
    XSRETURN(4);


    ###########################################################################
    # (@)METHOD:DialogUI(HANDLE, [FLAG])
void
DialogUI(handle,...)
    HWND handle
PREINIT:
	LPPERLWIN32GUI_USERDATA perlud;
PPCODE:
    if(items > 2) {
        CROAK("Usage: DialogUI(handle, [value]);\n");
    }

    perlud = (LPPERLWIN32GUI_USERDATA) GetWindowLong(handle, GWL_USERDATA);
    if(perlud == NULL || perlud->dwSize != sizeof(PERLWIN32GUI_USERDATA)) {
		XSRETURN_UNDEF;
	} else {
    	if(items == 1) {
			XSRETURN_IV( (long) perlud->fDialogUI );
		} else {
			perlud->fDialogUI = SvIV(ST(1));
			SetWindowLong( handle, GWL_USERDATA, (long) perlud );
			XSRETURN_IV( (long) perlud->fDialogUI );
		}
    }


    # TODO: GetIconInfo

    ###########################################################################
    # DC-related functions (2D window graphic...)
    ###########################################################################


    ###########################################################################
    # (@)METHOD:PlayEnhMetaFile(FILENAME)
int
PlayEnhMetaFile(handle,filename)
    HWND handle
    LPCTSTR filename
PREINIT:
    HV* self;
    HDC hdc;
    SV** tmp;
    STRLEN textlen;
    HENHMETAFILE hmeta;
    RECT rect;
CODE:
    self = (HV*) SvRV(ST(0));
    tmp = hv_fetch(self, "-DC", 3, 0);
    if(SvMAGICAL(self)) mg_get(*tmp);
    if(tmp == NULL) {
        RETVAL = -1;
    } else {
        hdc = (HDC) SvIV(*tmp);
        if(hmeta = GetEnhMetaFile(filename)) {
            GetClientRect(handle, &rect);
            RETVAL = PlayEnhMetaFile(hdc, hmeta, &rect);
            DeleteEnhMetaFile(hmeta);
        } else {
#ifdef PERLWIN32GUI_DEBUG
	            printf("XS(PlayEnhMetaFile): GetEnhMetaFile failed, error = %d\n", GetLastError());
#endif
            RETVAL = 0;
        }
    }
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:PlayWinMetaFile(FILENAME)
int
PlayWinMetaFile(handle,filename)
    HWND handle
    LPCTSTR filename
PREINIT:
    HDC hdc;
    HMETAFILE hwinmeta;
    HENHMETAFILE hmeta;
    RECT rect;
    UINT size;
    LPVOID data;
CODE:
#ifdef PERLWIN32GUI_DEBUG
    printf("XS(PlayWinMetaFile): filename = %s\n", filename);
#endif
    SetLastError(0);
    hwinmeta = GetMetaFile(filename);
#ifdef PERLWIN32GUI_DEBUG
    printf("XS(PlayWinMetaFile): hwinmeta = %ld\n", hwinmeta);
#endif
#ifdef PERLWIN32GUI_DEBUG
    printf("XS(PlayWinMetaFile): GetLastError = %ld\n", GetLastError());
#endif
    size = GetMetaFileBitsEx(hwinmeta, 0, NULL);
#ifdef PERLWIN32GUI_DEBUG
    printf("XS(PlayWinMetaFile): size = %d\n", size);
#endif
    data = (LPVOID) safemalloc(size);
    GetMetaFileBitsEx(hwinmeta, size, data);
    hmeta = SetWinMetaFileBits(size, (CONST BYTE *) data, NULL, NULL);
#ifdef PERLWIN32GUI_DEBUG
    printf("XS(PlayWinMetaFile): hmeta = %ld\n", hmeta);
#endif
    hdc = GetDC(handle);
    GetClientRect(handle, &rect);
    SetLastError(0);
    RETVAL = PlayEnhMetaFile(hdc, hmeta, &rect);
#ifdef PERLWIN32GUI_DEBUG
    printf("XS(PlayWinMetaFile): GetLastError after PlayEnhMetaFile = %d\n", GetLastError());
#endif
    DeleteEnhMetaFile(hmeta);
    ReleaseDC(handle, hdc);
    safefree(data);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:CreateEnhMetaFile(FILENAME, [DESCRIPTION])
HDC
CreateEnhMetaFile(handle, filename, description=NULL)
    HWND handle
    LPCTSTR filename
    LPCTSTR description
PREINIT:
    HV* self;
    HDC hdc;
    SV** tmp;
    RECT rect;
    int iWidthMM, iHeightMM, iWidthPels, iHeightPels;
CODE:
    self = (HV*) SvRV(ST(0));
    tmp = hv_fetch(self, "-DC", 3, 0);
	if(SvMAGICAL(self)) mg_get(*tmp);
    if(tmp == NULL) {
        RETVAL = 0;
    } else {
        hdc = (HDC) SvIV(*tmp);
        iWidthMM = GetDeviceCaps(hdc, HORZSIZE);
        iHeightMM = GetDeviceCaps(hdc, VERTSIZE);
        iWidthPels = GetDeviceCaps(hdc, HORZRES);
        iHeightPels = GetDeviceCaps(hdc, VERTRES);
        GetClientRect(handle, &rect);
        rect.left = (rect.left * iWidthMM * 100)/iWidthPels;
        rect.top = (rect.top * iHeightMM * 100)/iHeightPels;
        rect.right = (rect.right * iWidthMM * 100)/iWidthPels;
        rect.bottom = (rect.bottom * iHeightMM * 100)/iHeightPels;
        RETVAL = CreateEnhMetaFile(hdc, filename, &rect, description);
    }
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:CloseEnhMetaFile()
HENHMETAFILE
CloseEnhMetaFile(hdc)
    HDC hdc
CODE:
    RETVAL = CloseEnhMetaFile(hdc);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:DeleteEnhMetaFile(HANDLE)
BOOL
DeleteEnhMetaFile(hmeta)
    HENHMETAFILE hmeta
CODE:
    RETVAL = DeleteEnhMetaFile(hmeta);
OUTPUT:
    RETVAL


    #HDC GetOrInitDC(SV* obj) {
    #    CPerl *pPerl;
    #    HDC hdc;
    #    HWND hwnd;
    #    SV** obj_dc;
    #    SV** obj_hwnd;
    #
    #    pPerl = theperl;
    #
    #    obj_dc = hv_fetch((HV*)SvRV(obj), "dc", 2, 0);
    #    if(obj_dc != NULL) {
    #        __DEBUG("!XS(GetOrInitDC): obj{dc} = %ld\n", SvIV(*obj_dc));
    #        return (HDC) SvIV(*obj_dc);
    #    } else {
    #        obj_hwnd = hv_fetch((HV*)SvRV(obj), "handle", 6, 0);
    #        hwnd = (HWND) SvIV(*obj_hwnd);
    #        hdc = GetDC(hwnd);
    #        __DEBUG("!XS(GetOrInitDC): GetDC = %ld\n", hdc);
    #        hv_store((HV*) SvRV(obj), "dc", 2, newSViv((long) hdc), 0);
    #        return hdc;
    #    }
    #}
    #
    #
    #XS(XS_Win32__GUI_DrawText) {
    #
    #    dXSARGS;
    #    if(items < 4 || items > 7) {
    #        CROAK("usage: DrawText($handle, $text, $left, $top, [$width, $height, $format]);\n");
    #    }
    #
    #    HDC hdc = GetOrInitDC(ST(0));
    #    RECT myRect;
    #
    #    strlen cbString;
    #    char *szString = SvPV(ST(1), cbString);
    #
    #    myRect.left   = (LONG) SvIV(ST(2));
    #    myRect.top    = (LONG) SvIV(ST(3));
    #
    #    if(items >4) {
    #        myRect.right  = (LONG) SvIV(ST(4));
    #        myRect.bottom = (LONG) SvIV(ST(5));
    #    } else {
    #        SIZE mySize;
    #        GetTextExtentPoint(hdc, szString, (int)cbString, &mySize);
    #        myRect.right  = myRect.left + (UINT) mySize.cx;
    #        myRect.bottom = myRect.top  + (UINT) mySize.cy;
    #    }
    #
    #    UINT uFormat = DT_LEFT;
    #
    #    if(items == 7) {
    #        uFormat = (UINT) SvIV(ST(6));
    #    }
    #
    #    BOOL result = DrawText(hdc,
    #                           szString,
    #                           cbString,
    #                           &myRect,
    #                           uFormat);
    #    XSRETURN_IV((long) result);
    #}
    #
    #
    #
    #
    #XS(XS_Win32__GUI_ReleaseDC) {
    #
    #    dXSARGS;
    #    if(items != 1) {
    #        CROAK("usage: ReleaseDC($handle);\n");
    #    }
    #
    #    HWND hwnd = (HWND) handle_From(NOTXSCALL ST(0));
    #    HDC hdc = GetOrInitDC(ST(0));
    #
    #    ReleaseDC(hwnd, hdc);
    #    hv_delete((HV*) SvRV(ST(0)), "dc", 2, 0);
    #
    #    XSRETURN_NO;
    #}
    #
    #

long
TextOut(handle, x, y, text)
    HWND handle
    int x
    int y
    char * text
PREINIT:
    HV* self;
    HDC hdc;
    SV** tmp;
    STRLEN textlen;
CODE:
    self = (HV*) SvRV(ST(0));
    tmp = hv_fetch(self, "-DC", 3, 0);
   	if(SvMAGICAL(self)) mg_get(*tmp);
    if(tmp == NULL) {
        RETVAL = -1;
    } else {
        hdc = (HDC) SvIV(*tmp);
        textlen = strlen(text);
        RETVAL = (long) TextOut(hdc, x, y, text, textlen);
    }
OUTPUT:
    RETVAL

long
SetTextColor(handle, color)
    HWND handle
    COLORREF color
PREINIT:
    HV* self;
    HDC hdc;
    SV** tmp;
CODE:
    self = (HV*) SvRV(ST(0));
    tmp = hv_fetch(self, "-DC", 3, 0);
   	if(SvMAGICAL(self)) mg_get(*tmp);
    if(tmp == NULL) {
        RETVAL = -1;
    } else {
        hdc = (HDC) SvIV(*tmp);
        RETVAL = SetTextColor(hdc, color);
    }
OUTPUT:
    RETVAL

long
GetTextColor(handle)
    HWND handle
PREINIT:
    HV* self;
    HDC hdc;
    SV** tmp;
CODE:
    self = (HV*) SvRV(ST(0));
    tmp = hv_fetch(self, "-DC", 3, 0);
   	if(SvMAGICAL(self)) mg_get(*tmp);
    if(tmp == NULL) {
        RETVAL = -1;
    } else {
        hdc = (HDC) SvIV(*tmp);
        RETVAL = GetTextColor(hdc);
    }
OUTPUT:
    RETVAL

long
SetBkMode(handle, mode)
    HWND handle
    int mode
PREINIT:
    HV* self;
    HDC hdc;
    SV** tmp;
CODE:
    self = (HV*) SvRV(ST(0));
    tmp = hv_fetch(self, "-DC", 3, 0);
   	if(SvMAGICAL(self)) mg_get(*tmp);
    if(tmp == NULL) {
        RETVAL = -1;
    } else {
        hdc = (HDC) SvIV(*tmp);
        RETVAL = (long) SetBkMode(hdc, mode);
    }
OUTPUT:
    RETVAL

int
GetBkMode(handle)
    HWND handle
PREINIT:
    HV* self;
    HDC hdc;
    SV** tmp;
CODE:
    self = (HV*) SvRV(ST(0));
    tmp = hv_fetch(self, "-DC", 3, 0);
   	if(SvMAGICAL(self)) mg_get(*tmp);
    if(tmp == NULL) {
        RETVAL = -1;
    } else {
        hdc = (HDC) SvIV(*tmp);
        RETVAL = GetBkMode(hdc);
    }
OUTPUT:
    RETVAL

long
MoveTo(handle, x, y)
    HWND handle
    int x
    int y
PREINIT:
    HV* self;
    HDC hdc;
    SV** tmp;
CODE:
    self = (HV*) SvRV(ST(0));
    tmp = hv_fetch(self, "-DC", 3, 0);
   	if(SvMAGICAL(self)) mg_get(*tmp);
    if(tmp == NULL) {
        RETVAL = -1;
    } else {
        hdc = (HDC) SvIV(*tmp);
        RETVAL = MoveToEx(hdc, x, y, NULL);
    }
OUTPUT:
    RETVAL

long
Circle(handle, x, y, width, height=-1)
    HWND handle
    int x
    int y
    int width
    int height
PREINIT:
    HV* self;
    HDC hdc;
    SV** tmp;
CODE:
    self = (HV*) SvRV(ST(0));
    tmp = hv_fetch(self, "-DC", 3, 0);
   	if(SvMAGICAL(self)) mg_get(*tmp);
    if(tmp == NULL) {
        RETVAL = -1;
    } else {
        hdc = (HDC) SvIV(*tmp);
        if(height == -1) {
            width *= 2;
            height = width;
        }
        RETVAL = (long) Arc(hdc, x, y, width-x, height-y, 0, 0, 0, 0);
    }
OUTPUT:
    RETVAL


long
LineTo(handle, x, y)
    HWND handle
    int x
    int y
PREINIT:
    HV* self;
    HDC hdc;
    SV** tmp;
CODE:
    self = (HV*) SvRV(ST(0));
    tmp = hv_fetch(self, "-DC", 3, 0);
   	if(SvMAGICAL(self)) mg_get(*tmp);
    if(tmp == NULL) {
        RETVAL = -1;
    } else {
        hdc = (HDC) SvIV(*tmp);
        RETVAL = LineTo(hdc, x, y);
    }
OUTPUT:
    RETVAL

    #}
    #
    #XS(XS_Win32__GUI_DrawEdge) {
    #
    #    dXSARGS;
    #    if(items != 7) {
    #        CROAK("usage: DrawEdge($handle, $left, $top, $width, $height, $edge, $flags);\n");
    #    }
    #
    #    HDC hdc = GetOrInitDC(ST(0));
    #    RECT myRect;
    #    myRect.left   = (LONG) SvIV(ST(1));
    #    myRect.top    = (LONG) SvIV(ST(2));
    #    myRect.right  = (LONG) SvIV(ST(3));
    #    myRect.bottom = (LONG) SvIV(ST(4));
    #
    #    XSRETURN_IV((long) DrawEdge(hdc,
    #                           &myRect,
    #                           (UINT) SvIV(ST(5)),
    #                           (UINT) SvIV(ST(6))));
    #}

void
BeginPaint(...)
PPCODE:
    HV* self;
    HWND hwnd;
    HDC hdc;
    int i;
    PAINTSTRUCT ps;
    char tmprgb[16];
    self = (HV*) SvRV(ST(0));
    hwnd = (HWND) SvIV(*hv_fetch(self, "-handle", 7, 0));
    if(hwnd) {
        if(hdc = BeginPaint(hwnd, &ps)) {
            hv_store(self, "-DC", 3, newSViv((long) hdc), 0);
            hv_store(self, "-ps.hdc", 7, newSViv((long) ps.hdc), 0);
            hv_store(self, "-ps.fErase", 10, newSViv((long) ps.fErase), 0);
            hv_store(self, "-ps.rcPaint.left", 16, newSViv((long) ps.rcPaint.left), 0);
            hv_store(self, "-ps.rcPaint.top", 15, newSViv((long) ps.rcPaint.top), 0);
            hv_store(self, "-ps.rcPaint.right", 17, newSViv((long) ps.rcPaint.right), 0);
            hv_store(self, "-ps.rcPaint.bottom", 18, newSViv((long) ps.rcPaint.bottom), 0);
            hv_store(self, "-ps.fRestore", 12, newSViv((long) ps.fRestore), 0);
            hv_store(self, "-ps.fIncUpdate", 14, newSViv((long) ps.fIncUpdate), 0);
            for(i=0;i<=31;i++) {
                sprintf(tmprgb, "-ps.rgbReserved%02d", i);
                hv_store(self, tmprgb, 17, newSViv((long) ps.rgbReserved[i]), 0);
            }
            XSRETURN_YES;
        } else {
            XSRETURN_NO;
        }
    } else {
        XSRETURN_NO;
    }

void
EndPaint(...)
PPCODE:
    HV* self;
    HWND hwnd;
    HDC hdc;
    SV** tmp;
    int i;
    PAINTSTRUCT ps;
    char tmprgb[16];
    BOOL result;

    self = (HV*) SvRV(ST(0));
    if(self) {
        tmp = hv_fetch(self, "-handle", 7, 0);
        if(tmp == NULL) XSRETURN_NO;
        hwnd = (HWND) SvIV(*tmp);
        tmp = hv_fetch(self, "-ps.hdc", 7, 0);
        if(tmp == NULL) XSRETURN_NO;
        ps.hdc = (HDC) SvIV(*tmp);
        tmp = hv_fetch(self, "-ps.fErase", 10, 0);
        if(tmp == NULL) XSRETURN_NO;
        ps.fErase = (BOOL) SvIV(*tmp);
        tmp = hv_fetch(self, "-ps.rcPaint.left", 16, 0);
        if(tmp == NULL) XSRETURN_NO;
        ps.rcPaint.left = (LONG) SvIV(*tmp);
        tmp = hv_fetch(self, "-ps.rcPaint.top", 15, 0);
        if(tmp == NULL) XSRETURN_NO;
        ps.rcPaint.top = (LONG) SvIV(*tmp);
        tmp = hv_fetch(self, "-ps.rcPaint.right", 17, 0);
        if(tmp == NULL) XSRETURN_NO;
        ps.rcPaint.right = (LONG) SvIV(*tmp);
        tmp = hv_fetch(self, "-ps.rcPaint.bottom", 18, 0);
        if(tmp == NULL) XSRETURN_NO;
        ps.rcPaint.bottom = (LONG) SvIV(*tmp);
        tmp = hv_fetch(self, "-ps.fRestore", 12, 0);
        if(tmp == NULL) XSRETURN_NO;
        ps.fRestore = (BOOL) SvIV(*tmp);
        tmp = hv_fetch(self, "-ps.fIncUpdate", 14, 0);
        if(tmp == NULL) XSRETURN_NO;
        ps.fIncUpdate = (BOOL) SvIV(*tmp);
        for(i=0;i<=31;i++) {
            sprintf(tmprgb, "-ps.rgbReserved%02d", i);
            tmp = hv_fetch(self, tmprgb, 17, 0);
            if(tmp == NULL) XSRETURN_NO;
            ps.rgbReserved[i] = (BYTE) SvIV(*tmp);
        }
        result = EndPaint(hwnd, &ps);
        hv_delete(self, "-DC", 3, 0);
        hv_delete(self, "-ps.hdc", 7, 0);
        hv_delete(self, "-ps.fErase", 10, 0);
        hv_delete(self, "-ps.rcPaint.left", 16, 0);
        hv_delete(self, "-ps.rcPaint.top", 15, 0);
        hv_delete(self, "-ps.rcPaint.right", 17, 0);
        hv_delete(self, "-ps.rcPaint.bottom", 18, 0);
        hv_delete(self, "-ps.fRestore", 12, 0);
        hv_delete(self, "-ps.fIncUpdate", 14, 0);
        for(i=0;i<=31;i++) {
            sprintf(tmprgb, "-ps.rgbReserved%02d", i);
            hv_delete(self, tmprgb, 17, 0);
        }
        XSRETURN_IV((long) result);
    } else {
        XSRETURN_NO;
    }


    ###########################################################################
    # (@)METHOD:SaveBMP(handle)
    # (preliminary) Saves the window content to a BMP file.
void
SaveBMP(handle)
    HWND handle
PREINIT:
    HDC hdc;
    HDC hdc2;
    RECT cr;
    HANDLE hf;
    BITMAP bmp;
    HBITMAP hbmp;
    PBITMAPINFO pbmi;
    PBITMAPINFOHEADER pbih;
    BITMAPFILEHEADER hdr;
    WORD cClrBits;
    LONG width, height;
    LPBYTE lpBits;
    BYTE *hp;
    DWORD cb;
    DWORD dwTmp;
    DWORD dwTotal;
    int MAXWRITE;
PPCODE:
    hdc = GetDC(handle);
    GetClientRect(handle, &cr);
    width = cr.right - cr.left;
    height = cr.bottom - cr.top;
    MAXWRITE = 2048;

    hdc2 = CreateCompatibleDC(hdc);
    hbmp = CreateCompatibleBitmap(hdc, width, height);
    SelectObject(hdc2, hbmp);
    BitBlt(hdc2, 0, 0, width, height, hdc, 0, 0, SRCCOPY);
    if (!GetObject(hbmp, sizeof(BITMAP), (LPSTR)&bmp)) {
        XSRETURN_NO;
    }

    cClrBits = (WORD)(bmp.bmPlanes * bmp.bmBitsPixel);
    if (cClrBits == 1)       cClrBits = 1;
    else if (cClrBits <= 4)  cClrBits = 4;
    else if (cClrBits <= 8)  cClrBits = 8;
    else if (cClrBits <= 16) cClrBits = 16;
    else if (cClrBits <= 24) cClrBits = 24;
    else                     cClrBits = 32;

    if (cClrBits != 24)
        pbmi = (PBITMAPINFO) LocalAlloc(LPTR, sizeof(BITMAPINFOHEADER) + sizeof(RGBQUAD) * (2^cClrBits));
    else
        pbmi = (PBITMAPINFO) LocalAlloc(LPTR, sizeof(BITMAPINFOHEADER));

    pbmi->bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    pbmi->bmiHeader.biWidth = bmp.bmWidth;
    pbmi->bmiHeader.biHeight = bmp.bmHeight;
    pbmi->bmiHeader.biPlanes = bmp.bmPlanes;
    pbmi->bmiHeader.biBitCount = bmp.bmBitsPixel;
    if (cClrBits < 24) pbmi->bmiHeader.biClrUsed = 2^cClrBits;
    pbmi->bmiHeader.biCompression = BI_RGB;
    pbmi->bmiHeader.biSizeImage = (pbmi->bmiHeader.biWidth + 7) /8
                                  * pbmi->bmiHeader.biHeight
                                  * cClrBits;
    pbmi->bmiHeader.biClrImportant = 0;

    pbih = (PBITMAPINFOHEADER) pbmi;

    lpBits = (LPBYTE) GlobalAlloc(GMEM_FIXED, pbih->biSizeImage);

    if (!GetDIBits(hdc2, hbmp, 0, (WORD) pbih->biHeight, lpBits, pbmi, DIB_RGB_COLORS)) {
        XSRETURN_NO;
    }

    hf = CreateFile("SaveBMP.bmp",
                    GENERIC_READ | GENERIC_WRITE,
                    (DWORD) 0,
                    (LPSECURITY_ATTRIBUTES) NULL,
                    CREATE_ALWAYS,
                    FILE_ATTRIBUTE_NORMAL,
                    (HANDLE) NULL);
    if(hf == INVALID_HANDLE_VALUE) {
        XSRETURN_NO;
    }
    hdr.bfType = 0x4d42;        /* 0x42 = "B" 0x4d = "M" */

    /* Compute the size of the entire file. */
    hdr.bfSize = (DWORD) (sizeof(BITMAPFILEHEADER) +
                 pbih->biSize + pbih->biClrUsed
                 * sizeof(RGBQUAD) + pbih->biSizeImage);
    hdr.bfReserved1 = 0;
    hdr.bfReserved2 = 0;

    /* Compute the offset to the array of color indices. */
    hdr.bfOffBits = (DWORD) sizeof(BITMAPFILEHEADER) +
                    pbih->biSize + pbih->biClrUsed
                    * sizeof (RGBQUAD);
    /* Copy the BITMAPFILEHEADER into the .BMP file. */
    if (!WriteFile(hf, (LPVOID) &hdr, sizeof(BITMAPFILEHEADER),
       (LPDWORD) &dwTmp, (LPOVERLAPPED) NULL)) {
       XSRETURN_NO;
    }
    /* Copy the BITMAPINFOHEADER and RGBQUAD array into the file. */
    if (!WriteFile(hf, (LPVOID) pbih, sizeof(BITMAPINFOHEADER)
                  + pbih->biClrUsed * sizeof (RGBQUAD),
                  (LPDWORD) &dwTmp, (LPOVERLAPPED) NULL)) {
        XSRETURN_NO;
    }
    /* Copy the array of color indices into the .BMP file. */
    dwTotal = cb = pbih->biSizeImage;     hp = lpBits;
    while (cb > MAXWRITE)  {
        if (!WriteFile(hf, (LPSTR) hp, (int) MAXWRITE,
                          (LPDWORD) &dwTmp, (LPOVERLAPPED) NULL)) {
            XSRETURN_NO;
        }
        cb-= MAXWRITE;
        hp += MAXWRITE;
    }
    if (!WriteFile(hf, (LPSTR) hp, (int) cb,
        (LPDWORD) &dwTmp, (LPOVERLAPPED) NULL)) {
        XSRETURN_NO;
    }
    if (!CloseHandle(hf)) {
        XSRETURN_NO;
    }

    /* Free memory. */
    GlobalFree((HGLOBAL)lpBits);
    DeleteDC(hdc2);
    ReleaseDC(handle, hdc);
    DeleteObject(hbmp);
    XSRETURN_YES;


    ###########################################################################
    # Common Dialog Boxes
    ###########################################################################


    ###########################################################################
    # (@)METHOD:MessageBox([HANDLE], TEXT, [CAPTION], [TYPE])
int
MessageBox(handle=NULL, text, caption=NULL, type=MB_ICONWARNING|MB_OK)
    HWND handle
    LPCTSTR text
    LPCTSTR caption
    UINT type
CODE:
    RETVAL = MessageBox(handle, text, caption, type);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetOpenFileName(%OPTIONS)
    # Allowed %OPTIONS are:
    #  -owner => WINDOW
    #      [TBD]
    #  -title => STRING
    #      the title for the dialog
    #  -directory => STRING
    #      specifies the initial directory
    #  -file => STRING
    #      specifies a name that will appear on the dialog's edit field
    #  -filter => ARRAY REFERENCE
    #      [TBD]
void
GetOpenFileName(...)
PPCODE:
    OPENFILENAME ofn;
    BOOL retval;
    int i, next_i;
    char filename[MAX_PATH];
    char *option;
    char *filter;

    ZeroMemory(&ofn, sizeof(OPENFILENAME));
    ofn.lStructSize = sizeof(OPENFILENAME);
    ofn.hwndOwner = NULL;
    ofn.lpstrFilter = NULL;
    ofn.lpstrCustomFilter = NULL;
    ofn.nFilterIndex = 0;
    ofn.lpstrFileTitle = NULL;
    ofn.lpstrInitialDir = NULL;
    ofn.lpstrTitle = NULL;
    ofn.lpstrDefExt = NULL;
    ofn.lpTemplateName = NULL;
    ofn.Flags = 0;
    filename[0] = 0;
    ofn.lpstrFile = filename;
    ofn.nMaxFile = MAX_PATH;

    next_i = -1;
    for(i = 0; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-owner") == 0) {
                next_i = i + 1;
                ofn.hwndOwner = (HWND) handle_From(NOTXSCALL ST(next_i));
            }
            if(strcmp(option, "-title") == 0) {
                next_i = i + 1;
                ofn.lpstrTitle = SvPV_nolen(ST(next_i));
            }
            if(strcmp(option, "-directory") == 0) {
                next_i = i + 1;
                ofn.lpstrInitialDir = SvPV_nolen(ST(next_i));
            }
            if(strcmp(option, "-filter") == 0) {
                next_i = i + 1;
                if(SvROK(ST(next_i)) && SvTYPE(SvRV(ST(next_i))) == SVt_PVAV) {
                    AV* filters;
                    SV** t;
                    int i, filterlen = 0;
                    char *fpointer;
                    filters = (AV*)SvRV(ST(next_i));
                    for(i=0; i<=av_len(filters); i++) {
                        t = av_fetch(filters, i, 0);
                        if(t != NULL) {
                            filterlen += SvCUR(*t) + 1;
                        }
                    }
                    filterlen += 2;
                    filter = (char *) safemalloc(filterlen);
                    fpointer = filter;
                    for(i=0; i<=av_len(filters); i++) {
                        t = av_fetch(filters, i, 0);
                        if(t != NULL) {
                            strcpy(fpointer, SvPV_nolen(*t));
                            fpointer += SvCUR(*t);
                            *fpointer++ = 0;
                        }

                    }
                    *fpointer = 0;
                    ofn.lpstrFilter = (LPCTSTR) filter;
                } else {
                    if(PL_dowarn) warn("Win32::GUI: argument to -filter is not an array reference!");
                }

            }
            if(strcmp(option, "-file") == 0) {
                next_i = i + 1;
                strcpy(filename, SvPV_nolen(ST(next_i)));
            }
        } else {
            next_i = -1;
        }
    }
    retval = GetOpenFileName(&ofn);
    if(retval) {
        EXTEND(SP, 1);
        XST_mPV( 0, ofn.lpstrFile);
        if(ofn.lpstrFilter != NULL) safefree((void *)filter);
        XSRETURN(1);
    } else {
        if(ofn.lpstrFilter != NULL) safefree((void *)filter);
        XSRETURN_NO;
    }


    ###########################################################################
    # (@)METHOD:GetSaveFileName(%OPTIONS)
    # Allowed %OPTIONS are:
    #  -owner => WINDOW
    #      [TBD]
    #  -title => STRING
    #      the title for the dialog
    #  -directory => STRING
    #      specifies the initial directory
    #  -file => STRING
    #      specifies a name that will appear on the dialog's edit field
    #  -filter => ARRAY REFERENCE
    #      [TBD]
void
GetSaveFileName(...)
PPCODE:
    OPENFILENAME ofn;
    BOOL retval;
    int i, next_i;
    char filename[MAX_PATH];
    char *option;
    char *filter;

    ZeroMemory(&ofn, sizeof(OPENFILENAME));
    ofn.lStructSize = sizeof(OPENFILENAME);
    ofn.hwndOwner = NULL;
    ofn.lpstrFilter = NULL;
    ofn.lpstrCustomFilter = NULL;
    ofn.nFilterIndex = 0;
    ofn.lpstrFileTitle = NULL;
    ofn.lpstrInitialDir = NULL;
    ofn.lpstrTitle = NULL;
    ofn.lpstrDefExt = NULL;
    ofn.lpTemplateName = NULL;
    ofn.Flags = 0;
    filename[0] = 0;
    ofn.lpstrFile = filename;
    ofn.nMaxFile = MAX_PATH;

    next_i = -1;
    for(i = 0; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-owner") == 0) {
                next_i = i + 1;
                ofn.hwndOwner = (HWND) handle_From(NOTXSCALL ST(next_i));
            }
            if(strcmp(option, "-title") == 0) {
                next_i = i + 1;
                ofn.lpstrTitle = SvPV_nolen(ST(next_i));
            }
            if(strcmp(option, "-directory") == 0) {
                next_i = i + 1;
                ofn.lpstrInitialDir = SvPV_nolen(ST(next_i));
            }
            if(strcmp(option, "-filter") == 0) {
                next_i = i + 1;
                if(SvROK(ST(next_i)) && SvTYPE(SvRV(ST(next_i))) == SVt_PVAV) {
                    AV* filters;
                    SV** t;
                    int i, filterlen = 0;
                    char *fpointer;
                    filters = (AV*)SvRV(ST(next_i));
                    for(i=0; i<=av_len(filters); i++) {
                        t = av_fetch(filters, i, 0);
                        if(t != NULL) {
                            filterlen += SvCUR(*t) + 1;
                        }
                    }
                    filterlen += 2;
                    filter = (char *) safemalloc(filterlen);
                    fpointer = filter;
                    for(i=0; i<=av_len(filters); i++) {
                        t = av_fetch(filters, i, 0);
                        if(t != NULL) {
                            strcpy(fpointer, SvPV_nolen(*t));
                            fpointer += SvCUR(*t);
                            *fpointer++ = 0;
                        }

                    }
                    *fpointer = 0;
                    ofn.lpstrFilter = (LPCTSTR) filter;
                } else {
                    if(PL_dowarn) warn("Win32::GUI: argument to -filter is not an array reference!");
                }

            }
            if(strcmp(option, "-file") == 0) {
                next_i = i + 1;
                strcpy(filename, SvPV_nolen(ST(next_i)));
            }
        } else {
            next_i = -1;
        }
    }
    retval = GetSaveFileName(&ofn);
    if(retval) {
        EXTEND(SP, 1);
        XST_mPV( 0, ofn.lpstrFile);
        if(ofn.lpstrFilter != NULL) safefree((void *)filter);
        XSRETURN(1);
    } else {
        if(ofn.lpstrFilter != NULL) safefree((void *)filter);
        XSRETURN_NO;
    }





    ###########################################################################
    # (@)METHOD:BrowseForFolder(%OPTIONS)
void
BrowseForFolder(...)
PPCODE:
    BROWSEINFO bi;
    LPITEMIDLIST retval;
    LPITEMIDLIST pidl;
    LPSHELLFOLDER pDesktopFolder;
	OLECHAR olePath[MAX_PATH];
	ULONG chEaten;
	HRESULT hr;
	int i, next_i;
    char folder[MAX_PATH];
    char *option;
    ZeroMemory(&bi, sizeof(BROWSEINFO));
    bi.pszDisplayName = folder;
    next_i = -1;
    for(i = 0; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-owner") == 0) {
                next_i = i + 1;
                bi.hwndOwner = (HWND) handle_From(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-title") == 0) {
                next_i = i + 1;
                bi.lpszTitle = SvPV_nolen(ST(next_i));
            } else if(strcmp(option, "-computeronly") == 0) {
                next_i = i + 1;
                SwitchFlag(bi.ulFlags, BIF_BROWSEFORCOMPUTER, SvIV(ST(next_i)));
            } else if(strcmp(option, "-domainonly") == 0) {
                next_i = i + 1;
                SwitchFlag(bi.ulFlags, BIF_DONTGOBELOWDOMAIN, SvIV(ST(next_i)));
            } else if(strcmp(option, "-driveonly") == 0) {
                next_i = i + 1;
                SwitchFlag(bi.ulFlags, BIF_RETURNFSANCESTORS, SvIV(ST(next_i)));
            } else if(strcmp(option, "-editbox") == 0) {
                next_i = i + 1;
                SwitchFlag(bi.ulFlags, BIF_EDITBOX, SvIV(ST(next_i)));
            } else if(strcmp(option, "-folderonly") == 0) {
                next_i = i + 1;
                SwitchFlag(bi.ulFlags, BIF_RETURNONLYFSDIRS, SvIV(ST(next_i)));
            } else if(strcmp(option, "-includefiles") == 0) {
                next_i = i + 1;
                SwitchFlag(bi.ulFlags, BIF_BROWSEINCLUDEFILES, SvIV(ST(next_i)));
            } else if(strcmp(option, "-directory") == 0) {
                next_i = i + 1;
                strcpy(folder, SvPV_nolen(ST(next_i)));
            } else if(strcmp(option, "-root") == 0) {
                next_i = i + 1;
                if(SvIOK(ST(next_i))) {
					bi.pidlRoot = (LPCITEMIDLIST) SvIV(ST(next_i));
				} else {
					SHGetDesktopFolder(&pDesktopFolder);
					MultiByteToWideChar(
						CP_ACP,
						MB_PRECOMPOSED,
						SvPV_nolen(ST(next_i)), -1,
						olePath, MAX_PATH
					);
					hr = pDesktopFolder->ParseDisplayName(
					// hr = IShellFolder::ParseDisplayName(
						NULL,
						NULL,
						olePath,
						&chEaten,
						&pidl,
						NULL
					);
					if(FAILED(hr)) {
						if(PL_dowarn) warn("Win32::GUI::BrowseForFolder: can't get ITEMIDLIST for -root!\n");
						pDesktopFolder->Release();
						XSRETURN_NO;
					} else {
						bi.pidlRoot = pidl;
						pDesktopFolder->Release();
					}
				}
            } else if(strcmp(option, "-printeronly") == 0) {
                next_i = i + 1;
                SwitchFlag(bi.ulFlags, BIF_BROWSEFORPRINTER, SvIV(ST(next_i)));
            }
        } else {
            next_i = -1;
        }
    }
    retval = SHBrowseForFolder(&bi);
    if(retval != NULL) {
		if(SHGetPathFromIDList(retval, folder)) {
        	EXTEND(SP, 1);
	        XST_mPV( 0, folder);
        	XSRETURN(1);
		} else {
			XSRETURN_NO;
		}
    } else {
        XSRETURN_NO;
    }


    ###########################################################################
    # (@)METHOD:ChooseColor(%OPTIONS)
    # Allowed %OPTIONS are:
    #  -owner
    #  -color
void
ChooseColor(...)
PPCODE:
    CHOOSECOLOR cc;
    COLORREF lpCustColors[16];
    BOOL retval;
    int i, next_i;
    unsigned int lpstrlen;
    char * option;

    ZeroMemory(&cc, sizeof(CHOOSECOLOR));
    cc.lStructSize = sizeof(CHOOSECOLOR);
    cc.hwndOwner = NULL;
    cc.lpCustColors = lpCustColors;
    cc.lpTemplateName = NULL;
    cc.Flags = 0;
    cc.rgbResult = 0;

    next_i = -1;
    for(i = 0; i < items; i++) {
        if(next_i == -1) {
			option = SvPV_nolen(ST(i));
            if(strcmp(option, "-owner") == 0) {
                next_i = i + 1;
                cc.hwndOwner = (HWND) handle_From(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-color") == 0) {
                next_i = i + 1;
                cc.rgbResult = (COLORREF) SvCOLORREF(NOTXSCALL ST(next_i));
                cc.Flags = cc.Flags | CC_RGBINIT;
            }
        } else {
            next_i = -1;
        }
    }

    retval = ChooseColor(&cc);

    if(retval) {
        EXTEND(SP, 1);
        XST_mIV(0, cc.rgbResult);
        XSRETURN(1);
    } else {
        XSRETURN_NO;
    }


    ###########################################################################
    # (@)METHOD:ChooseFont(%OPTIONS)
    # Allowed %OPTIONS are:
    #  -owner
    #  -size
    #  -height
    #  -width
    #  -escapement
    #  -orientation
    #  -weight
    #  -bold
    #  -italic
    #  -underline
    #  -strikeout
    #  -charset
    #  -outputprecision
    #  -clipprecision
    #  -quality
    #  -family
    #  -name
    #  -face (== -name)
    #  -color
    #  -ttonly
    #  -fixedonly
    #  -effects
    #  -script
    #  -minsize
    #  -maxsize
void
ChooseFont(...)
PPCODE:
    CHOOSEFONT cf;
    static LOGFONT lf;
    BOOL retval;
    int i, next_i;
    char *option;
    unsigned int lpstrlen;

    ZeroMemory(&cf, sizeof(CHOOSEFONT));
    cf.lStructSize = sizeof(CHOOSEFONT);
    cf.hwndOwner = NULL;
    cf.lpLogFont = &lf;
    cf.lpTemplateName = NULL;
    cf.Flags = CF_SCREENFONTS;

    next_i = -1;
    for(i = 0; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-owner") == 0) {
                next_i = i + 1;
                cf.hwndOwner = (HWND) handle_From(NOTXSCALL ST(next_i));
            }
            if(strcmp(option, "-size") == 0) {
                next_i = i + 1;
                cf.iPointSize = SvIV(ST(next_i));
            }
            if(strcmp(option, "-height") == 0) {
                next_i = i + 1;
                lf.lfHeight = SvIV(ST(next_i));
                SwitchFlag(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);

            }
            if(strcmp(option, "-width") == 0) {
                next_i = i + 1;
                lf.lfWidth = SvIV(ST(next_i));
                SwitchFlag(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-escapement") == 0) {
                next_i = i + 1;
                lf.lfEscapement = SvIV(ST(next_i));
                SwitchFlag(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-orientation") == 0) {
                next_i = i + 1;
                lf.lfOrientation = SvIV(ST(next_i));
                SwitchFlag(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-weight") == 0) {
                next_i = i + 1;
                lf.lfWeight = (int) SvIV(ST(next_i));
                SwitchFlag(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-bold") == 0) {
                next_i = i + 1;
                if(SvIV(ST(next_i)) != 0) lf.lfWeight = 700;
                SwitchFlag(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-italic") == 0) {
                next_i = i + 1;
                lf.lfItalic = (BYTE) SvIV(ST(next_i));
                SwitchFlag(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-underline") == 0) {
                next_i = i + 1;
                lf.lfUnderline = (BYTE) SvIV(ST(next_i));
                SwitchFlag(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-strikeout") == 0) {
                next_i = i + 1;
                lf.lfStrikeOut = (BYTE) SvIV(ST(next_i));
                SwitchFlag(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-charset") == 0) {
                next_i = i + 1;
                lf.lfCharSet = (BYTE) SvIV(ST(next_i));
                SwitchFlag(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-outputprecision") == 0) {
                next_i = i + 1;
                lf.lfOutPrecision = (BYTE) SvIV(ST(next_i));
                SwitchFlag(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-clipprecision") == 0) {
                next_i = i + 1;
                lf.lfClipPrecision = (BYTE) SvIV(ST(next_i));
                SwitchFlag(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-quality") == 0) {
                next_i = i + 1;
                lf.lfQuality = (BYTE) SvIV(ST(next_i));
                SwitchFlag(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-family") == 0) {
                next_i = i + 1;
                lf.lfPitchAndFamily = (BYTE) SvIV(ST(next_i));
                SwitchFlag(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-name") == 0
            || strcmp(option, "-face") == 0) {
                next_i = i + 1;
                strncpy(lf.lfFaceName, SvPV_nolen(ST(next_i)), 32);
                SwitchFlag(cf.Flags, CF_INITTOLOGFONTSTRUCT, 1);
            }
            if(strcmp(option, "-color") == 0) {
                next_i = i + 1;
                cf.rgbColors = (DWORD) SvCOLORREF(NOTXSCALL ST(next_i));
                SwitchFlag(cf.Flags, CF_EFFECTS, 1);
            }
            if(strcmp(option, "-ttonly") == 0) {
                next_i = i + 1;
                SwitchFlag(cf.Flags, CF_TTONLY, SvIV(ST(next_i)));
            }
            if(strcmp(option, "-fixedonly") == 0) {
                next_i = i + 1;
                SwitchFlag(cf.Flags, CF_FIXEDPITCHONLY, SvIV(ST(next_i)));
            }
            if(strcmp(option, "-effects") == 0) {
                next_i = i + 1;
                SwitchFlag(cf.Flags, CF_EFFECTS, SvIV(ST(next_i)));
            }
            if(strcmp(option, "-script") == 0) {
                next_i = i + 1;
                if(SvIV(ST(next_i)) == 0) {
                    SwitchFlag(cf.Flags, CF_NOSCRIPTSEL, 1);
                } else {
                    SwitchFlag(cf.Flags, CF_NOSCRIPTSEL, 0);
                }
            }
            if(strcmp(option, "-minsize") == 0) {
                next_i = i + 1;
                cf.nSizeMin = SvIV(ST(next_i));
                SwitchFlag(cf.Flags, CF_LIMITSIZE, 1);
            }
            if(strcmp(option, "-maxsize") == 0) {
                next_i = i + 1;
                cf.nSizeMax = SvIV(ST(next_i));
                SwitchFlag(cf.Flags, CF_LIMITSIZE, 1);
            }


        } else {
            next_i = -1;
        }
    }
    retval = ChooseFont(&cf);
    if(retval) {
        EXTEND(SP, 18);
        XST_mPV( 0, "-name");
        XST_mPV( 1, lf.lfFaceName);
        XST_mPV( 2, "-height");
        XST_mIV( 3, lf.lfHeight);
        XST_mPV( 4, "-width");
        XST_mIV( 5, lf.lfWidth);
        XST_mPV( 6, "-weight");
        XST_mIV( 7, lf.lfWeight);
        XST_mPV( 8, "-size");
        XST_mIV( 9, cf.iPointSize);
        XST_mPV(10, "-italic");
        XST_mIV(11, lf.lfItalic);
        XST_mPV(12, "-underline");
        XST_mIV(13, lf.lfUnderline);
        XST_mPV(14, "-strikeout");
        XST_mIV(15, lf.lfStrikeOut);
        XST_mPV(16, "-color");
        XST_mIV(17, cf.rgbColors);
        // XST_mPV(18, "-style");
        // XST_mPV(19, cf.lpszStyle);
        // XSRETURN(20);
        XSRETURN(18);
    } else
        XSRETURN_NO;


    ###########################################################################
    # (@)METHOD:CommDlgExtendedError()
    # Returns the common dialog library error code.
DWORD
CommDlgExtendedError(...)
CODE:
    RETVAL = CommDlgExtendedError();
OUTPUT:
    RETVAL


HGDIOBJ
SelectObject(handle,hgdiobj)
    HWND handle
    HGDIOBJ hgdiobj
CODE:
    RETVAL = SelectObject(handle, hgdiobj);
OUTPUT:
    RETVAL

BOOL
DeleteObject(hgdiobj)
    HGDIOBJ hgdiobj
CODE:
    RETVAL = DeleteObject(hgdiobj);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetStockObject(OBJECT)
HGDIOBJ
GetStockObject(object)
    int object
CODE:
    RETVAL = GetStockObject(object);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetSystemMetrics(INDEX)
int
GetSystemMetrics(index)
    int index
CODE:
    RETVAL = GetSystemMetrics(index);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:CreateMenu()
HMENU
CreateMenu(...)
CODE:
    RETVAL = CreateMenu();
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:CreatePopupMenu()
HMENU
CreatePopupMenu(...)
CODE:
    RETVAL = CreatePopupMenu();
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:SetMenu(MENU)
    # Associates the specified MENU to a window.
BOOL
SetMenu(handle,menu)
    HWND handle
    HMENU menu
CODE:
    RETVAL = SetMenu(handle, menu);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetMenu()
HMENU
GetMenu(handle)
    HWND handle
CODE:
    RETVAL = GetMenu(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:DrawMenuBar()
BOOL
DrawMenuBar(handle)
    HWND handle
CODE:
    RETVAL = DrawMenuBar(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:DestroyMenu(HANDLE)
BOOL
DestroyMenu(hmenu)
    HMENU hmenu
CODE:
    RETVAL = DestroyMenu(hmenu);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetFontName()
LPTSTR
GetFontName(handle)
    HWND handle
PREINIT:
    HDC hdc;
    char facename[256];
CODE:
    hdc = GetDC(handle);
    if(GetTextFace(hdc, 256, facename)) {
        RETVAL = (LPTSTR) facename;
    } else {
        RETVAL = "";
    }
    ReleaseDC(handle, hdc);
OUTPUT:
    RETVAL


    ###########################################################################
	# (@)INTERNAL:CreateAcceleratorTable(ID, KEY, FLAG, ...)
HACCEL
CreateAcceleratorTable(...)
PREINIT:
	LPACCEL acc;
	int a, c, i;
CODE:
	a = items/3;
	acc = (LPACCEL) safemalloc(a * sizeof(ACCEL));
	c = 0;
	for(i=0; i<items; i+=3) {
		acc[c].cmd   = (WORD) SvIV(ST(i));
		acc[c].key   = (WORD) SvIV(ST(i+1));
		acc[c].fVirt = (BYTE) SvIV(ST(i+2));
		c++;
	}
	RETVAL = CreateAcceleratorTable(acc, a);
OUTPUT:
	RETVAL


    ###########################################################################
	# (@)INTERNAL:DestroyAcceleratorTable(HANDLE)
BOOL
DestroyAcceleratorTable(handle)
	HACCEL handle;
CODE:
	RETVAL = DestroyAcceleratorTable(handle);
OUTPUT:
	RETVAL


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Menu
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::Menu


    ###########################################################################
    # (@)INTERNAL:DESTROY(HANDLE)
BOOL
DESTROY(handle)
    HMENU handle
CODE:
    RETVAL = DestroyMenu(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::MenuButton
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::MenuButton


    ###########################################################################
    # (@)INTERNAL:InsertMenuItem(HANDLE, %OPTIONS)
BOOL
InsertMenuItem(...)
PREINIT:
    MENUITEMINFO myMII;
    int i, next_i;
    UINT myItem;
CODE:
    ZeroMemory(&myMII, sizeof(MENUITEMINFO));
    myMII.cbSize = sizeof(MENUITEMINFO);
    myItem = 0;

    ParseMenuItemOptions(NOTXSCALL sp, mark, ax, items, 1, &myMII, &myItem);

    myMII.hbmpChecked = NULL;
    myMII.hbmpUnchecked = NULL;

    RETVAL = InsertMenuItem(
        (HMENU) handle_From(NOTXSCALL ST(0)),
        myItem,
        FALSE,
        &myMII
    );
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::MenuItem
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::MenuItem


    ###########################################################################
    # (@)METHOD:Change(%OPTIONS)
    # Change most of the options used when the object was created.
void
Change(...)
PPCODE:
    MENUITEMINFO myMII;
    int i, next_i;
    UINT myItem;
    HMENU hMenu;
    SV** parentmenu;
    char tmpmenutext[1024];
    if(SvROK(ST(0))) {
        parentmenu = hv_fetch((HV*)SvRV((ST(0))), "-menu", 5, 0);
        if(parentmenu != NULL) {
            hMenu = (HMENU) SvIV(*parentmenu);
            myItem = SvIV(*(hv_fetch((HV*)SvRV(ST(0)), "-id", 3, 0)));
        } else {
            hMenu = (HMENU) handle_From(NOTXSCALL ST(0));
        }
    }
#ifdef PERLWIN32GUI_DEBUG
	    printf("XS(MenuItem::Change): hMenu=%ld\n", hMenu);
#endif
#ifdef PERLWIN32GUI_DEBUG
	    printf("XS(MenuItem::Change): myItem=%d\n", myItem);
#endif
    ZeroMemory(&myMII, sizeof(MENUITEMINFO));
    myMII.cbSize = sizeof(MENUITEMINFO);
    myMII.fMask = MIIM_STATE | MIIM_SUBMENU | MIIM_TYPE;
    myMII.dwTypeData = tmpmenutext;
    myMII.cch = 1024;
    if(GetMenuItemInfo(hMenu, myItem, FALSE, &myMII)) {
        myMII.fMask = 0;
        ParseMenuItemOptions(NOTXSCALL sp, mark, ax, items, 1, &myMII, &myItem);
        myMII.hbmpChecked = NULL;
        myMII.hbmpUnchecked = NULL;
        XSRETURN_IV(
			SetMenuItemInfo(hMenu, myItem, FALSE, &myMII)
		);
    } else
        XSRETURN_NO;


    ###########################################################################
    # (@)METHOD:Checked(...)
void
Checked(...)
PPCODE:
    MENUITEMINFO myMII;
    int i;
    UINT myItem;
    HMENU hMenu;
    SV** parentmenu;

    if(SvROK(ST(0))) {
        parentmenu = hv_fetch((HV*)SvRV((ST(0))), "-menu", 5, 0);
        if(parentmenu != NULL) {
            hMenu = (HMENU) SvIV(*parentmenu);
            myItem = SvIV(*(hv_fetch((HV*)SvRV(ST(0)), "-id", 3, 0)));
            i = 1;
        } else {
            hMenu = (HMENU) handle_From(NOTXSCALL ST(0));
            myItem = SvIV(ST(1));
            i = 2;
        }
    }
    ZeroMemory(&myMII, sizeof(MENUITEMINFO));
    myMII.cbSize = sizeof(MENUITEMINFO);
    myMII.fMask = MIIM_STATE;
    if(GetMenuItemInfo(hMenu, myItem, FALSE, &myMII)) {
        if(items > i) {
            myMII.fMask = MIIM_STATE;
            SwitchFlag(myMII.fState, MFS_CHECKED, SvIV(ST(i)));
            XSRETURN_IV(
				SetMenuItemInfo(hMenu, myItem, FALSE, &myMII)
			);
        } else {
            XSRETURN_IV((myMII.fState & MFS_CHECKED) ? 1 : 0);
        }
    } else {
        XSRETURN_NO;
    }


    ###########################################################################
    # (@)METHOD:Enabled(...)
void
Enabled(...)
PPCODE:
    MENUITEMINFO myMII;
    int i, x;
    UINT myItem;
    HMENU hMenu;
    SV** parentmenu;

    if(SvROK(ST(0))) {
        parentmenu = hv_fetch((HV*)SvRV((ST(0))), "-menu", 5, 0);
        if(parentmenu != NULL) {
            hMenu = (HMENU) SvIV(*parentmenu);
            myItem = SvIV(*(hv_fetch((HV*)SvRV(ST(0)), "-id", 3, 0)));
            i = 1;
        } else {
            hMenu = (HMENU) handle_From(NOTXSCALL ST(0));
            myItem = SvIV(ST(1));
            i = 2;
        }
    }
    ZeroMemory(&myMII, sizeof(MENUITEMINFO));
    myMII.cbSize = sizeof(MENUITEMINFO);
    myMII.fMask = MIIM_STATE;
    if(GetMenuItemInfo(hMenu, myItem, FALSE, &myMII)) {
        if(items > i) {
            myMII.fMask = MIIM_STATE;
            x = (SvIV(ST(i))) ? 0 : 1;
            SwitchFlag(myMII.fState, MFS_DISABLED, x);
            XSRETURN_IV(
				SetMenuItemInfo(hMenu, myItem, FALSE, &myMII)
			);
        } else {
            XSRETURN_IV((myMII.fState & MFS_DISABLED) ? 0 : 1);
        }
    } else {
        XSRETURN_NO;
    }


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::DialogBox
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::DialogBox

    # DWORD
    # Dialog(...)
    # PPCODE:
    #     HWND hwnd;
    #     MSG msg;
    #     int stayhere;
    #     stayhere = 1;
    #
    #     if(items > 0) {
    #         hwnd = (HWND) handle_From(NOTXSCALL ST(0));
    #     } else {
    #         hwnd = NULL;
    #     }
    #
    #     while (stayhere) {
    #         stayhere = GetMessage(&msg, hwnd, 0, 0);
    #         if(msg.message == WM_EXITLOOP) {
    #             stayhere = 0;
    #             msg.wParam = -1;
    #         } else {
    #             if(stayhere == -1) {
    #                 stayhere = 0;
    #                 msg.wParam = -2; // an error occurred...
    #             } else {
    #                 if(!IsDialogMessage(hwnd, &msg)) {
    #                     TranslateMessage(&msg);
    #                     DispatchMessage(&msg);
    #                 }
    #             }
    #         }
    #     }
    #     XSRETURN_IV((long) msg.wParam);


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Textfield
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::Textfield


    ###########################################################################
    # (@)METHOD:ReplaceSel(STRING, [FLAG])
LRESULT
ReplaceSel(handle,string,flag=TRUE)
    HWND handle
    LPCTSTR string
    BOOL flag
CODE:
    RETVAL = SendMessage(
        handle, EM_REPLACESEL, (WPARAM) flag, (LPARAM) string
    );
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:ReadOnly([FLAG])
BOOL
ReadOnly(handle,...)
    HWND handle
CODE:
    if(items > 1)
        RETVAL = SendMessage(
            handle, EM_SETREADONLY, (WPARAM) (BOOL) SvIV(ST(1)), 0
        );
    else
        RETVAL = (GetWindowLong(handle, GWL_STYLE) & ES_READONLY);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Modified([FLAG])
BOOL
Modified(handle,...)
    HWND handle
CODE:
    if(items > 1)
        RETVAL = SendMessage(
            handle, EM_SETMODIFY, (WPARAM) (UINT) SvIV(ST(1)), 0
        );
    else
        RETVAL = SendMessage(handle, EM_GETMODIFY, 0, 0);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Undo()
BOOL
Undo(handle)
    HWND handle
CODE:
    if (SendMessage(handle, EM_CANUNDO, 0, 0))
        RETVAL = SendMessage(handle, EM_UNDO, 0, 0);
    else
        RETVAL = 0;
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:LineFromChar(INDEX)
LRESULT
LineFromChar(handle,index)
    HWND handle
    WPARAM index
CODE:
    RETVAL = SendMessage(handle, EM_EXLINEFROMCHAR, index, 0);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:PasswordChar([CHAR])
LRESULT
PasswordChar(handle,passchar=0)
    HWND handle
    UINT passchar
CODE:
    if(items == 1) {
        RETVAL = SendMessage(handle, EM_GETPASSWORDCHAR, 0, 0);
    } else {
        RETVAL = SendMessage(handle, EM_SETPASSWORDCHAR, (WPARAM) passchar, 0);
    }
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Selection()
void
Selection(handle)
    HWND handle
PREINIT:
    DWORD start;
    DWORD end;
PPCODE:
    SendMessage(
        handle, EM_GETSEL, (WPARAM) &start, (LPARAM) &end
    );
    EXTEND(SP, 2);
    XST_mIV(0, (long) start);
    XST_mIV(1, (long) end);
    XSRETURN(2);


    ###########################################################################
    # (@)METHOD:Scroll(COMMAND | LINE | HORIZONTAL, VERTICAL)
LRESULT
Scroll(handle, line, otherdirection=NULL)
    SV* handle
    SV* line
    DWORD otherdirection
PREINIT:
	HWND hwnd;
    WPARAM wparam;
    char *arg;
    POINT pt;
CODE:
	hwnd = handle_From(NOTXSCALL handle);
	if(items == 2) {
		if(SvPOK(line)) {
			arg = strlwr( SvPV_nolen(line) );

			if(0 == strcmp( arg, "bottom" )) {
				RETVAL = SendMessage( hwnd, EM_GETLINECOUNT, 0, 0 );
				wparam = RETVAL;
				RETVAL = SendMessage( hwnd, EM_GETFIRSTVISIBLELINE, 0, 0);
				wparam -= RETVAL;
				RETVAL = SendMessage( hwnd, EM_LINESCROLL, 0, wparam);
			} else if(0 == strcmp( arg, "top" )) {
				wparam = SendMessage( hwnd, EM_GETFIRSTVISIBLELINE, 0, 0);
				RETVAL = SendMessage( hwnd, EM_LINESCROLL, 0, -wparam);
			} else {
				if(0 == strcmp( arg, "up" )) {
					wparam = SB_LINEUP;
				} else if(0 == strcmp( arg, "down" )
				||        0 == strcmp( arg, "dn" )) {
					wparam = SB_LINEDOWN;
				} else if(0 == strcmp( arg, "pageup" )
				||        0 == strcmp( arg, "pgup" )) {
					wparam = SB_PAGEUP;
				} else if(0 == strcmp( arg, "pagedown" )
				||        0 == strcmp( arg, "pagedn" )
				||        0 == strcmp( arg, "pgdown" )
				||        0 == strcmp( arg, "pgdn")) {
					wparam = SB_PAGEDOWN;
				}
				RETVAL = SendMessage(
					hwnd, EM_SCROLL, (WPARAM) wparam, (LPARAM) 0
				);
			}
		} else {
			RETVAL = SendMessage(
				hwnd, EM_LINESCROLL, 0, (WPARAM) SvIV(line)
			);
		}
	} else {
		if(sv_derived_from(handle, "Win32::GUI::RichEdit")) {
			RETVAL = SendMessage(
				hwnd, EM_LINESCROLL, 0, (WPARAM) otherdirection
			);
		} else {
			RETVAL = SendMessage(
				hwnd, EM_LINESCROLL, (LPARAM) SvIV(line), (WPARAM) otherdirection
			);
		}
	}
	SendMessage( handle, EM_SCROLLCARET, 0, 0);
OUTPUT:
	RETVAL

    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Listbox
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::Listbox


    ###########################################################################
    # (@)METHOD:AddString(STRING)
LRESULT
AddString(handle,string)
    HWND handle
    LPCTSTR string
CODE:
    RETVAL = SendMessage(handle, LB_ADDSTRING, 0, (LPARAM) string);
OUTPUT:
    RETVAL

	###########################################################################
    # (@)METHOD:Add(STRING, STRING .. STRING)
void
Add(handle,...)
    HWND handle
PREINIT:
	int i;
	LRESULT res;
CODE:
	for(i = 1; i < items; i++) {
		SendMessage(handle, LB_ADDSTRING, 0, (LPARAM) (LPCTSTR) SvPV_nolen(ST(i)));
	}

    ###########################################################################
    # (@)METHOD:InsertItem(STRING, [INDEX])
    # Inserts an item at the specified zero-based INDEX in the Listbox,
    # or adds it at the end if INDEX is not specified.
LRESULT
InsertItem(handle,string,index=-1)
    HWND handle
    LPCTSTR string
    WPARAM index
CODE:
    RETVAL = SendMessage(handle, LB_INSERTSTRING, index, (LPARAM) string);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetString(INDEX)
    # Returns the string at the specified zero-based INDEX in the Listbox.
void
GetString(handle,index)
    HWND handle
    WPARAM index
PREINIT:
    STRLEN cbString;
    char *szString;
PPCODE:
    cbString = SendMessage(handle, LB_GETTEXTLEN, index, 0);
	if(cbString != LB_ERR) {
		szString = (char *) safemalloc(cbString);
		if(SendMessage(handle, LB_GETTEXT,
					   index, (LPARAM) (LPCTSTR) szString) != LB_ERR) {
			EXTEND(SP, 1);
			XST_mPV(0, szString);
			safefree(szString);
			XSRETURN(1);
		} else {
			safefree(szString);
			XSRETURN_NO;
		}
	} else {
		XSRETURN_NO;
	}

    ###########################################################################
    # (@)METHOD:ItemHeight([HEIGHT])
    # Gets or sets the items height in a Listbox.
LRESULT
ItemHeight(handle,height=-1)
    HWND handle
    long height
CODE:
    if(items == 1) {
        RETVAL = SendMessage(handle, LB_GETITEMHEIGHT, 0, 0);
    } else {
        RETVAL = SendMessage(handle, LB_SETITEMHEIGHT, 0, MAKELPARAM(height, 0));
    }
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:FirstVisibleItem([INDEX])
LRESULT
FirstVisibleItem(handle,index=-1)
    HWND handle
    WPARAM index
CODE:
    if(items == 1)
        RETVAL = SendMessage(handle, LB_GETTOPINDEX, 0, 0);
    else
        RETVAL = SendMessage(handle, LB_SETTOPINDEX, index, 0);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:ItemFromPoint(X, Y)
void
ItemFromPoint(handle,x,y)
    HWND handle
    UINT x
    UINT y
PREINIT:
    LRESULT lresult;
PPCODE:
    lresult = SendMessage(handle, LB_ITEMFROMPOINT, 0, (LPARAM) MAKELPARAM(x, y));
    if(GIMME == G_ARRAY) {
        EXTEND(SP, 2);
        XST_mIV(0, (long) LOWORD(lresult));
        if(HIWORD(lresult) == 0)
            XST_mIV(1, 1);
        else
            XST_mIV(1, 0);
        XSRETURN(2);
    } else {
        XSRETURN_IV((long) LOWORD(lresult));
    }


    ###########################################################################
    # (@)METHOD:SelectString(STRING, [INDEX])
LRESULT
SelectString(handle,string,index=-1)
    HWND handle
    LPCTSTR string
    WPARAM index
CODE:
    RETVAL = SendMessage(handle, LB_SELECTSTRING, index, (LPARAM) string);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:FindString(STRING, [INDEX])
LRESULT
FindString(handle,string,index=-1)
    HWND handle
    LPCTSTR string
    WPARAM index
CODE:
    RETVAL = SendMessage(handle, LB_FINDSTRING, index, (LPARAM) string);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:FindStringExact(STRING, [INDEX])
LRESULT
FindStringExact(handle,string,index=-1)
    HWND handle
    LPCTSTR string
    WPARAM index
CODE:
    RETVAL = SendMessage(handle, LB_FINDSTRINGEXACT, index, (LPARAM) string);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:SelectCount()
LRESULT
SelectCount(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, LB_GETSELCOUNT, 0, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SelectedItems()
    # Returns an array containing the zero-based indexes of the selected items
    # in a multiple selection Listbox.
void
SelectedItems(handle)
    HWND handle
PREINIT:
    LRESULT count;
    LRESULT lresult;
    LPINT selitems;
    int i;
PPCODE:
    count = SendMessage(handle, LB_GETSELCOUNT, 0, 0);
    if(count > 0) {
        selitems = (LPINT) safemalloc(sizeof(INT)*count);
        lresult = SendMessage(handle, LB_GETSELITEMS, (WPARAM) count, (LPARAM) selitems);
        if(lresult == -1) {
            XSRETURN_NO;
        } else {
            EXTEND(SP, lresult);
            for(i=0; i<lresult; i++) {
                XST_mIV(i, (long) selitems[i]);
            }
            safefree(selitems);
            XSRETURN(lresult);
        }
    } else {
        XSRETURN_NO;
    }

    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Combobox
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::Combobox


    ###########################################################################
    # (@)METHOD:AddString(STRING)
    # Adds an item at the end of the control's list.
LRESULT
AddString(handle,string)
    HWND handle
    LPCTSTR string
CODE:
    RETVAL = SendMessage(handle, CB_ADDSTRING, 0, (LPARAM) string);
OUTPUT:
    RETVAL

	###########################################################################
    # (@)METHOD:Add(STRING, STRING .. STRING)
    # Adds one or more items at the end of the control's list.
void
Add(handle,...)
    HWND handle
PREINIT:
	int i;
	LRESULT res;
CODE:
	for(i = 1; i < items; i++) {
		SendMessage(handle, CB_ADDSTRING, 0, (LPARAM) (LPCTSTR) SvPV_nolen(ST(i)));
	}

    ###########################################################################
    # (@)METHOD:InsertItem(STRING, [INDEX])
    # Inserts an item at the specified zero-based INDEX in the Combobox,
    # or adds it at the end if INDEX is not specified.
LRESULT
InsertItem(handle,string,index=-1)
    HWND handle
    LPCTSTR string
    WPARAM index
CODE:
    RETVAL = SendMessage(handle, CB_INSERTSTRING, index, (LPARAM) string);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetString(INDEX)
    # Returns the string at the specified zero-based INDEX in the Combobox.
void
GetString(handle,index)
    HWND handle
    WPARAM index
PREINIT:
    STRLEN cbString;
    char *szString;
PPCODE:
    cbString = SendMessage(handle, CB_GETLBTEXTLEN, index, 0);
	if(cbString != LB_ERR) {
		szString = (char *) safemalloc(cbString);
		if(SendMessage(handle, CB_GETLBTEXT,
					   index, (LPARAM) (LPCTSTR) szString) != LB_ERR) {
			EXTEND(SP, 1);
			XST_mPV(0, szString);
			safefree(szString);
			XSRETURN(1);
		} else {
			safefree(szString);
			XSRETURN_NO;
		}
	} else {
		XSRETURN_NO;
	}

    ###########################################################################
    # (@)METHOD:ItemHeight([HEIGHT])
    # Gets or sets the items height in a Combobox.
LRESULT
ItemHeight(handle,height=-1)
    HWND handle
    long height
CODE:
    if(items == 1) {
        RETVAL = SendMessage(handle, LB_GETITEMHEIGHT, 0, 0);
    } else {
        RETVAL = SendMessage(handle, LB_SETITEMHEIGHT, 0, MAKELPARAM(height, 0));
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:FirstVisibleItem([INDEX])
LRESULT
FirstVisibleItem(handle,index=-1)
    HWND handle
    WPARAM index
CODE:
    if(items == 1)
        RETVAL = SendMessage(handle, CB_GETTOPINDEX, 0, 0);
    else
        RETVAL = SendMessage(handle, CB_SETTOPINDEX, index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:FindString(STRING, [INDEX])
LRESULT
FindString(handle,string,index=-1)
    HWND handle
    LPCTSTR string
    WPARAM index
CODE:
    RETVAL = SendMessage(handle, CB_FINDSTRING, index, (LPARAM) string);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:FindStringExact(STRING, [INDEX])
LRESULT
FindStringExact(handle,string,index=-1)
    HWND handle
    LPCTSTR string
    WPARAM index
CODE:
    RETVAL = SendMessage(handle, CB_FINDSTRINGEXACT, index, (LPARAM) string);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::TabStrip
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::TabStrip


    ###########################################################################
    # (@)METHOD:InsertItem(%OPTIONS)
    # Adds an item to the TabStrip.
    # Allowed %OPTIONS are:
    #  -image => NUMBER
    #    the index of an image from the associated ImageList
    #  -index => NUMBER
    #    the position for the new item (if not specified, the item
    #    is added at the end of the control)
    #  -text  => STRING
    #    the text that will appear on the item
int
InsertItem(handle,...)
    HWND handle
PREINIT:
    TC_ITEM Item;
    int iIndex;
    int iText;
    unsigned int chText;
    int i, next_i;
CODE:
    ZeroMemory(&Item, sizeof(TC_ITEM));
    iIndex = TabCtrl_GetItemCount(handle)+1;
    next_i = -1;
    for(i = 1; i < items; i++) {
        if(next_i == -1) {
            if(strcmp(SvPV_nolen(ST(i)), "-image") == 0) {
                next_i = i + 1;
                Item.mask = Item.mask | TCIF_IMAGE;
                Item.iImage = SvIV(ST(next_i));
            }
            if(strcmp(SvPV_nolen(ST(i)), "-index") == 0) {
                next_i = i + 1;
                iIndex = (int) SvIV(ST(next_i));
            }
            if(strcmp(SvPV_nolen(ST(i)), "-text") == 0) {
                next_i = i + 1;
                Item.pszText = SvPV(ST(next_i), chText);
                Item.cchTextMax = (int) chText;
                Item.mask = Item.mask | TCIF_TEXT;
            }
        } else {
            next_i = -1;
        }
    }
    RETVAL = TabCtrl_InsertItem(handle, iIndex, &Item);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:ChangeItem(ITEM, %OPTIONS)
    # Change most of the options used when the item was created
    # (see InsertItem()).
    # Allowed %OPTIONS are:
    #     -image
    #     -text
BOOL
ChangeItem(handle,item,...)
    HWND handle
    int item
PREINIT:
    TC_ITEM Item;
    int iIndex;
    int iText;
    unsigned int chText;
    int i, next_i;
CODE:
    ZeroMemory(&Item, sizeof(TC_ITEM));
    next_i = -1;
    for(i = 2; i < items; i++) {
        if(next_i == -1) {
            if(strcmp(SvPV_nolen(ST(i)), "-image") == 0) {
                next_i = i + 1;
                Item.mask = Item.mask | TCIF_IMAGE;
                Item.iImage = SvIV(ST(next_i));
            }
            if(strcmp(SvPV_nolen(ST(i)), "-text") == 0) {
                next_i = i + 1;
                Item.pszText = SvPV(ST(next_i), chText);
                Item.cchTextMax = (int) chText;
                Item.mask = Item.mask | TCIF_TEXT;
            }
        } else {
            next_i = -1;
        }
    }
    RETVAL = TabCtrl_SetItem(handle, item, &Item);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Count()
    # Returns the number of items in the TabStrip.
int
Count(handle)
    HWND handle
CODE:
    RETVAL = TabCtrl_GetItemCount(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Reset()
    # Deletes all items from the TabStrip.
BOOL
Reset(handle)
    HWND handle
CODE:
    RETVAL = TabCtrl_DeleteAllItems(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:DeleteItem(ITEM)
    # Removes the specified ITEM from the TabStrip.
BOOL
DeleteItem(handle,item)
    HWND handle
    int item
CODE:
    RETVAL = TabCtrl_DeleteItem(handle, item);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetString(ITEM)
    # Returns the string associated with the specified ITEM in the TabStrip.
void
GetString(handle,item)
    HWND handle
    int item
PREINIT:
    char *szString;
    TC_ITEM tcItem;
PPCODE:
    szString = (char *) safemalloc(1024);
    tcItem.pszText = szString;
    tcItem.cchTextMax = 1024;
    tcItem.mask = TCIF_TEXT;
    if(TabCtrl_GetItem(handle, item, &tcItem)) {
        EXTEND(SP, 1);
        XST_mPV(0, szString);
        safefree(szString);
        XSRETURN(1);
    } else {
        safefree(szString);
        XSRETURN_NO;
    }

    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Toolbar
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::Toolbar


    ###########################################################################
    # (@)METHOD:AddBitmap(BITMAP, NUMBUTTONS)
LRESULT
AddBitmap(handle,bitmap,numbuttons)
    HWND handle
    HBITMAP bitmap
    WPARAM numbuttons
PREINIT:
    TBADDBITMAP TbAddBitmap;
CODE:
    TbAddBitmap.hInst = (HINSTANCE) NULL;
    TbAddBitmap.nID = (UINT) bitmap;

    RETVAL = SendMessage(handle, TB_ADDBITMAP, numbuttons,
                         (LPARAM) (LPTBADDBITMAP) &TbAddBitmap);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:AddString(STRING)
LRESULT
AddString(handle,string)
    HWND handle
    char * string
PREINIT:
    char *Strings;
    int i;
    unsigned int szLen, totLen;
    LPARAM lParam;
CODE:
    totLen = 0;
    #    // the function should accept an array of strings,
    #    // but actually doesn't work...
    #
    #    for(i = 1; i < items; i++) {
    #        Strings = SvPV(ST(i), szLen);
    #        __DEBUG("AddString: szLen(%d) = %d\n", i, szLen);
    #        totLen += szLen+1;
    #    }
    #    totLen++;
    #    __DEBUG("AddString: totLen = %d\n", totLen);
    #    Strings = (char *) safemalloc(totLen);
    #
    #    totLen = 0;
    #    char *tmpStrings = Strings;
    #    for(i = 1; i < items; i++) {
    #        strcat(tmpStrings, SvPV(ST(i), szLen));
    #        totLen += szLen+1;
    #
    #    }
    #    Strings[totLen++] = '\0';
    // only one string allowed
    Strings = SvPV(ST(1), szLen);
    Strings = (char *) safemalloc(szLen+2);
    strcpy(Strings, string);
    Strings[szLen+1] = '\0';
#ifdef PERLWIN32GUI_DEBUG
	    printf("XS(Toolbar::AddString): Strings='%s', len=%d\n", Strings, szLen);
#endif
#ifdef PERLWIN32GUI_DEBUG
    for(i=0; i<=szLen+1; i++) {
        printf("XS(Toolbar::AddString): Strings[%d]='%d'\n", i, Strings[i]);
    }
#endif
    lParam = (LPARAM) MAKELONG(Strings, 0);
#ifdef PERLWIN32GUI_DEBUG
	    printf("XS(Toolbar::AddString): handle=%ld\n", handle);
#endif
#ifdef PERLWIN32GUI_DEBUG
	    printf("XS(Toolbar::AddString): Strings=%ld\n", Strings);
#endif
#ifdef PERLWIN32GUI_DEBUG
	    printf("XS(Toolbar::AddString): lParam=%ld\n", lParam);
#endif
    RETVAL = SendMessage(handle, TB_ADDSTRING, 0, (LPARAM) Strings);
#ifdef PERLWIN32GUI_DEBUG
	    printf("XS(Toolbar::AddString): SendMessage.result = %ld", RETVAL);
#endif
    safefree(Strings);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:AddButtons(NUMBER, ...)
LRESULT
AddButtons(handle,number,...)
    HWND handle
    UINT number
PREINIT:
    LPTBBUTTON buttons;
    int i, q, b;
CODE:
    if(items != 2 + number * 5) {
        CROAK("AddButtons: wrong number of parameters (expected %d, got %d)!\n", 2+number*5, items);
    }
    buttons = (LPTBBUTTON) safemalloc(sizeof(TBBUTTON)*number);
    q = 0;
    b = 0;
    for(i = 2; i < items; i++) {
        switch(q) {
        case 0:
            buttons[b].iBitmap = (int) SvIV(ST(i));
            break;
        case 1:
            buttons[b].idCommand = (int) SvIV(ST(i));
            break;
        case 2:
            buttons[b].fsState = (BYTE) SvIV(ST(i));
            break;
        case 3:
            buttons[b].fsStyle = (BYTE) SvIV(ST(i));
            break;
        case 4:
            buttons[b].iString = (int) SvIV(ST(i));
        }
        q++;
        if(q == 5) {
            buttons[b].dwData = 0;
            q = 0;
            b++;
        }
    }
    RETVAL = SendMessage(handle, TB_ADDBUTTONS,
                         (WPARAM) number,
                         (LPARAM) (LPTBBUTTON) buttons);
    safefree(buttons);
OUTPUT:
    RETVAL

    # LRESULT
    # AddButton(handle,...)
    #     HWND handle
    # PREINIT:
    #     TBBUTTON button;
    #     TBBUTTONINFO buttoninfo;
    #     int i, next_i;
    #     char *option;
    # CODE:
    #     ZeroMemory(&button, sizeof(TBBUTTON));
    #     ZeroMemory(&buttoninfo, sizeof(TBBUTTONINFO));
    #     buttoninfo.cbSize = sizeof(TBBUTTONINFO);
    #     next_i = -1;
    #     for(i = 2; i < items; i++) {
    #         if(next_i == -1) {
    #             option = SvPV_nolen(ST(i));
    #             if(strcmp(option, "-image") == 0) {
    #                 next_i = i + 1;
    #                 button.iBitmap = SvIV(ST(next_i));
    #             } else
    #             if(strcmp(option, "-text") == 0) {
    #                 next_i = i + 1;
    #                 buttoninfo.dwMask |= TBIF_TEXT;
    #                 buttoninfo.pszText = SvPV_nolen(ST(next_i));
    #             }
    #             // to implement: -style, -state, -id(?)
    #         } else {
    #             next_i = -1;
    #         }
    #     }
    #     RETVAL = FALSE;
    #     # SendMessage(handle, TB_SETBUTTONINFO, (WPARAM) &buttoninfo, 0);
    #     # RETVAL = TabCtrl_SetItem(handle, item, &Item);
    # OUTPUT:
    #     RETVAL


    ###########################################################################
    # (@)INTERNAL:ButtonStructSize()
    # initializes the toolbar button structure size
LRESULT
ButtonStructSize(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, TB_BUTTONSTRUCTSIZE,
                         (WPARAM) sizeof(TBBUTTON), 0);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::RichEdit
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::RichEdit

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
    # (@)METHOD:LineFromChar(INDEX)
    # Returns the line number where the zero-based INDEX character appears.
LRESULT
LineFromChar(handle,index)
    HWND handle
    LPARAM index
CODE:
    RETVAL = SendMessage(handle, EM_EXLINEFROMCHAR, 0, index);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:FirstVisibleLine()
    # Returns the first visible line in the RichEdit control.
LRESULT
FirstVisibleLine(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, EM_GETFIRSTVISIBLELINE, 0, 0);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:ReplaceSel(STRING, [FLAG])
    # Replaces the current selection with the given STRING.
    # The optional FLAG parameter can be set to zero to tell the control that
    # the operation cannot be undone; see also Undo().
LRESULT
ReplaceSel(handle,string,flag=TRUE)
    HWND handle
    LPCTSTR string
    BOOL flag
CODE:
    RETVAL = SendMessage(handle, EM_REPLACESEL,
                         (WPARAM) flag, (LPARAM) string);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Select(START, END)
    # Selects the characters range from START to END.
LRESULT
Select(handle,start,end)
    HWND handle
    LONG start
    LONG end
PREINIT:
    CHARRANGE cr;
CODE:
    ZeroMemory(&cr, sizeof(CHARRANGE));
    cr.cpMin = start;
    cr.cpMax = end;
    RETVAL = SendMessage(
        handle, EM_EXSETSEL, 0, (LPARAM) (CHARRANGE FAR *) &cr
    );
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Selection()
    # Returns a two elements array containing the current selection start
    # and end.
void
Selection(handle)
    HWND handle
PREINIT:
    CHARRANGE cr;
PPCODE:
    ZeroMemory(&cr, sizeof(CHARRANGE));
    SendMessage(
        handle, EM_EXGETSEL, 0, (LPARAM) (CHARRANGE FAR *) &cr
    );
    EXTEND(SP, 2);
    XST_mIV(0, cr.cpMin);
    XST_mIV(1, cr.cpMax);
    XSRETURN(2);


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


    ###########################################################################
    # (@)METHOD:BackColor([COLOR])
LRESULT
BackColor(handle,color=-1)
    HWND handle
    COLORREF color
PREINIT:
    WPARAM flag;
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
    # (@)PACKAGE:Win32::GUI::ListView
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::ListView


    ###########################################################################
    # (@)METHOD:InsertColumn(%OPTIONS)
int
InsertColumn(handle,...)
    HWND handle
PREINIT:
    LV_COLUMN Column;
    unsigned int tlen;
    int i, next_i;
    int iCol;
    char * option;
CODE:
    ZeroMemory(&Column, sizeof(LV_COLUMN));
    next_i = -1;
    for(i = 1; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-text") == 0) {
                next_i = i + 1;
                Column.pszText = SvPV(ST(next_i), tlen);
                Column.cchTextMax = tlen;
                Column.mask |= LVCF_TEXT;
            } else if(strcmp(option, "-align") == 0) {
                next_i = i + 1;
                if(strcmp(SvPV_nolen(ST(next_i)), "right") == 0) {
                    Column.fmt = LVCFMT_RIGHT;
                    Column.mask |= LVCF_FMT;
                } else if(strcmp(SvPV_nolen(ST(next_i)), "left") == 0) {
                    Column.fmt = LVCFMT_LEFT;
                    Column.mask |= LVCF_FMT;
                } else if(strcmp(SvPV_nolen(ST(next_i)), "center") == 0) {
                    Column.fmt = LVCFMT_CENTER;
                    Column.mask |= LVCF_FMT;
                }
            } else if(strcmp(option, "-width") == 0) {
                next_i = i + 1;
                Column.cx = SvIV(ST(next_i));
                Column.mask |= LVCF_WIDTH;
            } else if(strcmp(option, "-index") == 0
            || strcmp(option, "-item") == 0) {
                next_i = i + 1;
                iCol = SvIV(ST(next_i));
            } else if(strcmp(option, "-subitem") == 0) {
                next_i = i + 1;
                Column.iSubItem = SvIV(ST(next_i));
                Column.mask |= LVCF_SUBITEM;
            } else if(strcmp(option, "-image") == 0) {
                next_i = i + 1;
                Column.iImage = SvIV(ST(next_i));
                Column.mask |= LVCF_IMAGE;
            }
        } else {
            next_i = -1;
        }
    }
    if(!Column.mask & LVCF_FMT) {
        Column.fmt = LVCFMT_LEFT;
        Column.mask |= LVCF_FMT;
    }
    // evtl. autofill iCol too...

    RETVAL = ListView_InsertColumn(handle, iCol, &Column);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:InsertItem(%OPTIONS)
    # Inserts a new item in the control.
    # (@)OPT: -image => NUMBER
    # (@)OPT:   index of an image from the associated ImageList
    # (@)OPT: -indent => NUMBER
    # (@)OPT:   how much the item must be indented; one unit
	# (@)OPT:   is the width of an item image, so 2 is twice
	# (@)OPT:   the width of the image, and so on.
	# (@)OPT: -item => NUMBER
	# (@)OPT:   zero-based index for the new item; the default
	# (@)OPT:   is to add the item at the end of the list.
	# (@)OPT: -selected => 0/1, default 0
	# (@)OPT: -text => STRING
	# (@)OPT:   the text for the item
int
InsertItem(handle,...)
    HWND handle
PREINIT:
    LV_ITEM Item;
    unsigned int tlen;
    int i, next_i;
    char * option;
    AV* texts;
	SV** t;
CODE:
	texts = NULL;
    ZeroMemory(&Item, sizeof(LV_ITEM));
	Item.iItem = ListView_GetItemCount(handle);
    next_i = -1;
    for(i = 1; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-text") == 0) {
				next_i = i + 1;
                if(SvROK(ST(next_i)) && SvTYPE(SvRV(ST(next_i))) == SVt_PVAV) {
                    texts = (AV*)SvRV(ST(next_i));
					t = av_fetch(texts, 0, 0);
					if(t != NULL) {
						Item.pszText = SvPV(*t, tlen);
						Item.cchTextMax = tlen;
						SwitchFlag(Item.mask, LVIF_TEXT, 1);
					}
				} else {
					Item.pszText = SvPV(ST(next_i), tlen);
					Item.cchTextMax = tlen;
					SwitchFlag(Item.mask, LVIF_TEXT, 1);
				}
            } else if(strcmp(option, "-item") == 0
            || strcmp(option, "-index") == 0) {
                next_i = i + 1;
                Item.iItem = SvIV(ST(next_i));
            } else if(strcmp(option, "-image") == 0) {
                next_i = i + 1;
                Item.iImage = SvIV(ST(next_i));
				SwitchFlag(Item.mask, LVIF_IMAGE, 1);
            } else if(strcmp(option, "-selected") == 0) {
                next_i = i + 1;
				SwitchFlag(Item.state, LVIS_SELECTED, SvIV(ST(next_i)));
				SwitchFlag(Item.stateMask, LVIS_SELECTED, 1);
				SwitchFlag(Item.mask, LVIF_STATE, 1);
            } else if(strcmp(option, "-indent") == 0) {
                next_i = i + 1;
                Item.iIndent = SvIV(ST(next_i));
				SwitchFlag(Item.mask, LVIF_INDENT, 1);
			}
        } else {
            next_i = -1;
        }
    }
    RETVAL = ListView_InsertItem(handle, &Item);
	if(texts != NULL) {
		for(i=1; i<=av_len(texts); i++) {
			t = av_fetch(texts, i, 0);
			if(t != NULL) {
				Item.pszText = SvPV(*t, tlen);
				Item.cchTextMax = tlen;
				SwitchFlag(Item.mask, LVIF_TEXT, 1);
			}
			Item.iSubItem = i;
			ListView_SetItem(handle, &Item);
		}
	}
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Add(ITEM, ITEM .. ITEM)
    # Inserts one or more items in the control; each item must be passed as
    # an hash reference. See InsertItem() for a list of the available
    # key/values of these hashes.
int
Add(handle,...)
    HWND handle
PREINIT:
    LV_ITEM Item;
    unsigned int tlen;
    int item_i, i;
    char * option;
    AV* texts;
	SV** t;
	HV* itemdata;
	SV* sv_option;
	SV* sv_value;
	I32 retlen;
	I32 nitems;
	int iir;
CODE:
	RETVAL = 0;
    for(item_i = 1; item_i < items; item_i++) {
		texts = NULL;
		if(SvROK(ST(item_i)) && SvTYPE(SvRV(ST(item_i))) == SVt_PVHV) {
			ZeroMemory(&Item, sizeof(LV_ITEM));
			Item.iItem = ListView_GetItemCount(handle);
			itemdata = (HV*)SvRV(ST(item_i));
			nitems = hv_iterinit(itemdata);
			while(nitems--) {
				sv_value = hv_iternextsv(itemdata, &option, &retlen);
				if(strcmp(option, "-text") == 0) {
					if(SvROK(sv_value) && SvTYPE(SvRV(sv_value)) == SVt_PVAV) {
						texts = (AV*)SvRV(sv_value);
						t = av_fetch(texts, 0, 0);
						if(t != NULL) {
							Item.pszText = SvPV(*t, tlen);
							Item.cchTextMax = tlen;
							SwitchFlag(Item.mask, LVIF_TEXT, 1);
						}
					} else {
						Item.pszText = SvPV(sv_value, tlen);
						Item.cchTextMax = tlen;
						SwitchFlag(Item.mask, LVIF_TEXT, 1);
					}
				} else if(strcmp(option, "-item") == 0
				|| strcmp(option, "-index") == 0) {
					Item.iItem = SvIV(sv_value);
				} else if(strcmp(option, "-image") == 0) {
					Item.iImage = SvIV(sv_value);
					SwitchFlag(Item.mask, LVIF_IMAGE, 1);
				} else if(strcmp(option, "-selected") == 0) {
					SwitchFlag(Item.state, LVIS_SELECTED, SvIV(sv_value));
					SwitchFlag(Item.stateMask, LVIS_SELECTED, 1);
					SwitchFlag(Item.mask, LVIF_STATE, 1);
				} else if(strcmp(option, "-indent") == 0) {
					Item.iIndent = SvIV(sv_value);
					SwitchFlag(Item.mask, LVIF_INDENT, 1);
				}
			}
		}
		iir = ListView_InsertItem(handle, &Item);
		if(iir != -1) RETVAL++;
		if(texts != NULL) {
			for(i=1; i<=av_len(texts); i++) {
				t = av_fetch(texts, i, 0);
				if(t != NULL) {
					Item.pszText = SvPV(*t, tlen);
					Item.cchTextMax = tlen;
					SwitchFlag(Item.mask, LVIF_TEXT, 1);
				}
				Item.iSubItem = i;
				ListView_SetItem(handle, &Item);
			}
		}
		Item.iItem = ListView_GetItemCount(handle);
	}
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:ChangeItem(%OPTIONS)

    ###########################################################################
    # (@)METHOD:SetItem(%OPTIONS)
    # See ChangeItem().
int
ChangeItem(handle,...)
    HWND handle
ALIAS:
    Win32::GUI::ListView::SetItem = 1
PREINIT:
    LV_ITEM Item;
    unsigned int tlen;
    int i, next_i;
    char * option;
CODE:
    ZeroMemory(&Item, sizeof(LV_ITEM));
    next_i = -1;
    for(i = 1; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-text") == 0) {
                next_i = i + 1;
                Item.pszText = SvPV(ST(next_i), tlen);
                Item.cchTextMax = tlen;
                Item.mask = Item.mask | LVIF_TEXT;
            } else if(strcmp(option, "-item") == 0
            || strcmp(option, "-index") == 0) {
                next_i = i + 1;
                Item.iItem = SvIV(ST(next_i));
            } else if(strcmp(option, "-subitem") == 0) {
                next_i = i + 1;
                Item.iSubItem = SvIV(ST(next_i));
            } else if(strcmp(option, "-image") == 0) {
                next_i = i + 1;
                Item.iImage = SvIV(ST(next_i));
                Item.mask = Item.mask | LVIF_IMAGE;
            }
        } else {
            next_i = -1;
        }
    }
    RETVAL = ListView_SetItem(handle, &Item);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:ItemInfo(INDEX, [SUBINDEX])
    # Returns an associative array of information about the given zero-based
    # INDEX item:
	#     -image
	#     -state
    #     -text
	# Optionally, a SUBINDEX (one-based index) can be given, to get the text
	# for the specified column.

    ###########################################################################
    # (@)METHOD:GetItem(INDEX, [SUBINDEX])
    # See ItemInfo().
void
ItemInfo(handle,item, subitem=0)
    HWND handle
    int item
    int subitem
ALIAS:
    Win32::GUI::ListView::GetItem = 1
PREINIT:
    LV_ITEM lv_item;
    char pszText[1024];
PPCODE:
    ZeroMemory(&lv_item, sizeof(LV_ITEM));
    lv_item.iItem = item;
    lv_item.mask = LVIF_IMAGE
                 | LVIF_PARAM
                 | LVIF_TEXT | LVIF_STATE;
    lv_item.pszText = pszText;
    lv_item.cchTextMax = 1024;
    lv_item.iSubItem = subitem;
    if(ListView_GetItem(handle, &lv_item)) {
        EXTEND(SP, 6);
        XST_mPV(0, "-text");
        XST_mPV(1, lv_item.pszText);
        XST_mPV(2, "-image");
        XST_mIV(3, lv_item.iImage);
		XST_mPV(4, "-state");
		XST_mIV(5, lv_item.state);
        XSRETURN(6);
    } else {
        XSRETURN_NO;
    }


    ###########################################################################
    # (@)METHOD:View([MODE])
long
View(handle,view=-1)
    HWND handle
    DWORD view
PREINIT:
    DWORD dwStyle;
    DWORD dwView;
CODE:
    // Get the current window style.
    dwStyle = GetWindowLong(handle, GWL_STYLE);
    if(items == 2) {
        // Only set the window style if the view bits have changed.
        if ((dwStyle & LVS_TYPEMASK) != view)
            SetWindowLong(handle, GWL_STYLE,
                          (dwStyle & ~LVS_TYPEMASK) | view);
        dwStyle = GetWindowLong(handle, GWL_STYLE);
        RETVAL = (dwStyle & LVS_TYPEMASK);
    } else
        RETVAL = (dwStyle & LVS_TYPEMASK);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Count()
    # Returns the number of items in the ListView.
int
Count(handle)
    HWND handle
CODE:
    RETVAL = ListView_GetItemCount(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DeleteItem(INDEX)
    # Removes the zero-based INDEX item from the ListView.
BOOL
DeleteItem(handle,index)
    HWND handle
    int index
CODE:
    RETVAL = ListView_DeleteItem(handle, index);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:EditLabel(INDEX)
HWND
EditLabel(handle,index)
    HWND handle
    int index
CODE:
    RETVAL = ListView_EditLabel(handle, index);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Clear()
    # Deletes all items from the ListView.
BOOL
Clear(handle)
    HWND handle
CODE:
    RETVAL = ListView_DeleteAllItems(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:DeleteColumn(INDEX)
BOOL
DeleteColumn(handle,index)
    HWND handle
    int index
CODE:
    RETVAL = ListView_DeleteColumn(handle, index);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SelectCount()
UINT
SelectCount(handle)
    HWND handle
CODE:
    RETVAL = ListView_GetSelectedCount(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Select(INDEX)
void
Select(handle,item)
    HWND handle
    int item
PREINIT:
    UINT state;
    UINT mask;
CODE:
    state = LVIS_FOCUSED | LVIS_SELECTED;
    mask = 0xFFFFFFFF;
    ListView_SetItemState(handle, item, state, mask);

    ###########################################################################
    # (@)METHOD:HitTest(X, Y)
void
HitTest(handle,x,y)
    HWND handle
    LONG x
    LONG y
PREINIT:
    LV_HITTESTINFO ht;
PPCODE:
    ht.pt.x = x;
    ht.pt.y = y;
    ListView_HitTest(handle, &ht);
    if(GIMME == G_ARRAY) {
        EXTEND(SP, 2);
        XST_mIV(0, (long) ht.iItem);
        XST_mIV(1, ht.flags);
        XSRETURN(2);
    } else {
        XSRETURN_IV((long) ht.iItem);
    }

    ###########################################################################
    # (@)METHOD:GetStringWidth(STRING)
int
GetStringWidth(handle,string)
    HWND handle
    LPCSTR string
CODE:
    RETVAL = ListView_GetStringWidth(handle, string);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetFirstVisible()
    # Returns the index of the first visible item in the ListView.
int
GetFirstVisible(handle)
    HWND handle
CODE:
    RETVAL = ListView_GetTopIndex(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:EnsureVisible(INDEX, [FLAG])
BOOL
EnsureVisible(handle,index,flag=TRUE)
    HWND handle
    int index
    BOOL flag
CODE:
    RETVAL = ListView_EnsureVisible(handle, index, flag);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SetImageList(IMAGELIST, [TYPE])
HIMAGELIST
SetImageList(handle,imagelist,type=LVSIL_NORMAL)
    HWND handle
    HIMAGELIST imagelist
    WPARAM type
CODE:
    RETVAL = ListView_SetImageList(handle, imagelist, type);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:TextColor([COLOR])
    # Gets or sets the text color for the ListView.
COLORREF
TextColor(handle,color=-1)
    HWND handle
    COLORREF color
CODE:
    if(items == 2) {
        if(ListView_SetTextColor(handle, color))
            RETVAL = ListView_GetTextColor(handle);
        else
            RETVAL = -1;
    } else
        RETVAL = ListView_GetTextColor(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:TextBkColor([COLOR])
    # Gets or sets the background color for the text in the ListView.
COLORREF
TextBkColor(handle,color=-1)
    HWND handle
    COLORREF color
CODE:
    if(items == 2) {
        if(ListView_SetTextBkColor(handle, color))
            RETVAL = ListView_GetTextBkColor(handle);
        else
            RETVAL = -1;
    } else
        RETVAL = ListView_GetTextBkColor(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ColumnWidth(COLUMN, [WIDTH])
    # Gets or sets the width of the specified COLUMN; WIDTH can be the desired
    # width in pixels or one of the following special values:
    #   -1 automatically size the column
    #   -2 automatically size the column to fit the header text
int
ColumnWidth(handle,column,width=-1)
    HWND handle
    int column
    int width
CODE:
    if(items == 2)
        RETVAL = ListView_GetColumnWidth(handle, column);
    else
        RETVAL = ListView_SetColumnWidth(handle, column, width);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:VisibleCount()
int
VisibleCount(handle)
    HWND handle
CODE:
    RETVAL = ListView_GetCountPerPage(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:MoveItem(INDEX, X, Y)
BOOL
MoveItem(handle, index, x, y)
    HWND handle
    int index
    int x
    int y
CODE:
    RETVAL = ListView_SetItemPosition(handle, index, x, y);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ItemPosition(INDEX, [X, Y])
void
ItemPosition(handle, index, x=-1, y=-1)
    HWND handle
    int index
    int x
    int y
PREINIT:
    POINT p;
PPCODE:
    if(items == 2) {
        if(ListView_GetItemPosition(handle, index, &p)) {
            EXTEND(SP, 2);
            XST_mIV(0, p.x);
            XST_mIV(1, p.y);
            XSRETURN(2);
        } else {
            XSRETURN_NO;
        }
    } else {
        XSRETURN_IV(ListView_SetItemPosition(handle, index, x, y));
    }

    ###########################################################################
    # (@)METHOD:Arrange([FLAG])
int
Arrange(handle,flag=LVA_DEFAULT)
    HWND handle
    UINT flag
CODE:
    RETVAL = ListView_Arrange(handle, flag);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ItemCheck(INDEX)
BOOL
ItemCheck(handle,index,value=FALSE)
    HWND handle
    int index
    BOOL value
PREINIT:
    LVITEM lvitem;
CODE:
    if(items == 3) {
        lvitem.mask = LVIF_STATE;
        lvitem.iItem = index;
        lvitem.stateMask = LVIS_STATEIMAGEMASK;
        lvitem.state = INDEXTOSTATEIMAGEMASK((value ? 2 : 1));
        RETVAL = ListView_SetItem(handle, &lvitem);
    } else {
        RETVAL = ListView_GetCheckState(handle, index);

        # lvitem.mask = LVIF_STATE;
        # lvitem.iItem = index;
        # lvitem.stateMask = LVIS_STATEIMAGEMASK;
        # ListView_GetItem(handle, &lvitem);
        # RETVAL = ((BOOL)(lvitem.state >> 12) -1);
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:SelectedItems()
    # Retuns an array containing the zero-based indexes of selected items.
void
SelectedItems(handle)
    HWND handle
PREINIT:
    LVITEM lvitem;
	UINT lresult;
	UINT scount;
	UINT tcount;
	int index;
PPCODE:
	scount = ListView_GetSelectedCount(handle);
	if(scount > 0) {
		index = -1;
		tcount = 0;
		EXTEND(SP, scount);
		index = ListView_GetNextItem(handle, index, LVNI_SELECTED);
		while(tcount < scount && index != -1) {
			XST_mIV(tcount, (long) index);
			tcount++;
			index = ListView_GetNextItem(handle, index, LVNI_SELECTED);
		}
		XSRETURN(scount);
	} else {
		XSRETURN_NO;
	}

	# TODO: GetItem
	# TODO: GetNextItem

    ###########################################################################
    # (@)PACKAGE:Win32::GUI::TreeView
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::TreeView


    ###########################################################################
    # (@)METHOD:InsertItem(%OPTIONS)
    # Inserts a new node in the TreeView.
    # Allowed %OPTIONS are:
	#     -bold => 0/1, default 0
    #     -image => NUMBER
    #         index of an image from the associated ImageList
	#     -item => NUMBER
	#         handle of the node after which the new node is to be inserted,
	#         or one of the following special values:
	#             0xFFFF0001: at the beginning of the list
	#             0xFFFF0002: at the end of the list
	#             0xFFFF0003: in alphabetical order
	#         the default value is at the end of the list
	#     -parent => NUMBER
	#         handle of the parent node for the new node
	#     -selected => 0/1, default 0
    #     -selectedimage => NUMBER
    #         index of an image from the associated ImageList
	#     -text => STRING
	#         the text for the node
HTREEITEM
InsertItem(handle,...)
    HWND handle
PREINIT:
    TV_ITEM Item;
    TV_INSERTSTRUCT Insert;
    unsigned int tlen;
    int i, next_i;
    int imageSeen, selectedImageSeen;
    LPSTR pszText;
    char * option;
CODE:
    ZeroMemory(&Item, sizeof(TV_ITEM));
    ZeroMemory(&Insert, sizeof(TV_INSERTSTRUCT));
    Insert.hParent = NULL;
    Insert.hInsertAfter = TVI_LAST;

    imageSeen = 0;
    selectedImageSeen = 0;

    next_i = -1;
    for(i = 1; i < items; i++) {
		if(next_i == -1) {
            option = SvPV_nolen(ST(i));
			if(strcmp(option, "-text") == 0) {
                next_i = i + 1;
                tlen = SvCUR(ST(next_i));
                pszText = (LPSTR) safemalloc(tlen);
                strcpy(pszText, SvPV_nolen(ST(next_i)));
                Item.pszText = pszText;
                Item.cchTextMax = tlen;
                SwitchFlag(Item.mask, TVIF_TEXT, 1);
            } else if(strcmp(option, "-image") == 0) {
                next_i = i + 1;
                imageSeen = 1;
                Item.iImage = SvIV(ST(next_i));
                SwitchFlag(Item.mask, TVIF_IMAGE, 1);
            } else if(strcmp(option, "-selectedimage") == 0) {
                next_i = i + 1;
                selectedImageSeen = 1;
                Item.iSelectedImage = SvIV(ST(next_i));
                SwitchFlag(Item.mask, TVIF_SELECTEDIMAGE, 1);
            } else if(strcmp(option, "-parent") == 0) {
                next_i = i + 1;
                Insert.hParent = (HTREEITEM) handle_From(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-item") == 0
                   || strcmp(option, "-index") == 0) {
                next_i = i + 1;
                Insert.hInsertAfter = (HTREEITEM) handle_From(NOTXSCALL ST(next_i));
            } else if(strcmp(option, "-bold") == 0) {
                next_i = i + 1;
                SwitchFlag(Item.state, TVIS_BOLD, SvIV(ST(next_i)));
                SwitchFlag(Item.stateMask, TVIS_BOLD, 1);
				SwitchFlag(Item.mask, TVIF_STATE, 1);
            } else if(strcmp(option, "-selected") == 0) {
                next_i = i + 1;
                SwitchFlag(Item.state, TVIS_SELECTED, SvIV(ST(next_i)));
                SwitchFlag(Item.stateMask, TVIS_SELECTED, 1);
                SwitchFlag(Item.mask, TVIF_STATE, 1);
			}
        } else {
            next_i = -1;
        }
    }
    if(selectedImageSeen == 0 && imageSeen != 0) {
        Item.iSelectedImage = Item.iImage;
		SwitchFlag(Item.mask, TVIF_SELECTEDIMAGE, 1);
    }
    Insert.item = Item;
    RETVAL = TreeView_InsertItem(handle, &Insert);
    safefree(pszText);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:ChangeItem(NODE, %OPTIONS)
    # Change most of the options used when the item was created
    # (see InsertItem()).
    # Allowed %OPTIONS are:
	#     -bold
    #     -image
	#     -selected
    #     -selectedimage
    #     -text
BOOL
ChangeItem(handle,item,...)
    HWND handle
    HTREEITEM item;
PREINIT:
    int i, next_i, imageSeen, selectedImageSeen;
    unsigned int tlen;
    TV_ITEM Item;
    char * option;
CODE:
    ZeroMemory(&Item, sizeof(TV_ITEM));
    Item.hItem = item;
    imageSeen = 0;
    selectedImageSeen = 0;
    next_i = -1;
    for(i = 2; i < items; i++) {
        if(next_i == -1) {
			option = SvPV_nolen(ST(i));
            if(strcmp(option, "-text") == 0) {
                next_i = i + 1;
                Item.pszText = SvPV(ST(next_i), tlen);
                Item.cchTextMax = tlen;
                SwitchFlag(Item.mask, TVIF_TEXT, 1);
            } else if(strcmp(option, "-image") == 0) {
                next_i = i + 1;
                imageSeen = 1;
                Item.iImage = SvIV(ST(next_i));
                SwitchFlag(Item.mask, TVIF_IMAGE, 1);
            } else if(strcmp(option, "-selectedimage") == 0) {
                next_i = i + 1;
                selectedImageSeen = 1;
                Item.iSelectedImage = SvIV(ST(next_i));
                SwitchFlag(Item.mask, TVIF_SELECTEDIMAGE, 1);
            } else if(strcmp(option, "-bold") == 0) {
                next_i = i + 1;
                SwitchFlag(Item.state, TVIS_BOLD, SvIV(ST(next_i)));
                SwitchFlag(Item.stateMask, TVIS_BOLD, 1);
				SwitchFlag(Item.mask, TVIF_STATE, 1);
            } else if(strcmp(option, "-selected") == 0) {
                next_i = i + 1;
                SwitchFlag(Item.state, TVIS_SELECTED, SvIV(ST(next_i)));
                SwitchFlag(Item.stateMask, TVIS_SELECTED, 1);
                SwitchFlag(Item.mask, TVIF_STATE, 1);
			}
        } else {
            next_i = -1;
        }
    }
    if(selectedImageSeen == 0 && imageSeen != 0) {
        Item.iSelectedImage = Item.iImage;
		SwitchFlag(Item.mask, TVIF_SELECTEDIMAGE, 1);
    }
    RETVAL = TreeView_SetItem(handle, &Item);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:ItemInfo(NODE)
    # Returns an associative array of information about the given NODE:
    #     -children
	#     -image
	#     -parent
	#     -selectedimage
	#     -state
    #     -text

    ###########################################################################
    # (@)METHOD:GetItem(NODE)
    # See ItemInfo().
void
ItemInfo(handle,item)
    HWND handle
    HTREEITEM item
ALIAS:
    Win32::GUI::TreeView::GetItem = 1
PREINIT:
    TV_ITEM tv_item;
    char pszText[1024];
PPCODE:
    ZeroMemory(&tv_item, sizeof(TV_ITEM));
    tv_item.hItem = item;
    tv_item.mask = TVIF_CHILDREN | TVIF_HANDLE | TVIF_IMAGE
                 | TVIF_PARAM | TVIF_SELECTEDIMAGE
                 | TVIF_TEXT | TVIF_STATE;
    tv_item.pszText = pszText;
    tv_item.cchTextMax = 1024;
    if(TreeView_GetItem(handle, &tv_item)) {
        EXTEND(SP, 8);
        XST_mPV(0, "-text");
        XST_mPV(1, tv_item.pszText);
        XST_mPV(2, "-image");
        XST_mIV(3, tv_item.iImage);
        XST_mPV(4, "-selectedimage");
        XST_mIV(5, tv_item.iSelectedImage);
        XST_mPV(6, "-children");
        XST_mIV(7, tv_item.cChildren);
		XST_mPV(8, "-parent");
		XST_mIV(9, (long) TreeView_GetParent(handle, item));
		XST_mPV(10, "-state");
		XST_mIV(11, tv_item.state);
        XSRETURN(12);
    } else {
        XSRETURN_NO;
    }


    ###########################################################################
    # (@)METHOD:DeleteItem(NODE)
    # Removes the specified NODE from the TreeView.
BOOL
DeleteItem(handle,item)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_DeleteItem(handle,item);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Reset()
    # Deletes all nodes from the TreeView.
BOOL
Reset(handle)
    HWND handle
CODE:
    RETVAL = TreeView_DeleteAllItems(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Clear([NODE])
    # Deletes all nodes from the TreeView if no argument is given;
    # otherwise, delete all nodes under the given NODE.
BOOL
Clear(handle,...)
    HWND handle
CODE:
    if(items != 1 && items != 2)
        croak("Usage: Clear(handle, [item]);\n");
    if(items == 1)
        RETVAL = TreeView_DeleteAllItems(handle);
    else
        RETVAL = TreeView_Expand(handle,
                                 (HTREEITEM) SvIV(ST(1)),
                                 TVE_COLLAPSE | TVE_COLLAPSERESET);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:SetImageList(IMAGELIST, [TYPE])
HIMAGELIST
SetImageList(handle,imagelist,type=TVSIL_NORMAL)
    HWND handle
    HIMAGELIST imagelist
    WPARAM type
CODE:
    RETVAL = TreeView_SetImageList(handle, imagelist, type);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Expand(NODE, [FLAG])
BOOL
Expand(handle,item,flag=TVE_EXPAND)
    HWND handle
    HTREEITEM item
    UINT flag
CODE:
    RETVAL = TreeView_Expand(handle, item, flag);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Collapse(NODE)
    # Closes a NODE of the TreeView.
BOOL
Collapse(handle,item)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_Expand(handle, item, TVE_COLLAPSE);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetRoot()
    # Returns the handle of the TreeView root node.
HTREEITEM
GetRoot(handle)
    HWND handle
CODE:
    RETVAL = TreeView_GetRoot(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetParent(NODE)
    # Returns the handle of the parent node for the given NODE.
HTREEITEM
GetParent(handle,item)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_GetParent(handle, item);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetChild(NODE)
    # Returns the handle of the first child node for the given NODE.
HTREEITEM
GetChild(handle,item)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_GetChild(handle, item);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetNextSibling(NODE)
    # Returns the handle of the next sibling node for the given NODE.
HTREEITEM
GetNextSibling(handle,item)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_GetNextSibling(handle, item);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetPrevSibling(NODE)
    # Returns the handle of the previous sibling node for the given NODE.
HTREEITEM
GetPrevSibling(handle,item)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_GetPrevSibling(handle, item);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Count()
    # Returns the number of nodes in the TreeView.
UINT
Count(handle)
    HWND handle
CODE:
    RETVAL = TreeView_GetCount(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Select(NODE, [FLAG])
    # Selects the given NODE in the TreeView; the optional FLAG parameter
    # can be set to 5 if you want the selected NODE to become, if possible,
    # the first visible item in the TreeView.
	# If NODE is 0 (zero), the selected item, if any, is deselected.
BOOL
Select(handle,item,flag=TVGN_CARET)
    HWND handle
    HTREEITEM item
    WPARAM flag
CODE:
    RETVAL = (BOOL) TreeView_Select(handle, item, flag);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:SelectedItem()
    # Returns the handle of the currently selected node.
HTREEITEM
SelectedItem(handle)
    HWND handle
CODE:
    RETVAL = TreeView_GetSelection(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:HitTest(X, Y)
void
HitTest(handle,x,y)
    HWND handle
    LONG x
    LONG y
PREINIT:
    TV_HITTESTINFO ht;
PPCODE:
    ht.pt.x = x;
    ht.pt.y = y;
    TreeView_HitTest(handle, &ht);
    if(GIMME == G_ARRAY) {
        EXTEND(SP, 2);
        XST_mIV(0, (long) ht.hItem);
        XST_mIV(1, ht.flags);
        XSRETURN(2);
    } else {
        XSRETURN_IV((long) ht.hItem);
    }


    ###########################################################################
    # (@)METHOD:Indent([VALUE])
UINT
Indent(handle,value=-1)
    HWND handle
    UINT value
CODE:
    if(items == 2)
        RETVAL = TreeView_SetIndent(handle, value);
    else
        RETVAL = TreeView_GetIndent(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Sort(NODE)
    # Sorts the childs of the specified NODE in the TreeView.
BOOL
Sort(handle,item)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_SortChildren(handle, item, 0);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:EnsureVisible(NODE)
BOOL
EnsureVisible(handle,item)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_EnsureVisible(handle, item);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:VisibleCount()
UINT
VisibleCount(handle)
    HWND handle
CODE:
    RETVAL = TreeView_GetVisibleCount(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:FirstVisible([NODE])
HTREEITEM
FirstVisible(handle,item=0)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_GetFirstVisible(handle);
	if(items == 2)
        TreeView_SelectSetFirstVisible(handle, item);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetNextVisible(NODE)
HTREEITEM
GetNextVisible(handle,item)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_GetNextVisible(handle, item);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetPrevVisible(NODE)
HTREEITEM
GetPrevVisible(handle,item)
    HWND handle
    HTREEITEM item
CODE:
    RETVAL = TreeView_GetPrevVisible(handle, item);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetLastVisible()
HTREEITEM
GetLastVisible(handle)
    HWND handle
CODE:
    RETVAL = TreeView_GetLastVisible(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:ItemCheck(NODE, [VALUE])
BOOL
ItemCheck(handle,item,value=FALSE)
    HWND handle
    HTREEITEM item
    BOOL value
PREINIT:
    TVITEM tvitem;
CODE:
    if(items == 3) {
        tvitem.mask = TVIF_HANDLE | TVIF_STATE;
        tvitem.hItem = item;
        tvitem.stateMask = TVIS_STATEIMAGEMASK;
        tvitem.state = INDEXTOSTATEIMAGEMASK((value ? 2 : 1));
        RETVAL = TreeView_SetItem(handle, &tvitem);
    } else {
        tvitem.mask = TVIF_HANDLE | TVIF_STATE;
        tvitem.hItem = item;
        tvitem.stateMask = TVIS_STATEIMAGEMASK;
        TreeView_GetItem(handle, &tvitem);
        RETVAL = ((BOOL)(tvitem.state >> 12) -1);
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:TextColor([COLOR])
    # Gets or sets the text color for the control.
COLORREF
TextColor(handle,color=-1)
    HWND handle
    COLORREF color
CODE:
    if(items == 2) {
        if(TreeView_SetTextColor(handle, color))
            RETVAL = TreeView_GetTextColor(handle);
        else
            RETVAL = -1;
    } else
        RETVAL = TreeView_GetTextColor(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:BackColor([COLOR])
    # Gets or sets the background color for the control.
COLORREF
BackColor(handle,color=-1)
    HWND handle
    COLORREF color
CODE:
    if(items == 2) {
        if(TreeView_SetBkColor(handle, color))
            RETVAL = TreeView_GetBkColor(handle);
        else
            RETVAL = -1;
    } else
        RETVAL = TreeView_GetBkColor(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::UpDown
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::UpDown


    ###########################################################################
    # (@)METHOD:Base([VALUE])
    # Gets or sets the radix base for the UpDown control; VALUE can be
    # either 10 or 16 for decimal or hexadecimal base numbering.
LRESULT
Base(handle,base=0)
    HWND handle
    WPARAM base
CODE:
    if(items == 1)
        RETVAL = SendMessage(handle, UDM_GETBASE, 0, 0);
    else
        RETVAL = SendMessage(handle, UDM_SETBASE, base, 0);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Pos([VALUE])
    # Gets or sets the current position of the UpDown control.
LRESULT
Pos(handle,pos=-1)
    HWND handle
    short pos
CODE:
    if(items == 1)
        RETVAL = SendMessage(handle, UDM_GETPOS, 0, 0);
    else
        RETVAL = SendMessage(handle, UDM_SETPOS, 0, (LPARAM) MAKELONG(pos, 0));
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Range([MIN, MAX])
    # Gets or sets the range for the UpDown control; if no parameter is given,
    # returns a two element array containing the MIN and MAX range values,
    # otherwise sets them to the given values.
    # If MAX is lower than MIN, the UpDown control function is reversed, eg.
    # the up button decrements the value and the down button increments it
void
Range(handle,min=-1,max=-1)
    HWND handle
    short min
    short max
PREINIT:
    LRESULT range;
PPCODE:
    if(items == 1) {
        range = SendMessage(handle, UDM_GETRANGE, 0, 0);
        XST_mIV(0, HIWORD(range));
        XST_mIV(1, LOWORD(range));
        XSRETURN(2);
    } else {
        SendMessage(handle, UDM_SETRANGE, 0, (LPARAM) MAKELONG(max, min));
        XSRETURN_YES;
    }

    ###########################################################################
    # (@)METHOD:Buddy([OBJECT])
    # Gets or sets the buddy window for the UpDown control.
HV*
Buddy(handle,buddy=NULL)
    HWND handle
    HWND buddy
PREINIT:
    HWND oldbuddy;
CODE:
    if(items == 1) {
        oldbuddy = (HWND) SendMessage(handle, UDM_GETBUDDY, 0, 0);
        RETVAL = (HV*) GetWindowLong(oldbuddy, GWL_USERDATA);
    } else {
        oldbuddy = (HWND) SendMessage(handle, UDM_SETBUDDY, (WPARAM) buddy, 0);
        RETVAL = (HV*) GetWindowLong(oldbuddy, GWL_USERDATA);
    }
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Tooltip
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::Tooltip

    ###########################################################################
    # (@)METHOD:Add(...)
BOOL
Add(handle,...)
    HWND handle
PREINIT:
    int i, next_i;
    char * option;
    TOOLINFO ti;
CODE:
    ZeroMemory(&ti, sizeof(TOOLINFO));
    ti.cbSize = sizeof(TOOLINFO);
    ti.hwnd = (HWND) GetWindowLong(handle, GWL_HWNDPARENT);
    next_i = -1;
    for(i = 1; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
#ifdef PERLWIN32GUI_STRONGDEBUG
	            printf("XS(Tooltip::Add): got option '%s'\n", option);
#endif
            if(strcmp(option, "-text") == 0) {
                next_i = i + 1;
                ti.lpszText = SvPV_nolen(ST(next_i));
            } else if(strcmp(option, "-window") == 0) {
                next_i = i + 1;
                ti.uId = (UINT) handle_From(NOTXSCALL ST(next_i));
                ti.uFlags |= TTF_IDISHWND;
            } else if(strcmp(option, "-flags") == 0) {
                next_i = i + 1;
                ti.uFlags = SvIV(ST(next_i));
            }
        }
    }
    RETVAL = SendMessage(handle, TTM_ADDTOOL, 0, (LPARAM) &ti);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Count()
    # Returns the number of tools in the Tooltip.
LRESULT
Count(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, TTM_GETTOOLCOUNT, 0, 0);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Animation
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::Animation


    ###########################################################################
    # (@)METHOD:Open(FILE)
BOOL
Open(handle,file)
    HWND handle
    char * file
CODE:
    RETVAL = Animate_Open(handle, (LPSTR) file);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Close()
BOOL
Close(handle)
    HWND handle
CODE:
    RETVAL = Animate_Close(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Play([FROM], [TO], [REPEAT])
BOOL
Play(handle,from=0,to=-1,repeat=-1)
    HWND handle
    UINT from
    UINT to
    UINT repeat
CODE:
    RETVAL = Animate_Play(handle, from, to, repeat);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Stop()
BOOL
Stop(handle)
    HWND handle
CODE:
    RETVAL = Animate_Stop(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Seek(FRAME)
BOOL
Seek(handle,frame)
    HWND handle
    UINT frame
CODE:
    RETVAL = Animate_Seek(handle, frame);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Rebar
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::Rebar

    ###########################################################################
    # (@)METHOD:InsertBand(%OPTIONS)
LRESULT
InsertBand(handle,...)
    HWND handle
PREINIT:
    REBARBANDINFO rbbi;
    int i, next_i;
    UINT index;
CODE:
    ZeroMemory(&rbbi, sizeof(REBARBANDINFO));
    rbbi.cbSize = sizeof(REBARBANDINFO);
    index = -1;
    next_i = -1;
    for(i = 1; i < items; i++) {
        if(next_i == -1) {
            if(strcmp(SvPV_nolen(ST(i)), "-image") == 0) {
                next_i = i + 1;
                rbbi.iImage = SvIV(ST(next_i));
                SwitchFlag(rbbi.fMask, RBBIM_IMAGE, 1);
            } else if(strcmp(SvPV_nolen(ST(i)), "-index") == 0) {
                next_i = i + 1;
                index = (UINT) SvIV(ST(next_i));
            } else if(strcmp(SvPV_nolen(ST(i)), "-bitmap") == 0) {
                next_i = i + 1;
                rbbi.hbmBack = (HBITMAP) handle_From(NOTXSCALL ST(next_i));
                SwitchFlag(rbbi.fMask, RBBIM_BACKGROUND, 1);
            } else if(strcmp(SvPV_nolen(ST(i)), "-child") == 0) {
                next_i = i + 1;
                rbbi.hwndChild = (HWND) handle_From(NOTXSCALL ST(next_i));
                SwitchFlag(rbbi.fMask, RBBIM_CHILD, 1);
            } else if(strcmp(SvPV_nolen(ST(i)), "-foreground") == 0) {
                next_i = i + 1;
                rbbi.clrFore = SvCOLORREF(NOTXSCALL ST(next_i));
                SwitchFlag(rbbi.fMask, RBBIM_COLORS, 1);
            } else if(strcmp(SvPV_nolen(ST(i)), "-background") == 0) {
                next_i = i + 1;
                rbbi.clrBack = SvCOLORREF(NOTXSCALL ST(next_i));
                SwitchFlag(rbbi.fMask, RBBIM_COLORS, 1);
            } else if(strcmp(SvPV_nolen(ST(i)), "-width") == 0) {
                next_i = i + 1;
                rbbi.cx = SvIV(ST(next_i));
                SwitchFlag(rbbi.fMask, RBBIM_SIZE, 1);
            } else if(strcmp(SvPV_nolen(ST(i)), "-minwidth") == 0) {
                next_i = i + 1;
                rbbi.cxMinChild = SvIV(ST(next_i));
                SwitchFlag(rbbi.fMask, RBBIM_CHILDSIZE, 1);
            } else if(strcmp(SvPV_nolen(ST(i)), "-minheight") == 0) {
                next_i = i + 1;
                rbbi.cyMinChild = SvIV(ST(next_i));
                SwitchFlag(rbbi.fMask, RBBIM_CHILDSIZE, 1);
            } else if(strcmp(SvPV_nolen(ST(i)), "-text") == 0) {
                next_i = i + 1;
                rbbi.lpText = SvPV_nolen(ST(next_i));
                SwitchFlag(rbbi.fMask, RBBIM_TEXT, 1);
            }
        } else {
            next_i = -1;
        }
    }
    RETVAL = SendMessage(handle, RB_INSERTBAND, (WPARAM) index, (LPARAM) &rbbi);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:DeleteBand(INDEX)
LRESULT
DeleteBand(handle,index)
    HWND handle
    UINT index
CODE:
    RETVAL = SendMessage(handle, RB_DELETEBAND, (WPARAM) index, 0);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:RowCount()
LRESULT
RowCount(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, RB_GETROWCOUNT, 0, 0);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:BandCount()
LRESULT
BandCount(handle)
    HWND handle
CODE:
    RETVAL = SendMessage(handle, RB_GETBANDCOUNT, 0, 0);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:BandInfo(INDEX)
LRESULT
BandInfo(handle,index)
    HWND handle
    UINT index
PREINIT:
    REBARBANDINFO rbbi;
    int i, next_i;
CODE:
    ZeroMemory(&rbbi, sizeof(REBARBANDINFO));
    rbbi.cbSize = sizeof(REBARBANDINFO);
    rbbi.fMask =
    	RBBIM_BACKGROUND | RBBIM_CHILD | RBBIM_CHILDSIZE | RBBIM_COLORS |
    	RBBIM_HEADERSIZE | RBBIM_IDEALSIZE | RBBIM_ID | RBBIM_IMAGE |
    	RBBIM_LPARAM | RBBIM_SIZE | RBBIM_STYLE | RBBIM_TEXT;
    if(SendMessage(handle, RB_GETBANDINFO, (WPARAM) index, (LPARAM) &rbbi)) {
        EXTEND(SP, 18);
        XST_mPV( 0, "-text");
        XST_mPV( 1, rbbi.lpText);
        XST_mPV( 2, "-foreground");
        XST_mIV( 3, rbbi.clrFore);
		XST_mPV( 4, "-background");
		XST_mIV( 5, rbbi.clrBack);
		XST_mPV( 6, "-image");
		XST_mIV( 7, rbbi.iImage);
		XST_mPV( 8, "-child");
		XST_mIV( 9, (long) rbbi.hwndChild);
		XST_mPV(10, "-bitmap");
		XST_mIV(11, (long) rbbi.hbmBack);
		XST_mPV(12, "-width");
		XST_mIV(13, rbbi.cx);
		XST_mPV(14, "-minwidth");
		XST_mIV(15, rbbi.cxMinChild);
		XST_mPV(16, "-minheight");
		XST_mIV(17, rbbi.cyMinChild);
        XSRETURN(18);
    } else {
        XSRETURN_NO;
    }

    ###########################################################################
    # (@)METHOD:MinimizeBand(INDEX)
LRESULT
MinimizeBand(handle,index)
    HWND handle
    UINT index
CODE:
    RETVAL = SendMessage(handle, RB_MINIMIZEBAND, (WPARAM) index, 0);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:MaximizeBand(INDEX, [FLAG])
LRESULT
MaximizeBand(handle,index,flag=0)
    HWND handle
    UINT index
    BOOL flag
CODE:
    RETVAL = SendMessage(handle, RB_MAXIMIZEBAND, (WPARAM) index, (LPARAM) flag);
OUTPUT:
    RETVAL


    # TODO: ChangeBand


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Header
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::Header


    ###########################################################################
    # (@)METHOD:InsertItem(%OPTIONS)
    # Inserts a new item in the Header control. Returns the newly created
    # item zero-based index or -1 on errors.
    # %OPTIONS can be:
    #   -index => position
    #   -image => index of an image from the associated ImageList
    #   -bitmap => Win32::GUI::Bitmap object
    #   -width => pixels
    #   -height => pixels
    #   -text => string
    #   -align => left|center|right
LRESULT
InsertItem(handle,...)
    HWND handle
PREINIT:
    HDITEM Item;
    int index;
CODE:
    ZeroMemory(&Item, sizeof(HDITEM));
    index = Header_GetItemCount(handle) + 1;
    Item.fmt = HDF_LEFT;
    SwitchFlag(Item.mask, HDI_FORMAT, 1);
    ParseHeaderItemOptions(NOTXSCALL sp, mark, ax, items, 1, &Item, &index);
    RETVAL = Header_InsertItem(handle, index, &Item);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:DeleteItem(INDEX)
    # Deletes the zero-based INDEX item from the Header.
LRESULT
DeleteItem(handle,index)
    HWND handle
    int index
CODE:
    RETVAL = Header_DeleteItem(handle, index);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Count()
    # Returns the number of items in the Header control.
int
Count(handle)
    HWND handle
CODE:
    RETVAL = Header_GetItemCount(handle);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:ItemRect(INDEX)
    # Returns a four element array defining the rectangle of the specified
    # zero-based INDEX item; the array contains (left, top, right, bottom).
    # If not succesful returns undef.
void
ItemRect(handle,index)
    HWND handle
    int index
PREINIT:
    RECT rect;
CODE:
    if(Header_GetItemRect(handle, index, &rect)) {
        EXTEND(SP, 4);
        XST_mIV(0, rect.left);
        XST_mIV(1, rect.top);
        XST_mIV(2, rect.right);
        XST_mIV(3, rect.bottom);
        XSRETURN(4);
    } else {
        XSRETURN_NO;
    }

    ###########################################################################
    # (@)METHOD:ChangeItem(INDEX, %OPTIONS)
    # Changes the options for an item in the Header control. Returns nonzero
    # if successful, zero otherwise.
    # For a list of the available options see InsertItem().
BOOL
ChangeItem(handle,index,...)
    HWND handle
    int index
PREINIT:
    HDITEM Item;
CODE:
    ZeroMemory(&Item, sizeof(HDITEM));
    if(Header_GetItem(handle, index, &Item)) {
        ParseHeaderItemOptions(NOTXSCALL sp, mark, ax, items, 1, &Item, &index);
        SwitchFlag(Item.mask, HDI_FORMAT, 1);
        RETVAL = Header_SetItem(handle, index, &Item);
    } else {
        RETVAL = 0;
    }
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:HitTest(X, Y)
    # Checks if the specified point is on an Header item;
    # it returns the index of the found item or -1 if none was found.
    # If called in an array context, it returns an additional value containing
    # more info about the position of the specified point.
void
HitTest(handle,x,y)
    HWND handle
    LONG x
    LONG y
PREINIT:
    HDHITTESTINFO ht;
PPCODE:
	ZeroMemory(&ht, sizeof(HDHITTESTINFO));
    ht.pt.x = x;
    ht.pt.y = y;
    if(SendMessage(handle, HDM_HITTEST, 0, (LPARAM) &ht) == -1) {
		XSRETURN_IV(-1);
	} else {
		if(GIMME == G_ARRAY) {
			EXTEND(SP, 2);
			XST_mIV(0, (long) ht.iItem);
			XST_mIV(1, (long) ht.flags);
			XSRETURN(2);
		} else {
			XSRETURN_IV((long) ht.iItem);
		}
	}

    ###########################################################################
    # (@)METHOD:Clear()
    # Deletes all items from the control.

    ###########################################################################
    # (@)METHOD:Reset()
    # See Clear().
BOOL
Clear(handle)
    HWND handle
ALIAS:
    Win32::GUI::Header::Reset = 1
PREINIT:
	int i;
CODE:
	RETVAL = TRUE;
	for(i = Header_GetItemCount(handle); i > 0; i--) {
		if(!Header_DeleteItem(handle, i)) RETVAL = FALSE;
	}
OUTPUT:
    RETVAL


    # TODO: ItemInfo


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::ComboboxEx
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::ComboboxEx


    ###########################################################################
    # (@)METHOD:InsertItem(%OPTIONS)
    # Inserts a new item in the ComboboxEx control. Returns the newly created
    # item zero-based index or -1 on errors.
    # %OPTIONS can be:
    #   -index => position (-1 for the end of the list)
    #   -image => index of an image from the associated ImageList
    #   -selectedimage => index of an image from the associated ImageList
	#   -text => string
    #   -indent => indentation spaces (1 space == 10 pixels)
LRESULT
InsertItem(handle,...)
    HWND handle
PREINIT:
    COMBOBOXEXITEM Item;
    int index;
CODE:
    ZeroMemory(&Item, sizeof(COMBOBOXEXITEM));
    Item.iItem = -1;
    ParseComboboxExItemOptions(NOTXSCALL sp, mark, ax, items, 1, &Item);
    RETVAL = SendMessage(handle, CBEM_INSERTITEM, 0, (LPARAM) &Item);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::DateTime
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::DateTime


    ###########################################################################
    # (@)METHOD:GetDate()
    # (preliminary) Returns the date in the DateTime control in a three
	# elements array (day, month, year).
void
GetDate(handle)
    HWND handle
PREINIT:
    SYSTEMTIME st;
PPCODE:
	if(DateTime_GetSystemtime(handle, &st) == GDT_VALID) {
        EXTEND(SP, 3);
        XST_mIV(0, st.wDay);
        XST_mIV(1, st.wMonth);
        XST_mIV(2, st.wYear);
        XSRETURN(3);
    } else {
        XSRETURN_NO;
    }

    ###########################################################################
    # (@)METHOD:SetDate(DAY, MONTH, YEAR)
    # (preliminary) Sets the date in the DateTime control in a three
	# elements array (day, month, year).
BOOL
SetDate(handle, day, mon, year)
    HWND handle
	int day
	int mon
	int year
PREINIT:
    SYSTEMTIME st;
CODE:
	ZeroMemory(&st, sizeof(SYSTEMTIME));
	st.wDay   = day;
	st.wMonth = mon;
	st.wYear  = year;
	RETVAL = DateTime_SetSystemtime(handle, GDT_VALID, &st);
OUTPUT:
	RETVAL

    ###########################################################################
    # (@)METHOD:Format(FORMAT)
    # (preliminary) Sets the format for the DateTime control to the specified
    # string. More info [TBD].
BOOL
Format(handle, format)
    HWND handle
	LPCTSTR format
CODE:
	RETVAL = DateTime_SetFormat(handle, format);
OUTPUT:
	RETVAL


	###########################################################################
    # (@)PACKAGE:Win32::GUI::ImageList
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::ImageList


    ###########################################################################
    # (@)INTERNAL:Create(X, Y, FLAGS, INITAL, GROW)
HIMAGELIST
Create(cx,cy,flags,cInitial,cGrow)
    int cx
    int cy
    UINT flags
    int cInitial
    int cGrow
CODE:
    RETVAL = ImageList_Create(cx, cy, flags, cInitial, cGrow);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:AddBitmap(BITMAP, [BITMAPMASK])
	# Adds a Win32::GUI::Bitmap object to the ImageList. BITMAPMASK is
	# optional. See also Add().
int
AddBitmap(handle, bitmap, bitmapMask=NULL)
    HIMAGELIST handle
    HBITMAP bitmap
    HBITMAP bitmapMask
CODE:
    RETVAL = ImageList_Add(handle, bitmap, bitmapMask);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Replace(INDEX, BITMAP, [BITMAPMASK])
	# Replaces the specified zero-based INDEX image with the image specified
	# by BITMAP (must be a Win32::GUI::Bitmap object). BITMAPMASK is optional.
int
Replace(handle, index, bitmap, bitmapMask=NULL)
    HIMAGELIST handle
    int index
    HBITMAP bitmap
    HBITMAP bitmapMask
CODE:
    RETVAL = ImageList_Replace(handle, index, bitmap, bitmapMask);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Remove(INDEX)
    # Removes the specified zero-based INDEX image from the ImageList.
int
Remove(handle,index)
    HIMAGELIST handle
    int index
CODE:
    RETVAL = ImageList_Remove(handle, index);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:Clear()
    # Removes all the images from the ImageList.
int
Clear(handle)
    HIMAGELIST handle
    int index
CODE:
    RETVAL = ImageList_RemoveAll(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Count()
    # Returns the number of images in the ImageList.
int
Count(handle)
    HIMAGELIST handle
CODE:
    RETVAL = ImageList_GetImageCount(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:BackColor([COLOR])
    # Gets or sets the background color for the ImageList.
int
BackColor(handle,color=-1)
    HIMAGELIST handle
    COLORREF color
CODE:
    if(items == 2) {
        RETVAL = ImageList_SetBkColor(handle, color);
    } else
        RETVAL = ImageList_GetBkColor(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Size([X, Y])
    # Gets or sets the size of the images in the ImageList;
    # if no parameter is given, returns a 2 element array (X, Y),
    # otherwise sets the size to the given parameters.
void
Size(handle,...)
    HIMAGELIST handle
PREINIT:
    int cx, cy;
    BOOL result;
PPCODE:
    if(items != 1 && items != 3)
        croak("Usage: Size(handle);\n   or: Size(handle, x, y);\n");
    if(items == 1) {
        if(ImageList_GetIconSize(handle, &cx, &cy)) {
            EXTEND(SP, 2);
            XST_mIV(0, cx);
            XST_mIV(1, cy);
            XSRETURN(2);
        } else
            XSRETURN_NO;
    } else {
        result = ImageList_SetIconSize(handle, (int) SvIV(ST(1)), (int) SvIV(ST(2)));
        EXTEND(SP, 1);
        XST_mIV(0, result);
        XSRETURN(1);
    }


    ###########################################################################
    # (@)INTERNAL:DESTROY(HANDLE)
BOOL
DESTROY(handle)
    HIMAGELIST handle
CODE:
    RETVAL = ImageList_Destroy(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Bitmap
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::Bitmap

    ###########################################################################
    # (@)METHOD:Info()
    # returns a four elements array containing the following information
    # about the bitmap: width, height, color planes, bits per pixel
    # or undef on errors
void
Info(handle)
    HBITMAP handle
PREINIT:
    BITMAP bitmap;
PPCODE:
    ZeroMemory(&bitmap, sizeof(BITMAP));
    if(GetObject((HGDIOBJ) handle, sizeof(BITMAP), &bitmap)) {
        EXTEND(SP, 4);
        XST_mIV(0, bitmap.bmWidth);
        XST_mIV(1, bitmap.bmHeight);
        XST_mIV(2, bitmap.bmPlanes);
        XST_mIV(3, bitmap.bmBitsPixel);
        XSRETURN(4);
    } else {
        XSRETURN_NO;
    }

    ###########################################################################
    # (@)METHOD:GetDIBits()
void
GetDIBits(handle, hdc)
    HBITMAP handle
    HDC hdc
PREINIT:
    BITMAP bitmap;
    BITMAPINFO bInfo;
    long bufferlen;
    LPVOID buffer;
PPCODE:
    ZeroMemory(&bInfo, sizeof(BITMAPINFO));
    bInfo.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    ZeroMemory(&bitmap, sizeof(BITMAP));
    if(GetObject((HGDIOBJ) handle, sizeof(BITMAP), &bitmap)) {
        bufferlen = bitmap.bmHeight * bitmap.bmWidthBytes;
        buffer = (LPVOID) safemalloc(bufferlen);
        bInfo.bmiHeader.biWidth       = bitmap.bmWidth;
        bInfo.bmiHeader.biHeight      = bitmap.bmHeight;
        bInfo.bmiHeader.biPlanes      = bitmap.bmPlanes;
        bInfo.bmiHeader.biBitCount    = bitmap.bmBitsPixel;
        bInfo.bmiHeader.biCompression = BI_RGB;
#ifdef PERLWIN32GUI_DEBUG
        printf("XS(Bitmap::GetDIBits): getting %ld bytes...\n", bufferlen);
#endif
        if(GetDIBits(
            hdc,                        // handle of device context
            handle,                     // handle of bitmap
            0,                          // first scan line to set in destination bitmap
            bitmap.bmHeight,            // number of scan lines to copy
            buffer,                     // address of array for bitmap bits
            &bInfo,                     // address of structure with bitmap data
            DIB_RGB_COLORS              // RGB or palette index
        )) {
            EXTEND(SP, 5);
            XST_mIV(0, bitmap.bmWidth);
            XST_mIV(1, bitmap.bmHeight);
            XST_mIV(2, bitmap.bmPlanes);
            XST_mIV(3, bitmap.bmBitsPixel);
            sv_setpvn(ST(4), (char*) buffer, bufferlen);
            safefree(buffer);
            XSRETURN(5);
        } else {
#ifdef PERLWIN32GUI_DEBUG
            printf("XS(Bitmap::GetDIBits): GetDIBits failed (%d)\n", GetLastError());
#endif
            safefree(buffer);
            XSRETURN_NO;
        }
    } else {
#ifdef PERLWIN32GUI_DEBUG
        printf("XS(Bitmap::GetDIBits): GetObject failed (%d)\n", GetLastError());
#endif
        XSRETURN_NO;
    }

    ###########################################################################
    # (@)METHOD:Create(WIDTH, HEIGHT, PLANES, BPP, DATA)
HBITMAP
Create(width, height, planes, bpp, data)
    int width
    int height
    UINT planes
    UINT bpp
    LPVOID data
CODE:
    RETVAL = CreateBitmap(width, height, planes, bpp, data);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:OldInfo()
void
OldInfo(handle)
    HBITMAP handle
PREINIT:
    BITMAPINFO bInfo;
PPCODE:
    ZeroMemory(&bInfo, sizeof(BITMAPINFO));
#ifdef PERLWIN32GUI_DEBUG
	    printf("XS(Bitmap::OldInfo): handle=%ld\n", handle);
#endif
    bInfo.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bInfo.bmiHeader.biBitCount = 0; // don't care about colors, just general infos
    if(GetDIBits(NULL,          // handle of device context
                 handle,        // handle of bitmap
                 0,             // first scan line to set in destination bitmap
                 0,             // number of scan lines to copy
                 NULL,          // address of array for bitmap bits
                 &bInfo,        // address of structure with bitmap data
                 DIB_RGB_COLORS // RGB or palette index
                )) {
        EXTEND(SP, 9);
        XST_mIV(0, bInfo.bmiHeader.biWidth);
        XST_mIV(1, bInfo.bmiHeader.biHeight);
        XST_mIV(2, bInfo.bmiHeader.biBitCount);
        XST_mIV(3, bInfo.bmiHeader.biCompression);
        XST_mIV(4, bInfo.bmiHeader.biSizeImage);
        XST_mIV(5, bInfo.bmiHeader.biXPelsPerMeter);
        XST_mIV(6, bInfo.bmiHeader.biYPelsPerMeter);
        XST_mIV(7, bInfo.bmiHeader.biClrUsed);
        XST_mIV(8, bInfo.bmiHeader.biClrImportant);
        XSRETURN(9);
    } else {
#ifdef PERLWIN32GUI_DEBUG
        printf("XS(Bitmap::OldInfo): GetDIBits failed...\n");
        printf("XS(Bitmap::OldInfo): LastError is %d\n", GetLastError());
        printf("XS(Bitmap::OldInfo): bInfo.bmiHeader.biWidth=%d\n", bInfo.bmiHeader.biWidth);
#endif
        XSRETURN_NO;
    }

    ###########################################################################
    # (@)INTERNAL:OldInfoC()
void
OldInfoC(handle)
    HBITMAP handle
PREINIT:
    BITMAPCOREINFO bInfo;
PPCODE:
    ZeroMemory(&bInfo, sizeof(BITMAPCOREINFO));
#ifdef PERLWIN32GUI_DEBUG
	    printf("XS(Bitmap::OldInfoC): handle=%ld\n", handle);
#endif
    bInfo.bmciHeader.bcSize = sizeof(BITMAPCOREHEADER);
    bInfo.bmciHeader.bcBitCount = 0; // don't care about colors, just general infos
    if(GetDIBits(NULL,          // handle of device context
                 handle,        // handle of bitmap
                 0,             // first scan line to set in destination bitmap
                 0,             // number of scan lines to copy
                 NULL,          // address of array for bitmap bits
                 (LPBITMAPINFO) &bInfo,        // address of structure with bitmap data
                 DIB_RGB_COLORS // RGB or palette index
                )) {
        EXTEND(SP, 3);
        XST_mIV(0, bInfo.bmciHeader.bcWidth);
        XST_mIV(1, bInfo.bmciHeader.bcHeight);
        XST_mIV(2, bInfo.bmciHeader.bcBitCount);
        XSRETURN(3);
    } else {
#ifdef PERLWIN32GUI_DEBUG
        printf("XS(Bitmap::OldInfoC): GetDIBits failed...\n");
        printf("XS(Bitmap::OldInfoC): LastError is %d\n", GetLastError());
        printf("XS(Bitmap::OldInfoC): bInfo.bmciHeader.bcWidth=%d\n", bInfo.bmciHeader.bcWidth);
#endif
        XSRETURN_NO;
    }

    ###########################################################################
    # (@)INTERNAL:DESTROY(HANDLE)
BOOL
DESTROY(handle)
    HBITMAP handle
CODE:
    RETVAL = DeleteObject((HGDIOBJ) handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Font
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::Font

    ###########################################################################
    # (@)INTERNAL:Create(%OPTIONS)
    # Used by new Win32::GUI::Font.
void
Create(...)
PPCODE:
    int nHeight;
    int nWidth;
    int nEscapement;
    int nOrientation;
    int fnWeight;
    DWORD fdwItalic;
    DWORD fdwUnderline;
    DWORD fdwStrikeOut;
    DWORD fdwCharSet;
    DWORD fdwOutputPrecision;
    DWORD fdwClipPrecision;
    DWORD fdwQuality;
    DWORD fdwPitchAndFamily;
    char lpszFace[32];                        // pointer to typeface name string
    int i, next_i;
    char *option;

    nHeight = 0;                              // logical height of font
    nWidth = 0;                               // logical average character width
    nEscapement = 0;                          // angle of escapement
    nOrientation = 0;                         // base-line orientation angle
    fnWeight = 400;                           // font weight
    fdwItalic = 0;                            // italic attribute flag
    fdwUnderline = 0;                         // underline attribute flag
    fdwStrikeOut = 0;                         // strikeout attribute flag
    fdwCharSet = DEFAULT_CHARSET;             // character set identifier
    fdwOutputPrecision = OUT_DEFAULT_PRECIS;  // output precision
    fdwClipPrecision = CLIP_DEFAULT_PRECIS;   // clipping precision
    fdwQuality = DEFAULT_QUALITY;             // output quality
    fdwPitchAndFamily = DEFAULT_PITCH
                      | FF_DONTCARE;          // pitch and family

    next_i = -1;
    for(i = 0; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-height") == 0
            || strcmp(option, "-size") == 0) {
                next_i = i + 1;
                nHeight = (int) SvIV(ST(next_i));
            }
            if(strcmp(option, "-width") == 0) {
                next_i = i + 1;
                nWidth = (int) SvIV(ST(next_i));
            }
            if(strcmp(option, "-escapement") == 0) {
                next_i = i + 1;
                nEscapement = (int) SvIV(ST(next_i));
            }
            if(strcmp(option, "-orientation") == 0) {
                next_i = i + 1;
                nOrientation = (int) SvIV(ST(next_i));
            }
            if(strcmp(option, "-weight") == 0) {
                next_i = i + 1;
                fnWeight = (int) SvIV(ST(next_i));
            }
            if(strcmp(option, "-bold") == 0) {
                next_i = i + 1;
                if(SvIV(ST(next_i)) != 0) fnWeight = 700;
            }
            if(strcmp(option, "-italic") == 0) {
                next_i = i + 1;
                fdwItalic = (DWORD) SvIV(ST(next_i));
            }
            if(strcmp(option, "-underline") == 0) {
                next_i = i + 1;
                fdwUnderline = (DWORD) SvIV(ST(next_i));
            }
            if(strcmp(option, "-strikeout") == 0) {
                next_i = i + 1;
                fdwStrikeOut = (DWORD) SvIV(ST(next_i));
            }
            if(strcmp(option, "-charset") == 0) {
                next_i = i + 1;
                fdwCharSet = (DWORD) SvIV(ST(next_i));
            }
            if(strcmp(option, "-outputprecision") == 0) {
                next_i = i + 1;
                fdwOutputPrecision = (DWORD) SvIV(ST(next_i));
            }
            if(strcmp(option, "-clipprecision") == 0) {
                next_i = i + 1;
                fdwClipPrecision = (DWORD) SvIV(ST(next_i));
            }
            if(strcmp(option, "-quality") == 0) {
                next_i = i + 1;
                fdwQuality = (DWORD) SvIV(ST(next_i));
            }
            if(strcmp(option, "-family") == 0) {
                next_i = i + 1;
                fdwPitchAndFamily = (DWORD) SvIV(ST(next_i));
            }
            if(strcmp(option, "-name") == 0
            || strcmp(option, "-face") == 0) {
                next_i = i + 1;
                strncpy(lpszFace, SvPV_nolen(ST(next_i)), 32);
            }

        } else {
            next_i = -1;
        }
    }
    XSRETURN_IV((long) CreateFont(
        nHeight,
        nWidth,
        nEscapement,
        nOrientation,
        fnWeight,
        fdwItalic,
        fdwUnderline,
        fdwStrikeOut,
        fdwCharSet,
        fdwOutputPrecision,
        fdwClipPrecision,
        fdwQuality,
        fdwPitchAndFamily,
        (LPCTSTR) lpszFace)
    );


    ###########################################################################
    # (@)METHOD:GetMetrics()
    # Returns an associative array of information about the Font:
    #  -height
    #  -ascent
    #  -descent
    #  -ileading
    #  -eleading
    #  -avgwidth
    #  -maxwidth
    #  -overhang
    #  -aspectx
    #  -aspecty
    #  -firstchar
    #  -lastchar
    #  -breakchar
    #  -italic
    #  -underline
    #  -strikeout
    #  -flags
    #  -charset
void
GetMetrics(handle)
    HFONT handle
PREINIT:
    HDC hdc;
    TEXTMETRIC metrics;
PPCODE:
    ZeroMemory(&metrics, sizeof(TEXTMETRIC));
    hdc = CreateDC("DISPLAY", NULL, NULL, NULL);
    if(hdc != NULL) {
        SelectObject(hdc, (HGDIOBJ) handle);
        if(GetTextMetrics(hdc, &metrics)) {
            DeleteDC(hdc);
            EXTEND(SP, 38);
            XST_mPV( 0, "-height");
            XST_mIV( 1, metrics.tmHeight);
            XST_mPV( 2, "-ascent");
            XST_mIV( 3, metrics.tmAscent);
            XST_mPV( 4, "-descent");
            XST_mIV( 5, metrics.tmDescent);
            XST_mPV( 6, "-ileading");
            XST_mIV( 7, metrics.tmInternalLeading);
            XST_mPV( 8, "-eleading");
            XST_mIV( 9, metrics.tmExternalLeading);
            XST_mPV(10, "-avgwidth");
            XST_mIV(11, metrics.tmAveCharWidth);
            XST_mPV(12, "-maxwidth");
            XST_mIV(13, metrics.tmMaxCharWidth);
            XST_mPV(14, "-overhang");
            XST_mIV(15, metrics.tmOverhang);
            XST_mPV(16, "-aspectx");
            XST_mIV(17, metrics.tmDigitizedAspectX);
            XST_mPV(18, "-aspecty");
            XST_mIV(19, metrics.tmDigitizedAspectY);
            XST_mPV(20, "-firstchar");
            XST_mIV(21, metrics.tmFirstChar);
            XST_mPV(22, "-lastchar");
            XST_mIV(23, metrics.tmLastChar);
            XST_mPV(24, "-defchar");
            XST_mIV(25, metrics.tmDefaultChar);
            XST_mPV(26, "-breakchar");
            XST_mIV(27, metrics.tmBreakChar);
            XST_mPV(28, "-italic");
            XST_mIV(29, metrics.tmItalic);
            XST_mPV(30, "-underline");
            XST_mIV(31, metrics.tmUnderlined);
            XST_mPV(32, "-strikeout");
            XST_mIV(33, metrics.tmStruckOut);
            XST_mPV(34, "-flags");
            XST_mIV(35, metrics.tmPitchAndFamily);
            XST_mPV(36, "-charset");
            XST_mIV(37, metrics.tmCharSet);
            XSRETURN(38);
        } else {
            DeleteDC(hdc);
            XSRETURN_NO;
        }
    } else {
        XSRETURN_NO;
    }

    ###########################################################################
    # (@)METHOD:Info()
    # Returns an associative array of information about the Font, with
    # the same options given when creating the font.
void
Info(handle)
    HFONT handle
PREINIT:
    LOGFONT logfont;
PPCODE:
    ZeroMemory(&logfont, sizeof(LOGFONT));
    if(GetObject((HGDIOBJ) handle, sizeof(LOGFONT), (LPVOID) &logfont)) {
        EXTEND(SP, 28);
        XST_mPV( 0, "-height");
        XST_mIV( 1, logfont.lfHeight);
        XST_mPV( 2, "-width");
        XST_mIV( 3, logfont.lfWidth);
        XST_mPV( 4, "-escapement");
        XST_mIV( 5, logfont.lfEscapement);
        XST_mPV( 6, "-orientation");
        XST_mIV( 7, logfont.lfOrientation);
        XST_mPV( 8, "-weight");
        XST_mIV( 9, logfont.lfWeight);
        XST_mPV(10, "-italic");
        XST_mIV(11, logfont.lfItalic);
        XST_mPV(12, "-underline");
        XST_mIV(13, logfont.lfUnderline);
        XST_mPV(14, "-strikeout");
        XST_mIV(15, logfont.lfStrikeOut);
        XST_mPV(16, "-charset");
        XST_mIV(17, logfont.lfCharSet);
        XST_mPV(18, "-outputprecision");
        XST_mIV(19, logfont.lfOutPrecision);
        XST_mPV(20, "-clipprecision");
        XST_mIV(21, logfont.lfClipPrecision);
        XST_mPV(22, "-quality");
        XST_mIV(23, logfont.lfQuality);
        XST_mPV(24, "-family");
        XST_mIV(25, logfont.lfPitchAndFamily);
        XST_mPV(26, "-name");
        XST_mPV(27, logfont.lfFaceName);
        XSRETURN(28);
    } else {
        XSRETURN_NO;
    }


    ###########################################################################
    # (@)INTERNAL:DESTROY(handle)
BOOL
DESTROY(handle)
    HFONT handle
CODE:
    RETVAL = DeleteObject((HGDIOBJ) handle);
OUTPUT:
    RETVAL


    ###########################################################################
    #(@)PACKAGE:Win32::GUI::DC
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::DC


    ###########################################################################
    # (@)INTERNAL:CreateDC(DRIVER, DEVICE)
    # Used by new Win32::GUI::DC.
HDC
CreateDC(driver, device)
    LPCTSTR driver
    LPCTSTR device
CODE:
    RETVAL = CreateDC(driver, device, NULL, NULL);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:DeleteDC(HANDLE)
BOOL
DeleteDC(handle)
    HDC handle
CODE:
    RETVAL = DeleteDC(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:GetDC(HANDLE)
    # Gets a handle to the DC associated with the given window
    # (eg. gets an HDC from an HWND).
    # Used by new Win32::GUI::DC
HDC
GetDC(handle)
    HWND handle
CODE:
    RETVAL = GetDC(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:ReleaseDC(HWND, HDC)
    # Opposite of GetDC().
BOOL
ReleaseDC(hwnd, hdc)
    HWND hwnd
    HDC hdc
CODE:
    RETVAL = ReleaseDC(hwnd, hdc);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:TextColor([COLOR])
    # Gets or sets the text color.
long
TextColor(handle, color=-1)
    HDC handle
    COLORREF color
CODE:
    if(items == 1) {
        RETVAL = GetTextColor(handle);
    } else {
        RETVAL = SetTextColor(handle, color);
    }
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:BackColor([COLOR])
    # Gets or sets the background color.
long
BackColor(handle, color=-1)
    HDC handle
    COLORREF color
CODE:
    if(items == 1) {
        RETVAL = (long) GetBkColor(handle);
    } else {
        RETVAL = (long) SetBkColor(handle, color);
    }
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:BkMode([MODE])
    # Gets or sets the current background mix mode for the DC;
    # possible values are:
    #  1 TRANSPARENT
    #  2 OPAQUE
long
BkMode(handle, mode=-1)
    HDC handle
    int mode
CODE:
    if(items == 1) {
        RETVAL = (long) GetBkMode(handle);
    } else {
        RETVAL = (long) SetBkMode(handle, mode);
    }
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Save()
    # Saves the current state of the DC (this means the currently selected
    # colors, brushes, pens, drawing modes, etc.) to an internal stack.
    # The function returns a number identifying the saved state; this number
    # can then be passed to the Restore() function to load it back.
    # If the return value is zero, an error occurred.
    # See also Restore().
int
Save(handle)
    HDC handle
CODE:
    RETVAL = SaveDC(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Restore([STATE])
    # Restores the state of the DC saved by Save(). STATE can identify a state
    # from the saved stack (use the identifier returned by the corresponding
    # Save() call) or a negative number that specifies how many steps backwards
    # in the stack to recall (eg. -1 recalls the last saved state).
    # The default if STATE is not specified is -1.
    # Note that the restored state is removed from the stack, and if you restore
    # an early one, all the subsequent states will be removed too.
    # Returns nonzero if succesful, zero on errors.
    # See also Save().
BOOL
Restore(handle,state=-1)
    HDC handle
    int state
CODE:
    RETVAL = RestoreDC(handle, state);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:SetPixel(X, Y, [COLOR])
    # Sets the pixel at X, Y to the specified COLOR
    # (or to the current TextColor() if COLOR is not specified).
COLORREF
SetPixel(handle, x, y, color=-1)
    HDC handle
    int x
    int y
    COLORREF color
CODE:
    if(items == 3) {
        color = GetTextColor(handle);
    }
    RETVAL = SetPixel(handle, x, y, color);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:GetPixel(X, Y)
    # Returns the color of the pixel at X, Y.

COLORREF
GetPixel(handle, x, y)
    HDC handle
    int x
    int y
CODE:
    RETVAL = GetPixel(handle, x, y);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:MoveTo(X, Y)
    # Moves the current drawing position to the point specified by X, Y.
    # Returns nonzero if succesful, zero on errors.
long
MoveTo(handle, x, y)
    HDC handle
    int x
    int y
CODE:
    RETVAL = MoveToEx(handle, x, y, NULL);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:LineTo(X, Y)
    # Draws a line from the current drawing position up to, but not including,
    # the point specified by X, Y.
    # Returns nonzero if succesful, zero on errors.
long
LineTo(handle, x, y)
    HDC handle
    int x
    int y
CODE:
    RETVAL = LineTo(handle, x, y);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Circle(X, Y, (WIDTH, HEIGHT | RADIUS))
    # Draws a circle or an ellipse; X, Y, RADIUS specifies the center point
    # and the radius of the circle, while X, Y, WIDTH, HEIGHT specifies the
    # center point and the size of the ellipse.
    # Returns nonzero if succesful, zero on errors.
BOOL
Circle(handle, x, y, width, height=-1)
    HDC handle
    int x
    int y
    int width
    int height
CODE:
    if(height == -1) {
        width *= 2;
        height = width;
    }
    RETVAL = Arc(handle, x-width/2, y-height/2, width-x, height-y, 0, 0, 0, 0);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Arc(X, Y, RADIUS, START, SWEEP)
BOOL
Arc(handle, x, y, radius, start, sweep)
    HDC handle
    int x
    int y
    DWORD radius
    FLOAT start
    FLOAT sweep
CODE:
    RETVAL = AngleArc(handle, x, y, radius, start, sweep);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:TextOut(X, Y, TEXT)
BOOL
TextOut(handle, x, y, text)
    HDC handle
    int x
    int y
    char * text
CODE:
    RETVAL = TextOut(handle, x, y, text, strlen(text));
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:BeginPath()
BOOL
BeginPath(handle)
    HDC handle
CODE:
    RETVAL = BeginPath(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:EndPath()
BOOL
EndPath(handle)
    HDC handle
CODE:
    RETVAL = EndPath(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:StrokeAndFillPath()
BOOL
StrokeAndFillPath(handle)
    HDC handle
CODE:
    RETVAL = StrokeAndFillPath(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:FillPath()
BOOL
FillPath(handle)
    HDC handle
CODE:
    RETVAL = FillPath(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:StrokePath()
BOOL
StrokePath(handle)
    HDC handle
CODE:
    RETVAL = StrokePath(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:CloseFigure()
BOOL
CloseFigure(handle)
    HDC handle
CODE:
    RETVAL = CloseFigure(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:AbortPath()
BOOL
AbortPath(handle)
    HDC handle
CODE:
    RETVAL = AbortPath(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:MapMode([MODE])
int
MapMode(handle, mode=-1)
    HDC handle
    int mode
CODE:
    if(items == 1) {
        RETVAL = GetMapMode(handle);
    } else {
        RETVAL = SetMapMode(handle, mode);
    }
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:SelectObject(OBJECT)
HGDIOBJ
SelectObject(handle, object)
    HDC handle
    HGDIOBJ object
CODE:
    RETVAL = SelectObject(handle, object);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Rectangle(LEFT, TOP, RIGHT, BOTTOM)
BOOL
Rectangle(handle, left, top, right, bottom)
    HDC handle
    int left
    int top
    int right
    int bottom
CODE:
    RETVAL = Rectangle(handle, left, top, right, bottom);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Ellipse(LEFT, TOP, RIGHT, BOTTOM)
BOOL
Ellipse(handle, left, top, right, bottom)
    HDC handle
    int left
    int top
    int right
    int bottom
CODE:
    RETVAL = Ellipse(handle, left, top, right, bottom);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:InvertRect(LEFT, TOP, RIGHT, BOTTOM)
BOOL
InvertRect(handle, left, top, right, bottom)
    HDC handle
    int left
    int top
    int right
    int bottom
PREINIT:
    RECT rc;
CODE:
    rc.left = left;
    rc.top = top;
    rc.right = right;
    rc.bottom = bottom;
    RETVAL = InvertRect(handle, &rc);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Pie(LEFT, TOP, RIGHT, BOTTOM, XF, YF, XS, YS)
BOOL
Pie(handle, left, top, right, bottom, xf, yf, xs, ys)
    HDC handle
    int left
    int top
    int right
    int bottom
    int xf
    int yf
    int xs
    int ys
CODE:
    RETVAL = Pie(handle, left, top, right, bottom, xf, yf, xs, ys);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Fill(X, Y, [COLOR], [TYPE])
BOOL
Fill(handle, x, y, color=-1, type=FLOODFILLSURFACE)
    HDC handle
    int x
    int y
    COLORREF color
    UINT type
CODE:
    if(items == 3) {
        color = GetPixel(handle, x, y);
    }
    RETVAL = ExtFloodFill(handle, x, y, color, type);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:PaintDesktop()
    # Fills the DC content with the desktop pattern or wallpaper.
    # Returns nonzero if succesful, zero on errors.
BOOL
PaintDesktop(handle)
    HDC handle
CODE:
    RETVAL = PaintDesktop(handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)METHOD:Validate()
    # Validates (removes from the update region) the whole DC area.
    # This function is intended to be used in a Paint event;
    # see Win32::GUI::Graphic::Paint().
    # Returns nonzero if succesful, zero on errors.
BOOL
Validate(handle)
    SV* handle
CODE:
    HWND hwnd;
    SV** window;
    HV* self;
    char szKey[] = "-window";

    if(NULL != handle)  {
        if(SvROK(handle)) {
        	self = (HV*) SvRV(handle);
            window = hv_fetch(self, szKey, strlen(szKey), 0);
            if(SvMAGICAL(self)) mg_get(*window);
        	if(window != NULL) {
            	hwnd = (HWND) SvIV(*window);
            } else {
            	XSRETURN_NO;
            }
        } else {
            XSRETURN_NO;
        }
    } else {
    	XSRETURN_NO;
    }
    RETVAL = ValidateRect(hwnd, NULL);
OUTPUT:
    RETVAL

    ###########################################################################
    # (@)METHOD:GetUpdateRect([ERASE])
    # Returns the rectangle (as a four-element array containing left, top,
    # right, bottom coordinates) that needs to be updated.
    # If the update region is empty (eg. no need to update, the function
    # returns undef).
    # The optional ERASE parameter can be set to 1 to force an erase of
    # the update region, if there is any; by default, no erase action is
    # performed.
    # This function is intended to be used in a Paint event;
    # see Win32::GUI::Graphic::Paint().
void
GetUpdateRect(handle, erase=0)
    SV* handle
    BOOL erase
PREINIT:
    HWND hwnd;
    SV** window;
    HV* self;
    RECT myRect;
PPCODE:
    if(NULL != handle)  {
        if(SvROK(handle)) {
        	self = (HV*) SvRV(handle);
            window = hv_fetch(self, "-window", 7, 0);
            if(SvMAGICAL(self)) mg_get(*window);
        	if(window != NULL) {
            	hwnd = (HWND) SvIV(*window);
            } else {
            	XSRETURN_NO;
            }
        } else {
            XSRETURN_NO;
        }
    } else {
    	XSRETURN_NO;
    }
    ZeroMemory(&myRect, sizeof(RECT));
    if(GetUpdateRect(hwnd, &myRect, erase)) {
		EXTEND(SP, 4);
		XST_mIV(0, myRect.left);
		XST_mIV(1, myRect.top);
		XST_mIV(2, myRect.right);
		XST_mIV(3, myRect.bottom);
		XSRETURN(4);
	} else {
		XSRETURN_NO;
	}


    ###########################################################################
    # (@)METHOD:DrawEdge(LEFT, TOP, RIGHT, BOTTOM, [EDGE, FLAGS])
BOOL
DrawEdge(handle, left, top, right, bottom, edge=EDGE_RAISED, flags=BF_RECT)
    HDC handle
    int left
    int top
    int right
    int bottom
    UINT edge
    UINT flags
PREINIT:
    RECT rc;
CODE:
    rc.left = left;
    rc.top = top;
    rc.right = right;
    rc.bottom = bottom;
    RETVAL = DrawEdge(handle, &rc, edge, flags);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Brush
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::Brush


    ###########################################################################
    # (@)INTERNAL:Create(%OPTIONS)
void
Create(...)
PREINIT:
    LOGBRUSH lb;
    char *option;
    int i, next_i;
PPCODE:
    ZeroMemory(&lb, sizeof(LOGBRUSH));
    if(items == 1) {
        lb.lbStyle = BS_SOLID;
        lb.lbColor = SvCOLORREF(NOTXSCALL ST(0));
    } else {
        next_i = -1;
        for(i = 0; i < items; i++) {
            if(next_i == -1) {
                option = SvPV_nolen(ST(i));
                if(strcmp(option, "-pattern") == 0) {
                    next_i = i + 1;
                    lb.lbStyle = BS_PATTERN;
                    lb.lbHatch = (LONG) handle_From(NOTXSCALL ST(next_i));
                } else if(strcmp(option, "-hatch") == 0) {
                    next_i = i + 1;
                    lb.lbStyle = BS_HATCHED;
                    lb.lbHatch = (LONG) SvIV(ST(next_i));
                } else if(strcmp(option, "-color") == 0) {
                    next_i = i + 1;
                    lb.lbColor = SvCOLORREF(NOTXSCALL ST(next_i));
                } else if(strcmp(option, "-system") == 0) {
                    next_i = i + 1;
                    XSRETURN_IV((long) GetSysColorBrush(SvIV(ST(next_i))));
                }
            } else {
                next_i = -1;
            }
        }
    }
    XSRETURN_IV((long) CreateBrushIndirect(&lb));

    ###########################################################################
    # (@)METHOD:Info()
    # Returns an associative array of information about the Brush object, with
    # the same options given when creating the Brush.
void
Info(handle)
    HBRUSH handle
PREINIT:
    LOGBRUSH brush;
PPCODE:
    ZeroMemory(&brush, sizeof(LOGBRUSH));
    if(GetObject((HGDIOBJ) handle, sizeof(LOGBRUSH), &brush)) {
        if(brush.lbStyle & BS_PATTERN) {
            EXTEND(SP, 4);
            XST_mPV( 0, "-pattern");
            XST_mIV( 1, brush.lbHatch);
            XST_mPV( 2, "-color");
            XST_mIV( 3, brush.lbColor);
            XSRETURN(4);
        } else if(brush.lbStyle & BS_HATCHED) {
            EXTEND(SP, 4);
            XST_mPV( 0, "-hatch");
            XST_mIV( 1, brush.lbHatch);
            XST_mPV( 2, "-color");
            XST_mIV( 3, brush.lbColor);
            XSRETURN(4);
        } else {
            EXTEND(SP, 6);
            XST_mPV( 0, "-style");
            XST_mIV( 1, brush.lbStyle);
            XST_mPV( 2, "-hatch");
            XST_mIV( 3, brush.lbHatch);
            XST_mPV( 4, "-color");
            XST_mIV( 5, brush.lbColor);
            XSRETURN(6);
        }
    } else {
        XSRETURN_NO;
    }

    ###########################################################################
    # (@)INTERNAL:DESTROY(HANDLE)
BOOL
DESTROY(handle)
    HBRUSH handle
CODE:
    RETVAL = DeleteObject((HGDIOBJ) handle);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::Pen
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::Pen


    ###########################################################################
    # (@)INTERNAL:Create(%OPTIONS)
void
Create(...)
PPCODE:
    int penstyle;
    int penwidth;
    COLORREF pencolor;
    char *option;
    int i, next_i;
    penstyle = PS_SOLID;
    penwidth = 0;
    pencolor = RGB(0, 0, 0);
    if(items == 1) {
        pencolor = SvCOLORREF(NOTXSCALL ST(0));
    } else {
        next_i = -1;
        for(i = 0; i < items; i++) {
            if(next_i == -1) {
                option = SvPV_nolen(ST(i));
                if(strcmp(option, "-style") == 0) {
                    next_i = i + 1;
                    penstyle = (int) SvIV(ST(next_i));
                }
                if(strcmp(option, "-width") == 0) {
                    next_i = i + 1;
                    penwidth = (int) SvIV(ST(next_i));
                }
                if(strcmp(option, "-color") == 0) {
                    next_i = i + 1;
                    pencolor = SvCOLORREF(NOTXSCALL ST(next_i));
                }
            } else {
                next_i = -1;
            }
        }
    }
    XSRETURN_IV((long) CreatePen(penstyle, penwidth, pencolor));

    ###########################################################################
    # (@)METHOD:Info()
    # Returns an associative array of information about the Pen object, with
    # the same options given when creating the Pen.
void
Info(handle)
    HPEN handle
PREINIT:
    LOGPEN pen;
PPCODE:
    ZeroMemory(&pen, sizeof(LOGPEN));
    if(GetObject((HGDIOBJ) handle, sizeof(LOGPEN), &pen)) {
        EXTEND(SP, 6);
        XST_mPV( 0, "-style");
        XST_mIV( 1, pen.lopnStyle);
        XST_mPV( 2, "-width");
        XST_mIV( 3, pen.lopnWidth.x);
        XST_mPV( 4, "-color");
        XST_mIV( 5, pen.lopnColor);
        XSRETURN(6);
    } else {
        XSRETURN_NO;
    }

    ###########################################################################
    # (@)INTERNAL:DESTROY(HANDLE)
BOOL
DESTROY(handle)
    HPEN handle
CODE:
    RETVAL = DeleteObject((HGDIOBJ) handle);
	OUTPUT:
    RETVAL


    ###########################################################################
    # (@)PACKAGE:Win32::GUI::NotifyIcon
    ###########################################################################

MODULE = Win32::GUI     PACKAGE = Win32::GUI::NotifyIcon


    ###########################################################################
    # (@)INTERNAL:Add(PARENT, %OPTIONS)
BOOL
Add(parent,...)
    HWND parent
PREINIT:
    int i, next_i;
    char * option;
    NOTIFYICONDATA nid;
CODE:
    ZeroMemory(&nid, sizeof(NOTIFYICONDATA));
    nid.cbSize = sizeof(NOTIFYICONDATA);
    nid.hWnd = parent;
    nid.uCallbackMessage = WM_NOTIFYICON;
    SwitchFlag(nid.uFlags, NIF_MESSAGE, 1);
    next_i = -1;
    for(i = 1; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-id") == 0) {
                next_i = i + 1;
                nid.uID = (UINT) SvIV(ST(next_i));
            } else if(strcmp(option, "-icon") == 0) {
                next_i = i + 1;
                nid.hIcon = (HICON) handle_From(NOTXSCALL ST(next_i));
                SwitchFlag(nid.uFlags, NIF_ICON, 1);
            } else if(strcmp(option, "-tip") == 0) {
                next_i = i + 1;
                strcpy(nid.szTip, SvPV_nolen(ST(next_i)));
                SwitchFlag(nid.uFlags, NIF_TIP, 1);
            }
        } else {
            next_i = -1;
        }
    }
    RETVAL = Shell_NotifyIcon(NIM_ADD, &nid);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:Modify(PARENT, %OPTIONS)
BOOL
Modify(parent,...)
    HWND parent
PREINIT:
    int i, next_i;
    char * option;
    NOTIFYICONDATA nid;
CODE:
    ZeroMemory(&nid, sizeof(NOTIFYICONDATA));
    nid.cbSize = sizeof(NOTIFYICONDATA);
    nid.hWnd = parent;
    next_i = -1;
    for(i = 1; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-id") == 0) {
                next_i = i + 1;
                nid.uID = (UINT) SvIV(ST(next_i));
            } else if(strcmp(option, "-icon") == 0) {
                next_i = i + 1;
                nid.hIcon = (HICON) handle_From(NOTXSCALL ST(next_i));
                SwitchFlag(nid.uFlags, NIF_ICON, 1);
            } else if(strcmp(option, "-tip") == 0) {
                next_i = i + 1;
                strcpy(nid.szTip, SvPV_nolen(ST(next_i)));
                SwitchFlag(nid.uFlags, NIF_TIP, 1);
            }
        } else {
            next_i = -1;
        }
    }
    RETVAL = Shell_NotifyIcon(NIM_MODIFY, &nid);
OUTPUT:
    RETVAL


    ###########################################################################
    # (@)INTERNAL:Delete(PARENT, %OPTIONS)
BOOL
Delete(parent,...)
    HWND parent
PREINIT:
    int i, next_i;
    char * option;
    NOTIFYICONDATA nid;
CODE:
    ZeroMemory(&nid, sizeof(NOTIFYICONDATA));
    nid.cbSize = sizeof(NOTIFYICONDATA);
    nid.hWnd = parent;
    next_i = -1;
    for(i = 1; i < items; i++) {
        if(next_i == -1) {
            option = SvPV_nolen(ST(i));
            if(strcmp(option, "-id") == 0) {
                next_i = i + 1;
                nid.uID = (UINT) SvIV(ST(next_i));
            } else if(strcmp(option, "-icon") == 0) {
                next_i = i + 1;
                nid.hIcon = (HICON) handle_From(NOTXSCALL ST(next_i));
                SwitchFlag(nid.uFlags, NIF_ICON, 1);
            } else if(strcmp(option, "-tip") == 0) {
                next_i = i + 1;
                strcpy(nid.szTip, SvPV_nolen(ST(next_i)));
                SwitchFlag(nid.uFlags, NIF_TIP, 1);
            }
        } else {
            next_i = -1;
        }
    }
    RETVAL = Shell_NotifyIcon(NIM_DELETE, &nid);
OUTPUT:
    RETVAL

BOOT:
    {
        INITCOMMONCONTROLSEX icce;
        icce.dwSize = sizeof(INITCOMMONCONTROLSEX);
        icce.dwICC = ICC_ANIMATE_CLASS | ICC_BAR_CLASSES | ICC_COOL_CLASSES
                   | ICC_LISTVIEW_CLASSES | ICC_PROGRESS_CLASS
                   | ICC_TAB_CLASSES | ICC_TREEVIEW_CLASSES
                   | ICC_UPDOWN_CLASS | ICC_USEREX_CLASSES
				   | ICC_DATE_CLASSES;
        if(!InitCommonControlsEx(&icce)) {
            warn("Win32::GUI: Unable to init common controls!\n");
        }

    }

