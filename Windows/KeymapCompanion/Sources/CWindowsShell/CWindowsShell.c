#include "CWindowsShell.h"
#include "CWindowsTrayIcon.h"

#include <windows.h>
#include <commdlg.h>
#include <shellapi.h>
#include <stdlib.h>

#define KEYMAP_TRAY_MESSAGE (WM_APP + 0x42)
#define KEYMAP_TRAY_WINDOW_CLASS L"KeymapCompanionTrayWindow"

struct keymap_tray_handle {
    HWND window;
    NOTIFYICONDATAW icon;
    HICON owned_icon;
    keymap_tray_callback callback;
    void *context;
    uint32_t connection_state;
    uint32_t keyboard_kind;
    uint32_t active_layer;
    BOOL uses_version_four;
};

static const wchar_t *keymap_tray_keyboard_name(uint32_t keyboard_kind) {
    switch (keyboard_kind) {
    case KEYMAP_TRAY_KEYBOARD_KYRIA:
        return L"Kyria Rev4";
    case KEYMAP_TRAY_KEYBOARD_ELORA:
        return L"Elora Rev2";
    default:
        return L"Keyboard Connected";
    }
}

static const wchar_t *keymap_tray_layer_name(uint32_t active_layer) {
    switch (active_layer) {
    case KEYMAP_TRAY_LAYER_QWERTY:
        return L"QWERTY";
    case KEYMAP_TRAY_LAYER_LOWER:
        return L"Lower";
    case KEYMAP_TRAY_LAYER_RAISE:
        return L"Raise";
    case KEYMAP_TRAY_LAYER_FUNCTION:
        return L"Function";
    default:
        return L"Default";
    }
}

static const wchar_t *keymap_tray_status_name(keymap_tray_handle *handle) {
    switch (handle->connection_state) {
    case KEYMAP_TRAY_CONNECTION_CONNECTED:
        return keymap_tray_keyboard_name(handle->keyboard_kind);
    case KEYMAP_TRAY_CONNECTION_DISCONNECTED:
        return L"Keyboard Disconnected";
    case KEYMAP_TRAY_CONNECTION_FAILED:
        return L"Keyboard Connection Error";
    default:
        return L"Searching for Keyboard";
    }
}

static void keymap_tray_update_tip(keymap_tray_handle *handle) {
    if (handle->connection_state == KEYMAP_TRAY_CONNECTION_CONNECTED) {
        swprintf_s(
            handle->icon.szTip,
            ARRAYSIZE(handle->icon.szTip),
            L"%s - %s layer",
            keymap_tray_keyboard_name(handle->keyboard_kind),
            keymap_tray_layer_name(handle->active_layer)
        );
    } else {
        wcscpy_s(
            handle->icon.szTip,
            ARRAYSIZE(handle->icon.szTip),
            keymap_tray_status_name(handle)
        );
    }
}

