#pragma once

#include <windows.h>
#include <stdint.h>

HICON keymap_create_tray_icon(
    uint32_t connection_state,
    uint32_t keyboard_kind,
    uint32_t active_layer
);
