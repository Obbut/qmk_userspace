// Copyright 2024 Robbert Brandsma
// SPDX-License-Identifier: GPL-2.0-or-later

#include QMK_KEYBOARD_H

enum layers {
    _DEFAULT = 0,
    _LOWER,
    _RAISE,
    _FUNCTION,
};

#define LOWER    MO(_LOWER)
#define RAISE    MO(_RAISE)
#define FKEYS    MO(_FUNCTION)

// Aerospace window manager modifier (Cmd+Ctrl+Opt)
#define AEROSPACE LCTL(LGUI(KC_RALT))

// macOS screenshot (Cmd+Ctrl+Shift+4)
#define SCREENSHOT LGUI(LCTL(LSFT(KC_4)))

// clang-format off
const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
    [_DEFAULT] = LAYOUT_split_3x6_5_hlc(
     KC_TAB  , KC_Q ,  KC_W   ,  KC_F  ,   KC_P ,   KC_B ,                                        KC_J,   KC_L ,  KC_U ,   KC_Y ,KC_SCLN, KC_BSPC,
     KC_ESC  , KC_A ,  KC_R   ,  KC_S  ,   KC_T ,   KC_G ,                                        KC_M,   KC_N ,  KC_E ,   KC_I ,  KC_O , KC_QUOT,
     KC_LSFT , KC_Z ,  KC_X   ,  KC_C  ,   KC_D ,   KC_V , KC_LOPT, SCREENSHOT,  FKEYS  , KC_NO  , KC_K,   KC_H ,KC_COMM, KC_DOT ,KC_SLSH, KC_ENT ,
                                KC_NO  , KC_LCTL, KC_LGUI, AEROSPACE, KC_SPC,     KC_NO  , KC_SPC , RAISE , LOWER  , KC_NO  ,
     KC_NO  , KC_NO,  KC_NO, KC_NO, KC_NO,                                                                KC_NO  , KC_NO, KC_NO, KC_NO, KC_NO
    ),

    [_LOWER] = LAYOUT_split_3x6_5_hlc(
      _______, _______, _______, _______, _______, _______,                                     _______, _______, _______, _______, KC_DEL , KC_BSPC,
      _______, _______, _______, _______, _______, _______,                                     KC_LEFT, KC_DOWN, KC_UP  , KC_RGHT, _______, _______,
      _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______,
                                 _______, _______, _______, _______, _______, _______, _______, _______, _______, _______,
     _______, _______,  _______, _______, _______,                                                       _______, _______, _______, _______, _______
    ),

    [_RAISE] = LAYOUT_split_3x6_5_hlc(
      KC_GRV , KC_EXLM,  KC_AT , KC_LBRC, KC_RBRC, _______,                                     _______,   KC_7 ,   KC_8 ,   KC_9 , KC_MINS, _______,
      _______, KC_HASH,  KC_DLR, KC_LPRN, KC_RPRN, KC_COLN,                                     _______,   KC_4 ,   KC_5 ,   KC_6 , KC_PLUS, KC_EQL ,
      _______, KC_PERC, KC_CIRC, KC_LCBR, KC_RCBR, _______, _______, _______, _______, _______,   KC_0 ,   KC_1 ,   KC_2 ,   KC_3 ,  KC_DOT, KC_BSLS,
                                 _______, _______, _______, _______, _______, _______, _______, _______, _______, _______,
     _______, _______,  _______, _______, _______,                                                       _______, _______, _______, _______, _______
    ),

    [_FUNCTION] = LAYOUT_split_3x6_5_hlc(
      _______,  KC_F11,  KC_F12,  KC_F13,  KC_F14,  KC_F15,                                     _______, _______, _______, _______, _______, _______,
      _______,  KC_F6 ,  KC_F7 ,  KC_F8 ,  KC_F9 ,  KC_F10,                                     RM_TOGG, RM_SATU, RM_HUEU, RM_VALU, RM_NEXT, _______,
      _______,  KC_F1 ,  KC_F2 ,  KC_F3 ,  KC_F4 ,  KC_F5 , _______, _______, _______, _______, _______, RM_SATD, RM_HUED, RM_VALD, RM_PREV, _______,
                                 _______, _______, _______, _______, _______, _______, _______, _______, _______, _______,
     _______, _______,  _______, _______, _______,                                                       _______, _______, _______, _______, _______
    ),
};

#if defined(ENCODER_MAP_ENABLE)
const uint16_t PROGMEM encoder_map[][NUM_ENCODERS][NUM_DIRECTIONS] = {
    [_DEFAULT]  = { ENCODER_CCW_CW(KC_VOLD, KC_VOLU),  ENCODER_CCW_CW(KC_VOLD, KC_VOLU),  ENCODER_CCW_CW(KC_VOLD, KC_VOLU),  ENCODER_CCW_CW(KC_VOLD, KC_VOLU)  },
    [_LOWER]    = { ENCODER_CCW_CW(KC_MPRV, KC_MNXT),  ENCODER_CCW_CW(KC_MPRV, KC_MNXT),  ENCODER_CCW_CW(KC_MPRV, KC_MNXT),  ENCODER_CCW_CW(KC_MPRV, KC_MNXT)  },
    [_RAISE]    = { ENCODER_CCW_CW(KC_VOLD, KC_VOLU),  ENCODER_CCW_CW(KC_VOLD, KC_VOLU),  ENCODER_CCW_CW(KC_VOLD, KC_VOLU),  ENCODER_CCW_CW(KC_VOLD, KC_VOLU)  },
    [_FUNCTION] = { ENCODER_CCW_CW(RM_PREV, RM_NEXT),  ENCODER_CCW_CW(RM_PREV, RM_NEXT),  ENCODER_CCW_CW(RM_PREV, RM_NEXT),  ENCODER_CCW_CW(RM_PREV, RM_NEXT)  },
};
#endif
