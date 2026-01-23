// Swift-C Bridging Header for QMK Keyboard Firmware
// SPDX-License-Identifier: GPL-2.0-or-later
//
// This header is standalone - it does NOT include QMK headers.
// Swift only sees type definitions and function declarations here.
// The actual implementations are in swift_glue.c which includes QMK.

#pragma once

#include <stdint.h>
#include <stdbool.h>

// ============== LAYER STATE TYPE ==============

typedef uint32_t layer_state_t;

// ============== LAYER DEFINITIONS ==============
// These must match the Swift Layer enum and keymap.c

enum swift_layers {
    LAYER_DEFAULT = 0,
    LAYER_QWERTY,
    LAYER_LOWER,
    LAYER_RAISE,
    LAYER_FUNCTION,
};

// ============== OS DETECTION ==============

typedef enum {
    OS_UNSURE,
    OS_LINUX,
    OS_WINDOWS,
    OS_MACOS,
    OS_IOS,
} os_variant_t;

// ============== C GLUE FUNCTIONS ==============
// These are implemented in swift_glue.c and call QMK functions

// Keyboard state
extern bool glue_is_keyboard_master(void);
extern os_variant_t glue_detected_host_os(void);
extern uint8_t glue_get_highest_layer(layer_state_t state);
extern layer_state_t glue_get_layer_state(void);

// Layer control
extern void glue_layer_invert(uint8_t layer);

// Key sending
extern void glue_tap_code(uint8_t keycode);
extern void glue_tap_code16(uint16_t keycode);
extern void glue_register_code(uint8_t keycode);
extern void glue_unregister_code(uint8_t keycode);
extern void glue_register_code16(uint16_t keycode);
extern void glue_unregister_code16(uint16_t keycode);

// Timer functions
extern uint32_t glue_timer_read32(void);
extern uint32_t glue_timer_elapsed32(uint32_t t);

// RGB Matrix functions
// These are always declared but only implemented when RGB_MATRIX_ENABLE is defined
// The Swift code uses #if RGB_MATRIX_ENABLE to conditionally compile calls
extern void glue_rgb_matrix_set_color(uint8_t index, uint8_t r, uint8_t g, uint8_t b);
extern void glue_rgb_matrix_set_color_all(uint8_t r, uint8_t g, uint8_t b);
extern uint8_t glue_rgb_matrix_get_led_index(uint8_t row, uint8_t col);
extern uint8_t glue_matrix_rows(void);
extern uint8_t glue_matrix_cols(void);
extern bool glue_led_index_valid(uint8_t led_index, uint8_t led_min, uint8_t led_max);

// Keymap access
extern uint16_t glue_keymap_key_to_keycode(uint8_t layer, uint8_t row, uint8_t col);

// RGB preview mode (managed in swift_glue.c)
extern bool glue_get_rgb_preview_mode(void);
extern void glue_set_rgb_preview_mode(bool mode);

// ============== KEYCODE CONSTANTS ==============
// These are function calls because Swift can't see macros
// Implemented in swift_glue.c

extern uint16_t glue_kc_transparent(void);
extern uint16_t glue_kc_no(void);

// Layer keycodes
extern uint16_t glue_mo(uint8_t layer);
extern uint16_t glue_tg(uint8_t layer);

// RGB control keycodes
extern uint16_t glue_kc_rm_togg(void);
extern uint16_t glue_kc_rm_next(void);
extern uint16_t glue_kc_rm_prev(void);
extern uint16_t glue_kc_rm_hueu(void);
extern uint16_t glue_kc_rm_hued(void);
extern uint16_t glue_kc_rm_satu(void);
extern uint16_t glue_kc_rm_satd(void);
extern uint16_t glue_kc_rm_valu(void);
extern uint16_t glue_kc_rm_vald(void);

// System keycodes
extern uint16_t glue_kc_qk_boot(void);

// Modifier combinations
extern uint16_t glue_lctl(uint16_t kc);
extern uint16_t glue_lgui(uint16_t kc);
extern uint16_t glue_lalt(uint16_t kc);
extern uint16_t glue_lsft(uint16_t kc);

// Custom keycodes
extern uint16_t glue_kc_screenshot(void);
extern uint16_t glue_kc_aerospace(void);

// Basic keycodes
extern uint16_t glue_kc_a(void);
extern uint16_t glue_kc_delete(void);
extern uint16_t glue_kc_backspace(void);
extern uint16_t glue_kc_left(void);
extern uint16_t glue_kc_down(void);
extern uint16_t glue_kc_up(void);
extern uint16_t glue_kc_right(void);
extern uint16_t glue_kc_home(void);
extern uint16_t glue_kc_end(void);
extern uint16_t glue_kc_page_up(void);
extern uint16_t glue_kc_page_down(void);
extern uint16_t glue_kc_print_screen(void);

// Number keycodes (for Raise layer indicators)
extern uint16_t glue_kc_1(void);
extern uint16_t glue_kc_2(void);
extern uint16_t glue_kc_3(void);
extern uint16_t glue_kc_4(void);
extern uint16_t glue_kc_5(void);
extern uint16_t glue_kc_6(void);
extern uint16_t glue_kc_7(void);
extern uint16_t glue_kc_8(void);
extern uint16_t glue_kc_9(void);
extern uint16_t glue_kc_0(void);

// Function keycodes (for Function layer indicators)
extern uint16_t glue_kc_f1(void);
extern uint16_t glue_kc_f2(void);
extern uint16_t glue_kc_f3(void);
extern uint16_t glue_kc_f4(void);
extern uint16_t glue_kc_f5(void);
extern uint16_t glue_kc_f6(void);
extern uint16_t glue_kc_f7(void);
extern uint16_t glue_kc_f8(void);
extern uint16_t glue_kc_f9(void);
extern uint16_t glue_kc_f10(void);
extern uint16_t glue_kc_f11(void);
extern uint16_t glue_kc_f12(void);
extern uint16_t glue_kc_f13(void);
extern uint16_t glue_kc_f14(void);
extern uint16_t glue_kc_f15(void);

// Punctuation/symbol keycodes (for Raise layer)
extern uint16_t glue_kc_grave(void);
extern uint16_t glue_kc_minus(void);
extern uint16_t glue_kc_equal(void);
extern uint16_t glue_kc_lbracket(void);
extern uint16_t glue_kc_rbracket(void);
extern uint16_t glue_kc_backslash(void);
