// Shared code for Obbut's Halcyon keyboards (Kyria, Elora)
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include QMK_KEYBOARD_H
#include "transactions.h"
#include "os_detection.h"

// ============== LAYER DEFINITIONS ==============

enum layers {
    _DEFAULT = 0,
    _QWERTY,
    _LOWER,
    _RAISE,
    _FUNCTION,
};

#define LOWER    MO(_LOWER)
#define RAISE    MO(_RAISE)
#define FKEYS    MO(_FUNCTION)
#define TG_QWERTY  TG(_QWERTY)

// ============== CUSTOM KEYCODES ==============

// Aerospace window manager modifier (Cmd+Ctrl+Opt)
#define AEROSPACE LCTL(LGUI(KC_RALT))

// macOS screenshot (Cmd+Ctrl+Shift+4)
#define SCREENSHOT LGUI(LCTL(LSFT(KC_4)))

// ============== SHARED ROW MACROS ==============
// These define the key content for each row, shared between Kyria and Elora.
// The alpha rows (3x6) are identical between keyboards.

// ----- DEFAULT LAYER -----

// Alpha row 1 (Tab row)
#define DEFAULT_L1   KC_TAB,  KC_Q,    KC_W,    KC_F,    KC_P,    KC_B
#define DEFAULT_R1   KC_J,    KC_L,    KC_U,    KC_Y,    KC_SCLN, KC_BSPC

// Alpha row 2 (Home row)
#define DEFAULT_L2   KC_ESC,  KC_A,    KC_R,    KC_S,    KC_T,    KC_G
#define DEFAULT_R2   KC_M,    KC_N,    KC_E,    KC_I,    KC_O,    KC_QUOT

// Alpha row 3 (Bottom row) - 6 keys each side
#define DEFAULT_L3   KC_LSFT, KC_Z,    KC_X,    KC_C,    KC_D,    KC_V
#define DEFAULT_R3   KC_K,    KC_H,    KC_COMM, KC_DOT,  KC_SLSH, KC_ENT

// Thumb row - 5 keys each side
#define DEFAULT_THUMB_L   SCREENSHOT, KC_LCTL, KC_LGUI, AEROSPACE, KC_SPC
#define DEFAULT_THUMB_R   KC_NO,      KC_SPC,  RAISE,   LOWER,     KC_NO

// Module row (extra keys for modules) - 5 keys each side
#define DEFAULT_MODULE_L  KC_NO, KC_NO, KC_NO, KC_NO, KC_NO
#define DEFAULT_MODULE_R  KC_NO, KC_NO, KC_NO, KC_NO, KC_NO

// Number row (Elora only)
#define DEFAULT_NUM_L   KC_GRV,  KC_1,    KC_2,    KC_3,    KC_4,    KC_5
#define DEFAULT_NUM_R   KC_6,    KC_7,    KC_8,    KC_9,    KC_0,    KC_MINS

// ----- QWERTY LAYER (Gaming) -----

#define QWERTY_L1   KC_TAB,  KC_Q,    KC_W,    KC_E,    KC_R,    KC_T
#define QWERTY_R1   KC_Y,    KC_U,    KC_I,    KC_O,    KC_P,    KC_BSPC

#define QWERTY_L2   KC_ESC,  KC_A,    KC_S,    KC_D,    KC_F,    KC_G
#define QWERTY_R2   KC_H,    KC_J,    KC_K,    KC_L,    KC_SCLN, KC_QUOT

#define QWERTY_L3   KC_LSFT, KC_Z,    KC_X,    KC_C,    KC_V,    KC_B
#define QWERTY_R3   KC_N,    KC_M,    KC_COMM, KC_DOT,  KC_SLSH, KC_ENT

// Thumb: Simplified left side for gaming (CTRL, ALT, then all spaces)
#define QWERTY_THUMB_L   KC_LCTL, KC_LALT, KC_SPC, KC_SPC, KC_SPC
#define QWERTY_THUMB_R   KC_NO,   KC_SPC,  RAISE,  LOWER,  KC_NO

#define QWERTY_MODULE_L  KC_NO, KC_NO, KC_NO, KC_NO, KC_NO
#define QWERTY_MODULE_R  KC_NO, KC_NO, KC_NO, KC_NO, KC_NO

// Number row (Elora only) - same as default
#define QWERTY_NUM_L   KC_GRV,  KC_1,    KC_2,    KC_3,    KC_4,    KC_5
#define QWERTY_NUM_R   KC_6,    KC_7,    KC_8,    KC_9,    KC_0,    KC_MINS

// ----- LOWER LAYER (Navigation) -----

#define LOWER_L1   _______, _______, _______, _______, _______, _______
#define LOWER_R1   _______, _______, _______, _______, KC_DEL,  KC_BSPC

#define LOWER_L2   _______, _______, _______, _______, _______, _______
#define LOWER_R2   KC_LEFT, KC_DOWN, KC_UP,   KC_RGHT, _______, _______

#define LOWER_L3   _______, _______, _______, _______, _______, _______
#define LOWER_R3   _______, _______, _______, _______, _______, _______

