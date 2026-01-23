// Swift-C Bridging Header for QMK Keyboard Firmware
// SPDX-License-Identifier: GPL-2.0-or-later
//
// This header imports QMK headers so Swift can call QMK functions directly.
// Glue functions are only needed for C macros (which Swift can't see).

#pragma once

// ============== GENERATED CONFIG ==============
// Must be included before quantum.h to define MATRIX_ROWS, MATRIX_COLS, etc.
#include "info_config.h"

// ============== QMK HEADERS ==============
// These provide function declarations that Swift can call directly

#include "quantum.h"      // Main QMK header - includes most functions
#include "os_detection.h" // detected_host_os(), os_variant_t

#if defined(RGB_MATRIX_ENABLE)
#include "rgb_matrix.h"   // rgb_matrix_set_color(), etc.
#endif

// ============== LAYER DEFINITIONS ==============
// These must match the Swift Layer enum

enum swift_layers {
    LAYER_DEFAULT = 0,
    LAYER_QWERTY,
    LAYER_LOWER,
    LAYER_RAISE,
    LAYER_FUNCTION,
};

// ============== GLUE FUNCTIONS FOR MACROS ==============
// These wrap C macros/globals that Swift cannot see directly.
// Implemented in swift_glue.c

// get_highest_layer() is a macro
extern uint8_t glue_get_highest_layer(layer_state_t state);

// layer_state is a global variable
extern layer_state_t glue_get_layer_state(void);

#if defined(RGB_MATRIX_ENABLE)
// MATRIX_ROWS and MATRIX_COLS are macros
extern uint8_t glue_matrix_rows(void);
extern uint8_t glue_matrix_cols(void);

// g_led_config.matrix_co[row][col] accesses a global struct
extern uint8_t glue_rgb_matrix_get_led_index(uint8_t row, uint8_t col);

// NO_LED is a macro
extern bool glue_led_index_valid(uint8_t led_index, uint8_t led_min, uint8_t led_max);
#endif

// keymap_key_to_keycode takes keypos_t struct
extern uint16_t glue_keymap_key_to_keycode(uint8_t layer, uint8_t row, uint8_t col);

// RGB preview mode state (managed in swift_glue.c, synced between halves)
extern bool glue_get_rgb_preview_mode(void);
extern void glue_set_rgb_preview_mode(bool mode);
