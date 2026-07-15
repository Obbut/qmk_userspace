#pragma once

#include "KeymapCompanionResources.h"

#include <stdint.h>
#include <wchar.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct keymap_tray_handle keymap_tray_handle;
typedef void (*keymap_tray_callback)(uint32_t command, void *context);

enum {
    KEYMAP_TRAY_OPEN = 1,
    KEYMAP_TRAY_RECONNECT = 2,
    KEYMAP_TRAY_EXIT = 3
};

enum {
    KEYMAP_TRAY_CONNECTION_SEARCHING = 0,
    KEYMAP_TRAY_CONNECTION_CONNECTED = 1,
    KEYMAP_TRAY_CONNECTION_DISCONNECTED = 2,
    KEYMAP_TRAY_CONNECTION_FAILED = 3
};

enum {
    KEYMAP_TRAY_KEYBOARD_UNKNOWN = 0,
    KEYMAP_TRAY_KEYBOARD_KYRIA = 1,
    KEYMAP_TRAY_KEYBOARD_ELORA = 2
};

enum {
    KEYMAP_TRAY_LAYER_DEFAULT = 0,
    KEYMAP_TRAY_LAYER_QWERTY = 1,
    KEYMAP_TRAY_LAYER_LOWER = 2,
    KEYMAP_TRAY_LAYER_RAISE = 3,
    KEYMAP_TRAY_LAYER_FUNCTION = 4
};

keymap_tray_handle *keymap_tray_create(
    keymap_tray_callback callback,
    void *context
);
void keymap_tray_destroy(keymap_tray_handle *handle);
void keymap_tray_update_state(
    keymap_tray_handle *handle,
    uint32_t connection_state,
    uint32_t keyboard_kind,
    uint32_t active_layer
);

int32_t keymap_choose_color(uint8_t *red, uint8_t *green, uint8_t *blue);
int32_t keymap_prepare_overlay_window(const wchar_t *title);
void keymap_quit_application(void);

#ifdef __cplusplus
}
#endif