#define LOWER_THUMB_L   _______, _______, _______, _______, _______
#define LOWER_THUMB_R   _______, _______, _______, _______, _______

#define LOWER_MODULE_L  _______, _______, _______, _______, _______
#define LOWER_MODULE_R  _______, _______, _______, _______, _______

// Number row transparent (Elora only)
#define LOWER_NUM_L   _______, _______, _______, _______, _______, _______
#define LOWER_NUM_R   _______, _______, _______, _______, _______, _______

// ----- RAISE LAYER (Symbols/Numbers) -----

#define RAISE_L1   KC_GRV,  KC_EXLM, KC_AT,   KC_LBRC, KC_RBRC, _______
#define RAISE_R1   KC_COLN, KC_7,    KC_8,    KC_9,    KC_MINS, _______

#define RAISE_L2   _______, KC_HASH, KC_DLR,  KC_LPRN, KC_RPRN, KC_COLN
#define RAISE_R2   _______, KC_4,    KC_5,    KC_6,    KC_PLUS, KC_EQL

#define RAISE_L3   _______, KC_PERC, KC_CIRC, KC_LCBR, KC_RCBR, _______
#define RAISE_R3   KC_0,    KC_1,    KC_2,    KC_3,    KC_DOT,  KC_BSLS

#define RAISE_THUMB_L   _______, _______, _______, _______, _______
#define RAISE_THUMB_R   _______, _______, _______, _______, _______

#define RAISE_MODULE_L  _______, _______, _______, _______, _______
#define RAISE_MODULE_R  _______, _______, _______, _______, _______

// Number row transparent (Elora only) - pass through to base layer numbers
#define RAISE_NUM_L   _______, _______, _______, _______, _______, _______
#define RAISE_NUM_R   _______, _______, _______, _______, _______, _______

// ----- FUNCTION LAYER (F-keys, RGB, Boot) -----

#define FUNC_L1   _______, KC_F11,  KC_F12,  KC_F13,  KC_F14,  KC_F15
#define FUNC_R1   _______, _______, _______, _______, _______, _______

#define FUNC_L2   QK_BOOT, KC_F6,   KC_F7,   KC_F8,   KC_F9,   KC_F10
#define FUNC_R2   RM_TOGG, RM_SATU, RM_HUEU, RM_VALU, RM_NEXT, QK_BOOT

#define FUNC_L3   _______, KC_F1,   KC_F2,   KC_F3,   KC_F4,   KC_F5
#define FUNC_R3   _______, RM_SATD, RM_HUED, RM_VALD, RM_PREV, _______

#define FUNC_THUMB_L   _______, _______, _______, _______, _______
#define FUNC_THUMB_R   _______, _______, _______, _______, _______

#define FUNC_MODULE_L  _______, _______, _______, _______, _______
#define FUNC_MODULE_R  _______, _______, _______, _______, _______

// Number row transparent (Elora only)
#define FUNC_NUM_L   _______, _______, _______, _______, _______, _______
#define FUNC_NUM_R   _______, _______, _______, _______, _______, _______

// ============== SHARED ENCODER MAPS ==============
// Define encoder behavior per layer (same for all Halcyon keyboards)

#define ENCODER_MAP_DEFAULT   ENCODER_CCW_CW(KC_VOLD, KC_VOLU)
#define ENCODER_MAP_QWERTY    ENCODER_CCW_CW(KC_VOLD, KC_VOLU)
#define ENCODER_MAP_LOWER     ENCODER_CCW_CW(KC_MPRV, KC_MNXT)
#define ENCODER_MAP_RAISE     ENCODER_CCW_CW(KC_VOLD, KC_VOLU)
#define ENCODER_MAP_FUNCTION  ENCODER_CCW_CW(RM_PREV, RM_NEXT)

// ============== LAYOUT WRAPPER MACROS ==============
// These wrapper macros force expansion of row macros before passing to LAYOUT.
// This is necessary because the C preprocessor doesn't expand macro arguments
// before substitution - we need the rescan that happens with __VA_ARGS__.

#if defined(KEYBOARD_splitkb_halcyon_kyria_rev4)
#define LAYOUT_wrapper(...) LAYOUT_split_3x6_5_hlc(__VA_ARGS__)
#endif

#if defined(KEYBOARD_splitkb_halcyon_elora_rev2)
#define LAYOUT_wrapper(...) LAYOUT_elora_hlc(__VA_ARGS__)
#endif

// ============== SHARED FUNCTION DECLARATIONS ==============

void obbut_keyboard_post_init(void);
void obbut_housekeeping_task(void);
bool obbut_process_record(uint16_t keycode, keyrecord_t *record);
layer_state_t obbut_layer_state_set(layer_state_t state);

#if defined(RGB_MATRIX_ENABLE)
bool obbut_rgb_matrix_indicators(uint8_t led_min, uint8_t led_max);
#endif

#ifdef POINTING_DEVICE_ENABLE
report_mouse_t pointing_device_task_user(report_mouse_t mouse_report);
#endif
