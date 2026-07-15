#include "CWindowsTrayIcon.h"
#include "CWindowsShell.h"
#include "KeymapCompanionResources.h"

#include <string.h>

#define KEYMAP_TRAY_ICON_SIZE 64

static COLORREF keymap_icon_accent(uint32_t connection_state) {
    if (connection_state != KEYMAP_TRAY_CONNECTION_CONNECTED) {
        return RGB(112, 118, 132);
    }

    COLORREF accent = GetSysColor(COLOR_HIGHLIGHT);
    if (GetRValue(accent) + GetGValue(accent) + GetBValue(accent) < 40) {
        return RGB(0, 120, 215);
    }
    return accent;
}

static void keymap_draw_keyboard_icon(
    HDC device_context,
    uint32_t connection_state,
    uint32_t keyboard_kind
) {
    POINT kyria_outline[] = {
        {4, 12}, {44, 7}, {50, 29}, {61, 38}, {52, 56},
        {39, 45}, {27, 56}, {16, 51}, {4, 50}
    };
    POINT elora_outline[] = {
        {4, 10}, {48, 10}, {51, 29}, {61, 38}, {51, 55},
        {39, 45}, {26, 55}, {15, 51}, {4, 49}
    };
    POINT *outline = keyboard_kind == KEYMAP_TRAY_KEYBOARD_ELORA
        ? elora_outline
        : kyria_outline;
    int outline_count = keyboard_kind == KEYMAP_TRAY_KEYBOARD_ELORA
        ? ARRAYSIZE(elora_outline)
        : ARRAYSIZE(kyria_outline);

    COLORREF accent = keymap_icon_accent(connection_state);
    HPEN outline_pen = CreatePen(PS_SOLID, 3, RGB(22, 25, 34));
    HBRUSH plate_brush = CreateSolidBrush(accent);
    HPEN previous_pen = SelectObject(device_context, outline_pen);
    HBRUSH previous_brush = SelectObject(device_context, plate_brush);
    Polygon(device_context, outline, outline_count);

    HPEN key_pen = CreatePen(PS_NULL, 0, 0);
    HBRUSH key_brush = CreateSolidBrush(RGB(0, 0, 0));
    SelectObject(device_context, key_pen);
    SelectObject(device_context, key_brush);
    const int column_offsets[] = {3, 1, 0, 1, 3, 5};
    for (int column = 0; column < 6; ++column) {
        for (int row = 0; row < 3; ++row) {
            int left = 7 + column * 8;
            int top = 14 + row * 10 + column_offsets[column];
            RoundRect(device_context, left, top, left + 6, top + 7, 2, 2);
        }
    }
    RoundRect(device_context, 31, 45, 38, 52, 2, 2);
    RoundRect(device_context, 39, 48, 47, 55, 2, 2);

    SelectObject(device_context, previous_pen);
    SelectObject(device_context, previous_brush);
    DeleteObject(key_pen);
    DeleteObject(key_brush);
    DeleteObject(outline_pen);
    DeleteObject(plate_brush);
}

static void keymap_draw_layer_arrow(
    HDC device_context,
    BOOL points_up,
    COLORREF foreground
) {
    HPEN arrow_pen = CreatePen(PS_SOLID, 7, foreground);
    HPEN previous_pen = SelectObject(device_context, arrow_pen);
    int tip_y = points_up ? 17 : 47;
    int tail_y = points_up ? 47 : 17;
    int shoulder_y = points_up ? 29 : 35;

    MoveToEx(device_context, 32, tail_y, NULL);
    LineTo(device_context, 32, tip_y);
    MoveToEx(device_context, 19, shoulder_y, NULL);
    LineTo(device_context, 32, tip_y);
    LineTo(device_context, 45, shoulder_y);

    SelectObject(device_context, previous_pen);
    DeleteObject(arrow_pen);
}

static void keymap_draw_layer_text(
    HDC device_context,
    const wchar_t *text,
    int font_size,
    COLORREF foreground
) {
    HFONT font = CreateFontW(
        -font_size,
        0,
        0,
        0,
        FW_BLACK,
        FALSE,
        FALSE,
        FALSE,
        DEFAULT_CHARSET,
        OUT_DEFAULT_PRECIS,
        CLIP_DEFAULT_PRECIS,
        NONANTIALIASED_QUALITY,
        DEFAULT_PITCH | FF_SWISS,
        L"Segoe UI"
    );
    HFONT previous_font = SelectObject(device_context, font);
    SetBkMode(device_context, TRANSPARENT);
    SetTextColor(device_context, foreground);
    RECT bounds = {8, 7, 56, 57};
    DrawTextW(
        device_context,
        text,
        -1,
        &bounds,
        DT_CENTER | DT_VCENTER | DT_SINGLELINE | DT_NOPREFIX
    );
    SelectObject(device_context, previous_font);
    DeleteObject(font);
}

