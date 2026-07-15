// Static QMK ABI shim. The real keymap is compiled from Swift.
// SPDX-License-Identifier: GPL-2.0-or-later

#include QMK_KEYBOARD_H
#include "keymap_protocol_bridge.h"

const uint16_t PROGMEM keymaps[1][MATRIX_ROWS][MATRIX_COLS] = {{{KC_NO}}};

#if defined(ENCODER_MAP_ENABLE)
const uint16_t PROGMEM encoder_map[1][NUM_ENCODERS][NUM_DIRECTIONS] = {{{KC_NO}}};
#endif

uint16_t keymap_key_to_keycode(uint8_t layer, keypos_t key) {
#if defined(ENCODER_MAP_ENABLE)
    if (key.row == KEYLOC_ENCODER_CW && key.col < NUM_ENCODERS) {
        return qmk_swift_encoder_keycode_at(layer, key.col, 1);
    }
    if (key.row == KEYLOC_ENCODER_CCW && key.col < NUM_ENCODERS) {
        return qmk_swift_encoder_keycode_at(layer, key.col, 0);
    }
#endif
    return qmk_swift_keycode_at(layer, key.row, key.col);
}
