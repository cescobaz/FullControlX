#include <tchar.h>
#include <windows.h>

void NotifyIconCreate(_In_ HINSTANCE hInstance, _In_ HWND hWnd);
void NotifyIconRemove(_In_ HWND hWnd);

boolean NotifyIconHandleMsg(_In_ HWND   hWnd,
    _In_ UINT   message,
    _In_ WPARAM wParam,
    _In_ LPARAM lParam);