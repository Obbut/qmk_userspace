// Elora Rev2 keymap for Obbut
// Uses shared code from users/obbut_halcyon/
// SPDX-License-Identifier: GPL-2.0-or-later

#include "obbut_halcyon.h"

// clang-format off
const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
    [_DEFAULT] = LAYOUT_wrapper(
        DEFAULT_NUM_L,                                             DEFAULT_NUM_R,
        DEFAULT_L1,                                                DEFAULT_R1,
        DEFAULT_L2,                                                DEFAULT_R2,
        DEFAULT_L3, KC_LOPT, MS_BTN1,          FKEYS,   KC_NO,     DEFAULT_R3,
                    DEFAULT_THUMB_L,                               DEFAULT_THUMB_R,
        DEFAULT_MODULE_L,                                          DEFAULT_MODULE_R
    ),

    [_QWERTY] = LAYOUT_wrapper(
        QWERTY_NUM_L,                                              QWERTY_NUM_R,
        QWERTY_L1,                                                 QWERTY_R1,
        QWERTY_L2,                                                 QWERTY_R2,
        QWERTY_L3,  KC_LOPT, MS_BTN1,          FKEYS,   KC_NO,     QWERTY_R3,
                    QWERTY_THUMB_L,                                QWERTY_THUMB_R,
        QWERTY_MODULE_L,                                           QWERTY_MODULE_R
    ),

    [_LOWER] = LAYOUT_wrapper(
        LOWER_NUM_L,                                               LOWER_NUM_R,
        LOWER_L1,                                                  LOWER_R1,
        LOWER_L2,                                                  LOWER_R2,
        LOWER_L3,   _______, _______,          _______, _______,   LOWER_R3,
                    LOWER_THUMB_L,                                 LOWER_THUMB_R,
        LOWER_MODULE_L,                                            LOWER_MODULE_R
    ),

    [_RAISE] = LAYOUT_wrapper(
        RAISE_NUM_L,                                               RAISE_NUM_R,
        RAISE_L1,                                                  RAISE_R1,
        RAISE_L2,                                                  RAISE_R2,
        RAISE_L3,   _______, _______,          _______, _______,   RAISE_R3,
                    RAISE_THUMB_L,                                 RAISE_THUMB_R,
        RAISE_MODULE_L,                                            RAISE_MODULE_R
    ),

    [_FUNCTION] = LAYOUT_wrapper(
        FUNC_NUM_L,                                                FUNC_NUM_R,
        FUNC_L1,                                                   FUNC_R1,
        FUNC_L2,                                                   FUNC_R2,
        FUNC_L3,    _______, TG_QWERTY,        _______, _______,   FUNC_R3,
                    FUNC_THUMB_L,                                  FUNC_THUMB_R,
        FUNC_MODULE_L,                                             FUNC_MODULE_R
    ),
};
// clang-format on

#if defined(ENCODER_MAP_ENABLE)
const uint16_t PROGMEM encoder_map[][NUM_ENCODERS][NUM_DIRECTIONS] = {
    [_DEFAULT]  = { ENCODER_MAP_DEFAULT,  ENCODER_MAP_DEFAULT,  ENCODER_MAP_DEFAULT,  ENCODER_MAP_DEFAULT  },
    [_QWERTY]   = { ENCODER_MAP_QWERTY,   ENCODER_MAP_QWERTY,   ENCODER_MAP_QWERTY,   ENCODER_MAP_QWERTY   },
    [_LOWER]    = { ENCODER_MAP_LOWER,    ENCODER_MAP_LOWER,    ENCODER_MAP_LOWER,    ENCODER_MAP_LOWER    },
    [_RAISE]    = { ENCODER_MAP_RAISE,    ENCODER_MAP_RAISE,    ENCODER_MAP_RAISE,    ENCODER_MAP_RAISE    },
    [_FUNCTION] = { ENCODER_MAP_FUNCTION, ENCODER_MAP_FUNCTION, ENCODER_MAP_FUNCTION, ENCODER_MAP_FUNCTION },
};
#endif

// ============== QMK CALLBACKS ==============
// Delegate to shared functions

void keyboard_post_init_user(void) {
    obbut_keyboard_post_init();
}

void housekeeping_task_user(void) {
    obbut_housekeeping_task();
}

bool process_record_user(uint16_t keycode, keyrecord_t *record) {
    return obbut_process_record(keycode, record);
}

layer_state_t layer_state_set_user(layer_state_t state) {
    return obbut_layer_state_set(state);
}

#if defined(RGB_MATRIX_ENABLE)
bool rgb_matrix_indicators_advanced_user(uint8_t led_min, uint8_t led_max) {
    return obbut_rgb_matrix_indicators(led_min, led_max);
}
#endif
