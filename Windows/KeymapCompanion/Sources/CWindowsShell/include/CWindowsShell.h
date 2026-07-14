#pragma once

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

keymap_tray_handle *keymap_tray_create(
    keymap_tray_callback callback,
    void *context
);
void keymap_tray_destroy(keymap_tray_handle *handle);

int32_t keymap_choose_color(uint8_t *red, uint8_t *green, uint8_t *blue);
int32_t keymap_prepare_overlay_window(const wchar_t *title);
void keymap_quit_application(void);

#ifdef __cplusplus
}
#endif
