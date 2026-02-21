// Planck EZ Glow keymap for Obbut
// Standalone keymap - Colemak-DH layout matching Kyria
// SPDX-License-Identifier: GPL-2.0-or-later

#include QMK_KEYBOARD_H
#include "os_detection.h"

// ============== LAYER DEFINITIONS ==============

enum layers {
    _DEFAULT = 0,
    _QWERTY,
    _LOWER,
    _RAISE,
    _FUNCTION,
};

#define LOWER      TL_LOWR
#define RAISE      TL_UPPR
#define FKEYS      MO(_FUNCTION)
#define TG_QWERTY  TG(_QWERTY)

// ============== CUSTOM KEYCODES ==============

// Aerospace window manager modifier (Cmd+Ctrl+Opt)
#define AEROSPACE LCTL(LGUI(KC_RALT))

// macOS screenshot (Cmd+Ctrl+Shift+4)
#define SCREENSHOT LGUI(LCTL(LSFT(KC_4)))

// ============== KEYMAPS ==============

// clang-format off
const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
    [_DEFAULT] = LAYOUT_planck_1x2uC(
        KC_TAB,     KC_Q,    KC_W,    KC_F,      KC_P,      KC_B,    KC_J,    KC_L,    KC_U,    KC_Y,    KC_SCLN, KC_BSPC,
        KC_ESC,     KC_A,    KC_R,    KC_S,      KC_T,      KC_G,    KC_M,    KC_N,    KC_E,    KC_I,    KC_O,    KC_QUOT,
        KC_LSFT,    KC_Z,    KC_X,    KC_C,      KC_D,      KC_V,    KC_K,    KC_H,    KC_COMM, KC_DOT,  KC_SLSH, KC_ENT,
        SCREENSHOT, KC_LCTL, KC_LALT, AEROSPACE, KC_LGUI,       KC_SPC,       RAISE,   LOWER,   FKEYS,   KC_RALT, KC_DEL
    ),

    [_QWERTY] = LAYOUT_planck_1x2uC(
        KC_TAB,  KC_Q,    KC_W,    KC_E,    KC_R,    KC_T,    KC_Y,    KC_U,    KC_I,    KC_O,    KC_P,    KC_BSPC,
        KC_ESC,  KC_A,    KC_S,    KC_D,    KC_F,    KC_G,    KC_H,    KC_J,    KC_K,    KC_L,    KC_SCLN, KC_QUOT,
        KC_LSFT, KC_Z,    KC_X,    KC_C,    KC_V,    KC_B,    KC_N,    KC_M,    KC_COMM, KC_DOT,  KC_SLSH, KC_ENT,
        KC_LCTL, KC_LALT, KC_SPC,  KC_SPC,  KC_SPC,      KC_SPC,      RAISE,   LOWER,   FKEYS,   _______, _______
    ),

    [_LOWER] = LAYOUT_planck_1x2uC(
        _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, KC_DEL,  KC_BSPC,
        _______, _______, _______, _______, _______, _______, KC_LEFT, KC_DOWN, KC_UP,   KC_RGHT, _______, _______,
        _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______, _______,
        _______, _______, _______, _______, _______,     _______,      _______, _______, _______, _______, _______
    ),

    [_RAISE] = LAYOUT_planck_1x2uC(
        KC_GRV,  KC_EXLM, KC_AT,   KC_LBRC, KC_RBRC, _______, KC_COLN, KC_7,    KC_8,    KC_9,    KC_MINS, _______,
        _______, KC_HASH, KC_DLR,  KC_LPRN, KC_RPRN, KC_COLN, _______, KC_4,    KC_5,    KC_6,    KC_PLUS, KC_EQL,
        _______, KC_PERC, KC_CIRC, KC_LCBR, KC_RCBR, _______, KC_0,    KC_1,    KC_2,    KC_3,    KC_DOT,  KC_BSLS,
        _______, _______, _______, _______, _______,     _______,      _______, _______, _______, _______, _______
    ),

    [_FUNCTION] = LAYOUT_planck_1x2uC(
        _______,    KC_F11,  KC_F12,  KC_F13,  KC_F14,  KC_F15,  _______, _______, _______, _______, _______, _______,
        QK_BOOT,    KC_F6,   KC_F7,   KC_F8,   KC_F9,   KC_F10,  RGB_TOG, RGB_SAI, RGB_HUI, RGB_VAI, RGB_MOD, QK_BOOT,
        _______,    KC_F1,   KC_F2,   KC_F3,   KC_F4,   KC_F5,   TG_QWERTY, RGB_SAD, RGB_HUD, RGB_VAD, RGB_RMOD, _______,
        _______,    _______, _______, _______, _______,     _______,      _______, _______, _______, _______, _______
    ),
};
// clang-format on

// ============== INIT ==============

void keyboard_post_init_user(void) {
    // Dim the layer indicator LEDs (level 1 out of 4)
    planck_ez_right_led_level(255 / 4);
    planck_ez_left_led_level(255 / 4);
    // Turn off both LEDs on boot (default layer has no indicators)
    planck_ez_left_led_off();
    planck_ez_right_led_off();
}

// ============== OS DETECTION ==============

static inline bool is_windows(void) {
    return detected_host_os() == OS_WINDOWS;
}

// ============== KEY PROCESSING ==============

