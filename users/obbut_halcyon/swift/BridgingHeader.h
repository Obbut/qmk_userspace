// Swift-C Bridging Header for QMK Keyboard Firmware
// SPDX-License-Identifier: GPL-2.0-or-later
//
// This header is standalone - Swift's clang can't include QMK headers
// because it doesn't have the ARM toolchain include paths.
// We declare the QMK functions we need; they're linked from the QMK build.

#pragma once

#include <stdint.h>
#include <stdbool.h>

// ============== TYPE DEFINITIONS ==============

typedef uint32_t layer_state_t;

typedef enum {
    OS_UNSURE,
    OS_LINUX,
    OS_WINDOWS,
    OS_MACOS,
    OS_IOS,
} os_variant_t;

// ============== LAYER DEFINITIONS ==============
// These must match the Swift Layer enum

enum swift_layers {
    LAYER_DEFAULT = 0,
    LAYER_QWERTY,
    LAYER_LOWER,
    LAYER_RAISE,
    LAYER_FUNCTION,
};

// ============== QMK FUNCTIONS (declared, linked from QMK) ==============
// These are real QMK functions, not glue wrappers

// Keyboard state
extern bool is_keyboard_master(void);
extern os_variant_t detected_host_os(void);

// Layer control
extern void layer_invert(uint8_t layer);

// Key sending
extern void tap_code(uint8_t keycode);
extern void tap_code16(uint16_t keycode);
extern void register_code(uint8_t keycode);
extern void unregister_code(uint8_t keycode);
extern void register_code16(uint16_t keycode);
extern void unregister_code16(uint16_t keycode);

// Timer functions
extern uint32_t timer_read32(void);
extern uint32_t timer_elapsed32(uint32_t last);

// RGB Matrix functions
extern void rgb_matrix_set_color(int index, uint8_t red, uint8_t green, uint8_t blue);
extern void rgb_matrix_set_color_all(uint8_t red, uint8_t green, uint8_t blue);

// ============== GLUE FUNCTIONS FOR MACROS ==============
// These wrap C macros/globals that Swift can't see directly.
// Implemented in swift_glue.c

// get_highest_layer() is a macro
extern uint8_t glue_get_highest_layer(layer_state_t state);

// layer_state is a global variable
extern layer_state_t glue_get_layer_state(void);

// MATRIX_ROWS and MATRIX_COLS are macros
extern uint8_t glue_matrix_rows(void);
extern uint8_t glue_matrix_cols(void);

// g_led_config.matrix_co[row][col] accesses a global struct
extern uint8_t glue_rgb_matrix_get_led_index(uint8_t row, uint8_t col);

// NO_LED is a macro
extern bool glue_led_index_valid(uint8_t led_index, uint8_t led_min, uint8_t led_max);

// keymap_key_to_keycode takes keypos_t struct
extern uint16_t glue_keymap_key_to_keycode(uint8_t layer, uint8_t row, uint8_t col);

// RGB preview mode state (managed in swift_glue.c, synced between halves)
extern bool glue_get_rgb_preview_mode(void);
extern void glue_set_rgb_preview_mode(bool mode);
