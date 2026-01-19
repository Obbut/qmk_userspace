/* Copyright 2024 @ Keychron (https://www.keychron.com)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include QMK_KEYBOARD_H
#include "keychron_common.h"

enum layers {
    MAC_BASE,
    WIN_BASE,
    MAC_FN,
    WIN_FN,
    COM_FN,
    _RAISE,  // Symbol layer (hold right space)
};

// Aerospace window manager modifier (Cmd+Ctrl+Opt)
#define AEROSPACE LCTL(LGUI(KC_RALT))

// Escape on tap, Aerospace modifiers on hold
#define ESC_AERO MT(MOD_LCTL | MOD_LGUI | MOD_RALT, KC_ESC)

// macOS screenshot (Cmd+Ctrl+Shift+4)
#define MAC_SCREENSHOT LGUI(LCTL(LSFT(KC_4)))

// clang-format off
const uint16_t PROGMEM keymaps[][MATRIX_ROWS][MATRIX_COLS] = {
    [MAC_BASE] = LAYOUT_ansi_66(
        MAC_SCREENSHOT,KC_1,    KC_2,     KC_3,     KC_4,     KC_5,     KC_6,     KC_7,     KC_8,     KC_9,     KC_0,     KC_MINS,  KC_BSPC,  KC_MPLY,
        KC_TAB,   KC_Q,     KC_W,     KC_E,     KC_R,     KC_T,     KC_Y,     KC_U,     KC_I,     KC_O,     KC_P,     KC_LBRC,  KC_RBRC,  KC_BSLS,
        ESC_AERO, KC_A,     KC_S,     KC_D,     KC_F,     KC_G,     KC_H,     KC_J,     KC_K,     KC_L,     KC_SCLN,  KC_QUOT,            KC_ENT,
        KC_LSFT,  KC_Z,     KC_X,     KC_C,     KC_V,     KC_B,     KC_N,     KC_M,     KC_COMM,  KC_DOT,   KC_SLSH,  KC_RSFT,  KC_UP,    KC_DEL,
        KC_LCTL,  XXXXXXX,  KC_LOPT,  KC_LCMD,       KC_SPC,             LT(_RAISE, KC_SPC),MO(MAC_FN),MO(COM_FN),KC_LEFT, KC_DOWN,  KC_RGHT),

    [WIN_BASE] = LAYOUT_ansi_66(
        KC_PSCR,  KC_1,     KC_2,     KC_3,     KC_4,     KC_5,     KC_6,     KC_7,     KC_8,     KC_9,     KC_0,     KC_MINS,  KC_BSPC,  KC_MPLY,
        KC_TAB,   KC_Q,     KC_W,     KC_E,     KC_R,     KC_T,     KC_Y,     KC_U,     KC_I,     KC_O,     KC_P,     KC_LBRC,  KC_RBRC,  KC_BSLS,
        KC_ESC,   KC_A,     KC_S,     KC_D,     KC_F,     KC_G,     KC_H,     KC_J,     KC_K,     KC_L,     KC_SCLN,  KC_QUOT,            KC_ENT,
        KC_LSFT,  KC_Z,     KC_X,     KC_C,     KC_V,     KC_B,     KC_N,     KC_M,     KC_COMM,  KC_DOT,   KC_SLSH,  KC_RSFT,  KC_UP,    KC_DEL,
        KC_LCTL,  KC_LGUI,  XXXXXXX,  KC_LALT,       KC_SPC,             LT(_RAISE, KC_SPC),MO(WIN_FN),MO(COM_FN),KC_LEFT, KC_DOWN,  KC_RGHT),

    [MAC_FN] = LAYOUT_ansi_66(
        RGB_TOG,  KC_BRID,  KC_BRIU,  KC_MCTRL, KC_LPAD,  RGB_VAD,  RGB_VAI,  KC_MPRV,  KC_MPLY,  KC_MNXT,  KC_MUTE,  KC_VOLD,  KC_EQL,   _______,
        QK_BOOT,  BT_HST1,  BT_HST2,  BT_HST3,  P2P4G,    _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,
        _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,            _______,
        _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,
        _______,  _______,  _______,  _______,       _______,            _______,      _______,  _______,  _______,  _______,  _______),

    [WIN_FN] = LAYOUT_ansi_66(
        RGB_TOG,  KC_BRID,  KC_BRIU,  KC_TASK,  KC_FILE,  RGB_VAD,  RGB_VAI,  KC_MPRV,  KC_MPLY,  KC_MNXT,  KC_MUTE,  KC_VOLD,  KC_EQL,   _______,
        QK_BOOT,  BT_HST1,  BT_HST2,  BT_HST3,  P2P4G,    _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,
        _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,            _______,
        _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,
        _______,  _______,  _______,  _______,       _______,            _______,      _______,  _______,  _______,  _______,  _______),

    [COM_FN] = LAYOUT_ansi_66(
        _______,  KC_F1,    KC_F2,    KC_F3,    KC_F4,    KC_F5,    KC_F6,    KC_F7,    KC_F8,    KC_F9,    KC_F10,   KC_F11,   KC_F12,   _______,
        _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,
        _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,            _______,
        _______,  _______,  _______,  _______,  _______,  BAT_LVL,  _______,  _______,  _______,  _______,  _______,  _______,  RGB_VAI,  _______,
        _______,  _______,  _______,  _______,       _______,            _______,      _______,  _______,  RGB_SPD,  RGB_VAD,  RGB_SPI),

    [_RAISE] = LAYOUT_ansi_66(
        _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,  _______,
        KC_GRV,   KC_EXLM,  KC_AT,    KC_LBRC,  KC_RBRC,  _______,  _______,  KC_7,     KC_8,     KC_9,     KC_MINS,  _______,  _______,  _______,
        _______,  _______,  KC_HASH,  KC_DLR,   KC_LPRN,  KC_RPRN,  _______,  KC_4,     KC_5,     KC_6,     KC_PLUS,  KC_EQL,             _______,
        _______,  _______,  KC_PERC,  KC_CIRC,  KC_LCBR,  KC_RCBR,  KC_0,     KC_1,     KC_2,     KC_3,     KC_DOT,   KC_BSLS,  _______,  _______,
        _______,  _______,  _______,  _______,       _______,            _______,      _______,  _______,  _______,  _______,  _______),
};
// clang-format on

#if defined(ENCODER_MAP_ENABLE)
const uint16_t PROGMEM encoder_map[][NUM_ENCODERS][NUM_DIRECTIONS] = {
    [MAC_BASE] = {ENCODER_CCW_CW(KC_VOLD, KC_VOLU), ENCODER_CCW_CW(KC_VOLD, KC_VOLU)},
    [WIN_BASE] = {ENCODER_CCW_CW(KC_VOLD, KC_VOLU), ENCODER_CCW_CW(KC_VOLD, KC_VOLU)},
    [MAC_FN]   = {ENCODER_CCW_CW(RGB_VAD, RGB_VAI), ENCODER_CCW_CW(RGB_VAD, RGB_VAI)},
    [WIN_FN]   = {ENCODER_CCW_CW(RGB_VAD, RGB_VAI), ENCODER_CCW_CW(RGB_VAD, RGB_VAI)},
    [COM_FN]   = {ENCODER_CCW_CW(RGB_VAD, RGB_VAI), ENCODER_CCW_CW(RGB_VAD, RGB_VAI)},
    [_RAISE]   = {ENCODER_CCW_CW(KC_VOLD, KC_VOLU), ENCODER_CCW_CW(KC_VOLD, KC_VOLU)},
};
#endif

bool process_record_user(uint16_t keycode, keyrecord_t *record) {
    if (!process_record_keychron_common(keycode, record)) {
        return false;
    }
    return true;
}

#if defined(RGB_MATRIX_ENABLE)
bool rgb_matrix_indicators_advanced_user(uint8_t led_min, uint8_t led_max) {
    uint8_t layer = get_highest_layer(layer_state);

    // Only show indicators on function and raise layers
    if (layer != MAC_FN && layer != WIN_FN && layer != COM_FN && layer != _RAISE) {
        return false;
    }

    // Turn off all LEDs first
    for (uint8_t i = led_min; i < led_max; i++) {
        rgb_matrix_set_color(i, RGB_OFF);
    }

    // Highlight keys based on what's mapped on the current layer
    for (uint8_t row = 0; row < MATRIX_ROWS; row++) {
        for (uint8_t col = 0; col < MATRIX_COLS; col++) {
            uint8_t led_index = g_led_config.matrix_co[row][col];
            if (led_index >= led_min && led_index < led_max && led_index != NO_LED) {
                keypos_t pos = {.row = row, .col = col};
                uint16_t keycode = keymap_key_to_keycode(layer, pos);

                if (layer == _RAISE) {
                    // Number keys (0-9): blue
                    if ((keycode >= KC_1 && keycode <= KC_9) || keycode == KC_0) {
                        rgb_matrix_set_color(led_index, 0, 0, 255);
                    }
                    // Symbol keys: yellow
                    else if (keycode == KC_GRV || keycode == KC_EXLM || keycode == KC_AT ||
                             keycode == KC_HASH || keycode == KC_DLR || keycode == KC_PERC ||
                             keycode == KC_CIRC || keycode == KC_LBRC || keycode == KC_RBRC ||
                             keycode == KC_LPRN || keycode == KC_RPRN || keycode == KC_LCBR ||
                             keycode == KC_RCBR || keycode == KC_MINS || keycode == KC_PLUS ||
                             keycode == KC_EQL || keycode == KC_DOT || keycode == KC_BSLS) {
                        rgb_matrix_set_color(led_index, 255, 255, 0);
                    }
                } else {
                    // F-keys: cyan
                    if (keycode >= KC_F1 && keycode <= KC_F12) {
                        rgb_matrix_set_color(led_index, 0, 220, 220);
                    }
                    // Boot key: red
                    else if (keycode == QK_BOOT) {
                        rgb_matrix_set_color(led_index, 255, 68, 68);
                    }
                    // Bluetooth/wireless keys: cyan
                    else if (keycode == BT_HST1 || keycode == BT_HST2 ||
                             keycode == BT_HST3 || keycode == P2P4G) {
                        rgb_matrix_set_color(led_index, 0, 220, 220);
                    }
                    // Battery level: blue
                    else if (keycode == BAT_LVL) {
                        rgb_matrix_set_color(led_index, 0, 0, 255);
                    }
                    // RGB controls increase: bright green
                    else if (keycode == RGB_TOG || keycode == RGB_VAI ||
                             keycode == RGB_SPI) {
                        rgb_matrix_set_color(led_index, 0, 255, 0);
                    }
                    // RGB controls decrease: dark green
                    else if (keycode == RGB_VAD || keycode == RGB_SPD) {
                        rgb_matrix_set_color(led_index, 0, 50, 0);
                    }
                }
            }
        }
    }
    return false;
}
#endif