bool process_record_user(uint16_t keycode, keyrecord_t *record) {
    if (is_windows()) {
        switch (keycode) {
            // Screenshot: send Print Screen instead of macOS shortcut
            case SCREENSHOT:
                if (record->event.pressed) {
                    register_code(KC_PSCR);
                } else {
                    unregister_code(KC_PSCR);
                }
                return false;
            // Swap Ctrl and Cmd
            case KC_LCTL:
                if (record->event.pressed) {
                    register_code(KC_LGUI);
                } else {
                    unregister_code(KC_LGUI);
                }
                return false;
            case KC_LGUI:
                if (record->event.pressed) {
                    register_code(KC_LCTL);
                } else {
                    unregister_code(KC_LCTL);
                }
                return false;
        }
    }

    return true;
}

// ============== RGB MATRIX INDICATORS ==============

#if defined(RGB_MATRIX_ENABLE)
bool rgb_matrix_indicators_advanced_user(uint8_t led_min, uint8_t led_max) {
    uint8_t layer = get_highest_layer(layer_state);

    if (layer == _DEFAULT) {
        return false;
    }

    if (layer == _QWERTY) {
        // Overlay WASD + gaming keys with purple on normal RGB effect
        for (uint8_t row = 0; row < MATRIX_ROWS; row++) {
            for (uint8_t col = 0; col < MATRIX_COLS; col++) {
                uint8_t led_index = g_led_config.matrix_co[row][col];
                if (led_index >= led_min && led_index < led_max && led_index != NO_LED) {
                    keypos_t pos = {.row = row, .col = col};
                    uint16_t keycode = keymap_key_to_keycode(_QWERTY, pos);

                    if (keycode == KC_W || keycode == KC_A ||
                        keycode == KC_S || keycode == KC_D ||
                        keycode == KC_LCTL || keycode == KC_LALT ||
                        keycode == KC_SPC) {
                        rgb_matrix_set_color(led_index, 148, 0, 211);
                    }
                }
            }
        }
        return false;
    }

    // Turn off all LEDs first for indicator layers
    for (uint8_t i = led_min; i < led_max; i++) {
        rgb_matrix_set_color(i, RGB_OFF);
    }

    for (uint8_t row = 0; row < MATRIX_ROWS; row++) {
        for (uint8_t col = 0; col < MATRIX_COLS; col++) {
            uint8_t led_index = g_led_config.matrix_co[row][col];
            if (led_index >= led_min && led_index < led_max && led_index != NO_LED) {
                keypos_t pos = {.row = row, .col = col};
                uint16_t keycode = keymap_key_to_keycode(layer, pos);

                if (layer == _LOWER) {
                    // Arrow keys: magenta
                    if (keycode == KC_LEFT || keycode == KC_DOWN ||
                        keycode == KC_UP || keycode == KC_RGHT) {
                        rgb_matrix_set_color(led_index, 255, 0, 255);
                    }
                    // Delete/Backspace: orange
                    else if (keycode == KC_DEL || keycode == KC_BSPC) {
                        rgb_matrix_set_color(led_index, 255, 128, 0);
                    }
                } else if (layer == _RAISE) {
                    // Number keys: blue
                    if (keycode >= KC_1 && keycode <= KC_0) {
                        rgb_matrix_set_color(led_index, 0, 0, 255);
                    }
                    // Symbol keys: yellow
                    else if (keycode == KC_GRV || keycode == KC_EXLM || keycode == KC_AT ||
                             keycode == KC_HASH || keycode == KC_DLR || keycode == KC_PERC ||
                             keycode == KC_CIRC || keycode == KC_LBRC || keycode == KC_RBRC ||
                             keycode == KC_LPRN || keycode == KC_RPRN || keycode == KC_LCBR ||
                             keycode == KC_RCBR || keycode == KC_COLN || keycode == KC_MINS ||
                             keycode == KC_PLUS || keycode == KC_EQL || keycode == KC_DOT ||
                             keycode == KC_BSLS) {
                        rgb_matrix_set_color(led_index, 255, 255, 0);
                    }
                } else if (layer == _FUNCTION) {
                    uint16_t default_keycode = keymap_key_to_keycode(_DEFAULT, pos);
                    uint16_t os_indicator_key = is_windows() ? KC_LCTL : KC_LGUI;

                    // F-keys: cyan
                    if (keycode >= KC_F1 && keycode <= KC_F15) {
                        rgb_matrix_set_color(led_index, 0, 220, 220);
                    }
                    // RGB controls increase: bright green
                    else if (keycode == RGB_TOG || keycode == RGB_MOD ||
                             keycode == RGB_HUI || keycode == RGB_SAI || keycode == RGB_VAI) {
                        rgb_matrix_set_color(led_index, 0, 255, 0);
                    }
                    // RGB controls decrease: dark green
                    else if (keycode == RGB_RMOD || keycode == RGB_HUD ||
                             keycode == RGB_SAD || keycode == RGB_VAD) {
                        rgb_matrix_set_color(led_index, 0, 50, 0);
                    }
                    // Boot keys: red
                    else if (keycode == QK_BOOT) {
                        rgb_matrix_set_color(led_index, 255, 68, 68);
                    }
                    // QWERTY toggle: purple
                    else if (keycode == TG_QWERTY) {
                        rgb_matrix_set_color(led_index, 148, 0, 211);
                    }
                    // OS indicator: white on primary modifier key
                    else if (default_keycode == os_indicator_key) {
                        rgb_matrix_set_color(led_index, 255, 255, 255);
                    }
                }
            }
        }
    }
    return false;
}
#endif