static void keymap_draw_layer_icon(
    HDC device_context,
    uint32_t connection_state,
    uint32_t active_layer
) {
    COLORREF accent = keymap_icon_accent(connection_state);
    COLORREF foreground = RGB(0, 0, 0);
    HPEN outline_pen = CreatePen(PS_SOLID, 4, RGB(22, 25, 34));
    HBRUSH tile_brush = CreateSolidBrush(accent);
    HPEN previous_pen = SelectObject(device_context, outline_pen);
    HBRUSH previous_brush = SelectObject(device_context, tile_brush);
    RoundRect(device_context, 6, 6, 58, 58, 15, 15);
    SelectObject(device_context, previous_pen);
    SelectObject(device_context, previous_brush);
    DeleteObject(outline_pen);
    DeleteObject(tile_brush);

    switch (active_layer) {
    case KEYMAP_TRAY_LAYER_QWERTY:
        keymap_draw_layer_text(device_context, L"Q", 38, foreground);
        break;
    case KEYMAP_TRAY_LAYER_LOWER:
        keymap_draw_layer_arrow(device_context, FALSE, foreground);
        break;
    case KEYMAP_TRAY_LAYER_RAISE:
        keymap_draw_layer_arrow(device_context, TRUE, foreground);
        break;
    case KEYMAP_TRAY_LAYER_FUNCTION:
        keymap_draw_layer_text(device_context, L"FN", 27, foreground);
        break;
    case KEYMAP_TRAY_LAYER_POINTER:
        keymap_draw_layer_text(device_context, L"P", 38, foreground);
        break;
    default:
        break;
    }
}

HICON keymap_create_tray_icon(
    uint32_t connection_state,
    uint32_t keyboard_kind,
    uint32_t active_layer
) {
    if (connection_state == KEYMAP_TRAY_CONNECTION_CONNECTED
            && keyboard_kind == KEYMAP_TRAY_KEYBOARD_KYRIA
            && active_layer == KEYMAP_TRAY_LAYER_DEFAULT) {
        HICON application_icon = LoadImageW(
            GetModuleHandleW(NULL),
            MAKEINTRESOURCEW(KEYMAP_COMPANION_ICON),
            IMAGE_ICON,
            KEYMAP_TRAY_ICON_SIZE,
            KEYMAP_TRAY_ICON_SIZE,
            LR_DEFAULTCOLOR
        );
        if (application_icon != NULL) {
            return application_icon;
        }
    }

    BITMAPV5HEADER header;
    memset(&header, 0, sizeof(header));
    header.bV5Size = sizeof(header);
    header.bV5Width = KEYMAP_TRAY_ICON_SIZE;
    header.bV5Height = -KEYMAP_TRAY_ICON_SIZE;
    header.bV5Planes = 1;
    header.bV5BitCount = 32;
    header.bV5Compression = BI_BITFIELDS;
    header.bV5RedMask = 0x00FF0000;
    header.bV5GreenMask = 0x0000FF00;
    header.bV5BlueMask = 0x000000FF;
    header.bV5AlphaMask = 0xFF000000;

    uint32_t *pixels = NULL;
    HBITMAP color_bitmap = CreateDIBSection(
        NULL,
        (BITMAPINFO *)&header,
        DIB_RGB_COLORS,
        (void **)&pixels,
        NULL,
        0
    );
    if (color_bitmap == NULL || pixels == NULL) {
        return NULL;
    }
    memset(
        pixels,
        0,
        KEYMAP_TRAY_ICON_SIZE * KEYMAP_TRAY_ICON_SIZE * sizeof(uint32_t)
    );

    HDC device_context = CreateCompatibleDC(NULL);
    if (device_context == NULL) {
        DeleteObject(color_bitmap);
        return NULL;
    }
    HBITMAP previous_bitmap = SelectObject(device_context, color_bitmap);
    if (connection_state == KEYMAP_TRAY_CONNECTION_CONNECTED
            && active_layer != KEYMAP_TRAY_LAYER_DEFAULT) {
        keymap_draw_layer_icon(device_context, connection_state, active_layer);
    } else {
        keymap_draw_keyboard_icon(device_context, connection_state, keyboard_kind);
    }
    SelectObject(device_context, previous_bitmap);
    DeleteDC(device_context);

    for (int index = 0; index < KEYMAP_TRAY_ICON_SIZE * KEYMAP_TRAY_ICON_SIZE; ++index) {
        if ((pixels[index] & 0x00FFFFFF) != 0) {
            pixels[index] |= 0xFF000000;
        }
    }

    BYTE mask_bits[KEYMAP_TRAY_ICON_SIZE * KEYMAP_TRAY_ICON_SIZE / 8] = {0};
    HBITMAP mask_bitmap = CreateBitmap(
        KEYMAP_TRAY_ICON_SIZE,
        KEYMAP_TRAY_ICON_SIZE,
        1,
        1,
        mask_bits
    );
    if (mask_bitmap == NULL) {
        DeleteObject(color_bitmap);
        return NULL;
    }

    ICONINFO icon_info;
    memset(&icon_info, 0, sizeof(icon_info));
    icon_info.fIcon = TRUE;
    icon_info.hbmMask = mask_bitmap;
    icon_info.hbmColor = color_bitmap;
    HICON icon = CreateIconIndirect(&icon_info);
    DeleteObject(mask_bitmap);
    DeleteObject(color_bitmap);
    return icon;
}
