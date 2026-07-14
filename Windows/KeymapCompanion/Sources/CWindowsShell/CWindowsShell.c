#include "CWindowsShell.h"

#include <windows.h>
#include <commdlg.h>
#include <shellapi.h>
#include <stdlib.h>

#define KEYMAP_TRAY_MESSAGE (WM_APP + 0x42)
#define KEYMAP_TRAY_WINDOW_CLASS L"KeymapCompanionTrayWindow"

struct keymap_tray_handle {
    HWND window;
    NOTIFYICONDATAW icon;
    keymap_tray_callback callback;
    void *context;
};

static void keymap_tray_show_menu(keymap_tray_handle *handle) {
    HMENU menu = CreatePopupMenu();
    if (menu == NULL) {
        return;
    }
    AppendMenuW(menu, MF_STRING | MF_DEFAULT, KEYMAP_TRAY_OPEN, L"Open Keymap Companion");
    AppendMenuW(menu, MF_STRING, KEYMAP_TRAY_RECONNECT, L"Reconnect keyboard");
    AppendMenuW(menu, MF_SEPARATOR, 0, NULL);
    AppendMenuW(menu, MF_STRING, KEYMAP_TRAY_EXIT, L"Exit");

    POINT point;
    GetCursorPos(&point);
    SetForegroundWindow(handle->window);
    UINT command = TrackPopupMenu(
        menu,
        TPM_RETURNCMD | TPM_RIGHTBUTTON | TPM_NONOTIFY,
        point.x,
        point.y,
        0,
        handle->window,
        NULL
    );
    DestroyMenu(menu);
    if (command != 0 && handle->callback != NULL) {
        handle->callback(command, handle->context);
    }
}

static LRESULT CALLBACK keymap_tray_window_proc(
    HWND window,
    UINT message,
    WPARAM wparam,
    LPARAM lparam
) {
    keymap_tray_handle *handle = (keymap_tray_handle *)GetWindowLongPtrW(
        window,
        GWLP_USERDATA
    );
    if (message == WM_NCCREATE) {
        CREATESTRUCTW *create = (CREATESTRUCTW *)lparam;
        handle = (keymap_tray_handle *)create->lpCreateParams;
        handle->window = window;
        SetWindowLongPtrW(window, GWLP_USERDATA, (LONG_PTR)handle);
    }

    if (message == KEYMAP_TRAY_MESSAGE && handle != NULL) {
        if (lparam == WM_RBUTTONUP || lparam == WM_CONTEXTMENU) {
            keymap_tray_show_menu(handle);
        } else if (lparam == WM_LBUTTONUP || lparam == WM_LBUTTONDBLCLK) {
            if (handle->callback != NULL) {
                handle->callback(KEYMAP_TRAY_OPEN, handle->context);
            }
        }
        return 0;
    }
    if (message == WM_NCDESTROY && handle != NULL) {
        SetWindowLongPtrW(window, GWLP_USERDATA, 0);
        free(handle);
        return 0;
    }
    return DefWindowProcW(window, message, wparam, lparam);
}

keymap_tray_handle *keymap_tray_create(
    keymap_tray_callback callback,
    void *context
) {
    HINSTANCE instance = GetModuleHandleW(NULL);
    WNDCLASSEXW window_class = {0};
    window_class.cbSize = sizeof(window_class);
    window_class.lpfnWndProc = keymap_tray_window_proc;
    window_class.hInstance = instance;
    window_class.lpszClassName = KEYMAP_TRAY_WINDOW_CLASS;
    RegisterClassExW(&window_class);

    keymap_tray_handle *handle = calloc(1, sizeof(*handle));
    if (handle == NULL) {
        return NULL;
    }
    handle->callback = callback;
    handle->context = context;
    HWND window = CreateWindowExW(
        0,
        KEYMAP_TRAY_WINDOW_CLASS,
        L"Keymap Companion Tray",
        0,
        0, 0, 0, 0,
        HWND_MESSAGE,
        NULL,
        instance,
        handle
    );
    if (window == NULL) {
        free(handle);
        return NULL;
    }

    handle->icon.cbSize = sizeof(handle->icon);
    handle->icon.hWnd = window;
    handle->icon.uID = 1;
    handle->icon.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP | NIF_SHOWTIP;
    handle->icon.uCallbackMessage = KEYMAP_TRAY_MESSAGE;
    handle->icon.hIcon = LoadIconW(NULL, IDI_APPLICATION);
    wcscpy_s(handle->icon.szTip, ARRAYSIZE(handle->icon.szTip), L"Keymap Companion");
    if (!Shell_NotifyIconW(NIM_ADD, &handle->icon)) {
        DestroyWindow(window);
        return NULL;
    }
    handle->icon.uVersion = NOTIFYICON_VERSION_4;
    Shell_NotifyIconW(NIM_SETVERSION, &handle->icon);
    return handle;
}

void keymap_tray_destroy(keymap_tray_handle *handle) {
    if (handle == NULL) {
        return;
    }
    Shell_NotifyIconW(NIM_DELETE, &handle->icon);
    DestroyWindow(handle->window);
}

int32_t keymap_choose_color(uint8_t *red, uint8_t *green, uint8_t *blue) {
    if (red == NULL || green == NULL || blue == NULL) {
        return 0;
    }
    COLORREF custom_colors[16] = {0};
    CHOOSECOLORW chooser = {0};
    chooser.lStructSize = sizeof(chooser);
    chooser.hwndOwner = GetActiveWindow();
    chooser.rgbResult = RGB(*red, *green, *blue);
    chooser.lpCustColors = custom_colors;
    chooser.Flags = CC_FULLOPEN | CC_RGBINIT | CC_ANYCOLOR;
    if (!ChooseColorW(&chooser)) {
        return 0;
    }
    *red = GetRValue(chooser.rgbResult);
    *green = GetGValue(chooser.rgbResult);
    *blue = GetBValue(chooser.rgbResult);
    return 1;
}

int32_t keymap_prepare_overlay_window(const wchar_t *title) {
    HWND window = FindWindowW(NULL, title);
    if (window == NULL) {
        return 0;
    }

    LONG_PTR style = GetWindowLongPtrW(window, GWL_STYLE);
    style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MAXIMIZEBOX | WS_MINIMIZEBOX | WS_SYSMENU);
    SetWindowLongPtrW(window, GWL_STYLE, style);
    LONG_PTR extended = GetWindowLongPtrW(window, GWL_EXSTYLE);
    extended |= WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE | WS_EX_TRANSPARENT;
    extended &= ~WS_EX_APPWINDOW;
    SetWindowLongPtrW(window, GWL_EXSTYLE, extended);

    POINT pointer;
    GetCursorPos(&pointer);
    HMONITOR monitor = MonitorFromPoint(pointer, MONITOR_DEFAULTTONEAREST);
    MONITORINFO info = {0};
    info.cbSize = sizeof(info);
    GetMonitorInfoW(monitor, &info);
    const int inset = 12;
    int available_width = info.rcWork.right - info.rcWork.left - inset * 2;
    int available_height = info.rcWork.bottom - info.rcWork.top - inset * 2;
    int width = available_width < 900 ? available_width : 900;
    int height = available_height < 420 ? available_height : 420;
    int x = info.rcWork.right - width - inset;
    int y = info.rcWork.top + inset;
    SetWindowPos(
        window,
        HWND_TOPMOST,
        x, y, width, height,
        SWP_NOACTIVATE | SWP_FRAMECHANGED | SWP_SHOWWINDOW
    );
    return 1;
}

void keymap_quit_application(void) {
    PostQuitMessage(0);
}
