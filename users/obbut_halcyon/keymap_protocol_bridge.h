// Narrow platform boundary between QMK and the Embedded Swift protocol engine.
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <stdint.h>

#if defined(__clang__)
#    define KEYMAP_PROTOCOL_NONNULL _Nonnull
#else
#    define KEYMAP_PROTOCOL_NONNULL
#endif

// Adapter-local keyboard identifiers. Swift maps these to stable wire values.
#define KEYMAP_PROTOCOL_PLATFORM_KEYBOARD_KYRIA 0
#define KEYMAP_PROTOCOL_PLATFORM_KEYBOARD_ELORA 1

// Adapter-local semantic roles. They deliberately are not wire-format values.
#define KEYMAP_PROTOCOL_PLATFORM_SEMANTIC_NONE 0
#define KEYMAP_PROTOCOL_PLATFORM_SEMANTIC_SCREENSHOT 1
#define KEYMAP_PROTOCOL_PLATFORM_SEMANTIC_AEROSPACE 2
#define KEYMAP_PROTOCOL_PLATFORM_SEMANTIC_POINTER_LEFT_CLICK 3
#define KEYMAP_PROTOCOL_PLATFORM_SEMANTIC_POINTER_RIGHT_CLICK 4
#define KEYMAP_PROTOCOL_PLATFORM_SEMANTIC_POINTER_MIDDLE_CLICK 5
#define KEYMAP_PROTOCOL_PLATFORM_SEMANTIC_BROWSER_BACK 6
#define KEYMAP_PROTOCOL_PLATFORM_SEMANTIC_BROWSER_FORWARD 7
#define KEYMAP_PROTOCOL_PLATFORM_SEMANTIC_POINTER_SCROLL 8
#define KEYMAP_PROTOCOL_PLATFORM_SEMANTIC_POINTER_SNIPER 9
#define KEYMAP_PROTOCOL_PLATFORM_SEMANTIC_POINTER_DRAG_LOCK 10
#define KEYMAP_PROTOCOL_PLATFORM_SEMANTIC_POINTER_SENSITIVITY_DOWN 11
#define KEYMAP_PROTOCOL_PLATFORM_SEMANTIC_POINTER_SENSITIVITY_UP 12
#define KEYMAP_PROTOCOL_PLATFORM_SEMANTIC_POINTER_SCROLL_SPEED_DOWN 13
#define KEYMAP_PROTOCOL_PLATFORM_SEMANTIC_POINTER_SCROLL_SPEED_UP 14

// Adapter-local presentation roles. Swift maps them to KeymapProtocol.KeyStyle.
#define KEYMAP_PROTOCOL_PLATFORM_STYLE_STANDARD 0
#define KEYMAP_PROTOCOL_PLATFORM_STYLE_PURPLE 1
#define KEYMAP_PROTOCOL_PLATFORM_STYLE_MAGENTA 2
#define KEYMAP_PROTOCOL_PLATFORM_STYLE_BLUE 3
#define KEYMAP_PROTOCOL_PLATFORM_STYLE_YELLOW 4
#define KEYMAP_PROTOCOL_PLATFORM_STYLE_CYAN 5
#define KEYMAP_PROTOCOL_PLATFORM_STYLE_GREEN 6
#define KEYMAP_PROTOCOL_PLATFORM_STYLE_DARK_GREEN 7
#define KEYMAP_PROTOCOL_PLATFORM_STYLE_RED 8
#define KEYMAP_PROTOCOL_PLATFORM_STYLE_ORANGE 9

// A point-in-time view of the QMK state needed by the protocol engine.
typedef struct {
    uint32_t timestamp;
    uint32_t layer_state_mask;
    uint32_t default_layer_state_mask;
    uint8_t  keyboard;
    uint8_t  highest_active_layer;
    uint8_t  layer_count;
    uint8_t  matrix_row_count;
    uint8_t  matrix_column_count;
    uint8_t  encoder_count;
    uint8_t  includes_rgb_settings;
    uint8_t  rgb_effect_index;
    uint8_t  rgb_hue;
    uint8_t  rgb_saturation;
    uint8_t  rgb_brightness;
    uint8_t  is_rgb_enabled;
    uint8_t  rgb_speed;
} keymap_protocol_platform_snapshot_t;

// One compiled keymap entry enriched with keyboard-specific presentation roles.
typedef struct {
    uint16_t keycode;
    uint8_t  semantic_role;
    uint8_t  style_role;
} keymap_protocol_platform_entry_t;

// The only protocol entry points called by QMK.
void keymap_protocol_receive(const uint8_t *KEYMAP_PROTOCOL_NONNULL data, uint8_t length);
void keymap_protocol_housekeeping(void);

// QMK services consumed by the Swift protocol engine.
keymap_protocol_platform_snapshot_t keymap_protocol_platform_get_snapshot(void);
keymap_protocol_platform_entry_t keymap_protocol_platform_get_entry(uint16_t index);
void keymap_protocol_platform_send(uint8_t *KEYMAP_PROTOCOL_NONNULL data, uint8_t length);
uint8_t keymap_protocol_platform_apply_rgb(uint8_t effect_index, uint8_t hue, uint8_t saturation, uint8_t brightness, uint8_t is_enabled, uint8_t speed);
