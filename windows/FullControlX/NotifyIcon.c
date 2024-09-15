#include "NotifyIcon.h"
#include <windows.h>
#include <shellapi.h>
#include <tchar.h>
#include <Commctrl.h>
#include <strsafe.h>
#include "resource.h"

#define NOTIFICATION_TRAY_ICON_MSG (WM_USER + 0x100)

static UINT notifyIconId = 42;

void NotifyIconCreate(_In_ HINSTANCE hInstance, _In_ HWND hWnd) {
    NOTIFYICONDATA nid = { 0 };
    nid.cbSize = sizeof(nid);
    nid.hWnd = hWnd;
    nid.uFlags = NIF_ICON | NIF_TIP | NIF_MESSAGE | NIF_SHOWTIP | NIF_GUID;
    nid.uCallbackMessage = NOTIFICATION_TRAY_ICON_MSG;
    nid.uID = notifyIconId;
    StringCchCopy(nid.szTip, 64, _T("Test application"));
    LoadIconMetric(hInstance, MAKEINTRESOURCE(IDI_ICON1), LIM_SMALL, &nid.hIcon);

    Shell_NotifyIcon(NIM_ADD, &nid);

    nid.uVersion = NOTIFYICON_VERSION_4;
    Shell_NotifyIcon(NIM_SETVERSION, &nid);
}

void NotifyIconRemove(_In_ HWND hWnd) {
    NOTIFYICONDATA nid = { 0 };
    nid.cbSize = sizeof(nid);
    nid.hWnd = hWnd;
    nid.uID = notifyIconId;

    Shell_NotifyIcon(NIM_DELETE, &nid);
}


#define IDM_EXIT 100
#define IDM_FULLCONTROL_X 101

boolean NotifyIconHandleMsg(_In_ HWND   hWnd,
    _In_ UINT   message,
    _In_ WPARAM wParam,
    _In_ LPARAM lParam) {
    if (message != NOTIFICATION_TRAY_ICON_MSG) {
        return FALSE;
    }

    switch (LOWORD(lParam))
    {
    case NIN_SELECT:
    case NIN_KEYSELECT:
    case WM_CONTEXTMENU:
    {
        

        POINT pt;
        GetCursorPos(&pt);

        HMENU hmenu = CreatePopupMenu();
        InsertMenu(hmenu, 0, MF_BYPOSITION | MF_STRING, IDM_FULLCONTROL_X, _T("FullControl X"));
        InsertMenu(hmenu, 0, MF_BYPOSITION | MF_STRING, IDM_EXIT, _T("Quit"));

        int cmd = TrackPopupMenu(hmenu, TPM_LEFTALIGN | TPM_LEFTBUTTON | TPM_BOTTOMALIGN | TPM_NONOTIFY | TPM_RETURNCMD, pt.x, pt.y, 0, hWnd, NULL);

        PostMessage(hWnd, WM_NULL, 0, 0);

        switch (cmd)
        {
        case IDM_EXIT: 
            NotifyIconRemove(hWnd);
            PostQuitMessage(0);
            break;
        case IDM_FULLCONTROL_X: 
            //ShellExecute(0, 0, _T("start https://github.com/cescobaz/fullcontrolx"), 0, 0, SW_SHOW);
            system("start https://github.com/cescobaz/fullcontrolx");
            break;
        default:
            break;
        }

        break;
    }
    }

    return TRUE;
}