static void keymap_tray_show_menu(
    keymap_tray_handle *handle,
    POINT anchor
) {
    HMENU menu = CreatePopupMenu();
    if (menu == NULL) {
        return;
    }

    AppendMenuW(
        menu,
        MF_STRING | MF_DISABLED | MF_GRAYED,
        0,
        keymap_tray_status_name(handle)
    );
    if (handle->connection_state == KEYMAP_TRAY_CONNECTION_CONNECTED) {
        AppendMenuW(
            menu,
            MF_STRING | MF_DISABLED | MF_GRAYED,
            0,
            keymap_tray_layer_name(handle->active_layer)
        );
    }
    AppendMenuW(menu, MF_SEPARATOR, 0, NULL);
    AppendMenuW(menu, MF_STRING | MF_DEFAULT, KEYMAP_TRAY_OPEN, L"Open Keymap Companion");
    AppendMenuW(menu, MF_STRING, KEYMAP_TRAY_RECONNECT, L"Reconnect keyboard");
    AppendMenuW(menu, MF_SEPARATOR, 0, NULL);
    AppendMenuW(menu, MF_STRING, KEYMAP_TRAY_EXIT, L"Quit Keymap Companion");

    SetForegroundWindow(handle->window);
    UINT command = TrackPopupMenu(
        menu,
        TPM_RETURNCMD | TPM_RIGHTBUTTON | TPM_NONOTIFY,
        anchor.x,
        anchor.y,
        0,
        handle->window,
        NULL
    );
    PostMessageW(handle->window, WM_NULL, 0, 0);
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
        UINT notification = handle->uses_version_four
            ? LOWORD((DWORD_PTR)lparam)
            : (UINT)lparam;
        POINT anchor;
        if (handle->uses_version_four) {
            anchor.x = (LONG)(SHORT)LOWORD((DWORD_PTR)wparam);
            anchor.y = (LONG)(SHORT)HIWORD((DWORD_PTR)wparam);
        } else {
            GetCursorPos(&anchor);
        }

        if (notification == WM_RBUTTONUP || notification == WM_CONTEXTMENU) {
            if (anchor.x == -1 && anchor.y == -1) {
                GetCursorPos(&anchor);
            }
            keymap_tray_show_menu(handle, anchor);
        } else if (notification == WM_LBUTTONUP
                || notification == NIN_SELECT
                || notification == NIN_KEYSELECT) {
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
    handle->connection_state = KEYMAP_TRAY_CONNECTION_SEARCHING;
    handle->keyboard_kind = KEYMAP_TRAY_KEYBOARD_UNKNOWN;
    handle->active_layer = KEYMAP_TRAY_LAYER_DEFAULT;
    HWND window = CreateWindowExW(
        WS_EX_TOOLWINDOW,
        KEYMAP_TRAY_WINDOW_CLASS,
        L"Keymap Companion Tray",
        WS_POPUP,
        0, 0, 0, 0,
        NULL,
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
    handle->owned_icon = keymap_create_tray_icon(
        handle->connection_state,
        handle->keyboard_kind,
        handle->active_layer
    );
    if (handle->owned_icon == NULL) {
        handle->owned_icon = CopyIcon(LoadIconW(NULL, IDI_APPLICATION));
    }
    handle->icon.hIcon = handle->owned_icon;
    keymap_tray_update_tip(handle);
    if (!Shell_NotifyIconW(NIM_ADD, &handle->icon)) {
        DestroyIcon(handle->owned_icon);
        handle->owned_icon = NULL;
        DestroyWindow(window);
        return NULL;
    }
    handle->icon.uVersion = NOTIFYICON_VERSION_4;
    handle->uses_version_four = Shell_NotifyIconW(NIM_SETVERSION, &handle->icon);
    return handle;
}

void keymap_tray_update_state(
    keymap_tray_handle *handle,
    uint32_t connection_state,
    uint32_t keyboard_kind,
    uint32_t active_layer
) {
    if (handle == NULL
            || (handle->connection_state == connection_state
                && handle->keyboard_kind == keyboard_kind
                && handle->active_layer == active_layer)) {
        return;
    }

    HICON updated_icon = keymap_create_tray_icon(
        connection_state,
        keyboard_kind,
        active_layer
    );
    if (updated_icon == NULL) {
        return;
    }

    HICON previous_icon = handle->owned_icon;
    uint32_t previous_connection_state = handle->connection_state;
    uint32_t previous_keyboard_kind = handle->keyboard_kind;
    uint32_t previous_active_layer = handle->active_layer;
    handle->owned_icon = updated_icon;
    handle->connection_state = connection_state;
    handle->keyboard_kind = keyboard_kind;
    handle->active_layer = active_layer;
    handle->icon.hIcon = updated_icon;
    handle->icon.uFlags = NIF_ICON | NIF_TIP | NIF_SHOWTIP;
    keymap_tray_update_tip(handle);

    if (Shell_NotifyIconW(NIM_MODIFY, &handle->icon)) {
        DestroyIcon(previous_icon);
    } else {
        handle->owned_icon = previous_icon;
        handle->connection_state = previous_connection_state;
        handle->keyboard_kind = previous_keyboard_kind;
        handle->active_layer = previous_active_layer;
        handle->icon.hIcon = previous_icon;
        keymap_tray_update_tip(handle);
        DestroyIcon(updated_icon);
    }
}

void keymap_tray_destroy(keymap_tray_handle *handle) {
    if (handle == NULL) {
        return;
    }
    Shell_NotifyIconW(NIM_DELETE, &handle->icon);
    DestroyIcon(handle->owned_icon);
    handle->owned_icon = NULL;
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
