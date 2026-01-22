// Shared code for Obbut's Halcyon keyboards (Kyria, Elora)
// SPDX-License-Identifier: GPL-2.0-or-later

#include "obbut_halcyon.h"

// ============== RGB PREVIEW MODE ==============
// Track if RGB controls were used on Function layer (to show actual RGB effect)

static bool rgb_preview_mode = false;

// Handler for receiving RGB preview mode sync from master
void rgb_preview_sync_handler(uint8_t in_buflen, const void* in_data, uint8_t out_buflen, void* out_data) {
    if (in_buflen == sizeof(rgb_preview_mode)) {
        memcpy(&rgb_preview_mode, in_data, sizeof(rgb_preview_mode));
    }
}

void obbut_keyboard_post_init(void) {
    // Register the sync handler for RGB preview mode
    transaction_register_rpc(USER_SYNC_RGB_PREVIEW, rgb_preview_sync_handler);
}

void obbut_housekeeping_task(void) {
    if (is_keyboard_master()) {
        static bool last_rgb_preview_mode = false;
        static uint32_t last_sync = 0;

        // Sync when state changes or every 500ms
        if (rgb_preview_mode != last_rgb_preview_mode || timer_elapsed32(last_sync) > 500) {
            if (transaction_rpc_send(USER_SYNC_RGB_PREVIEW, sizeof(rgb_preview_mode), &rgb_preview_mode)) {
                last_rgb_preview_mode = rgb_preview_mode;
                last_sync = timer_read32();
            }
        }
    }
}

// ============== OS DETECTION ==============

static inline bool is_windows(void) {
    return detected_host_os() == OS_WINDOWS;
}

// ============== KEY PROCESSING ==============

bool obbut_process_record(uint16_t keycode, keyrecord_t *record) {
    // When pressing RGB control keys on Function layer, enable preview mode
    if (record->event.pressed && get_highest_layer(layer_state) == _FUNCTION) {
        switch (keycode) {
            case RM_TOGG:
            case RM_NEXT:
            case RM_PREV:
            case RM_HUEU:
            case RM_HUED:
            case RM_SATU:
            case RM_SATD:
            case RM_VALU:
            case RM_VALD:
                rgb_preview_mode = true;
                break;
        }
    }

    // Swap Ctrl and Cmd on Windows
    if (is_windows()) {
        switch (keycode) {
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

layer_state_t obbut_layer_state_set(layer_state_t state) {
    // Reset preview mode when leaving Function layer
    if (get_highest_layer(state) != _FUNCTION) {
        rgb_preview_mode = false;
    }
    return state;
}

// ============== RGB MATRIX INDICATORS ==============

#if defined(RGB_MATRIX_ENABLE)
bool obbut_rgb_matrix_indicators(uint8_t led_min, uint8_t led_max) {
    uint8_t layer = get_highest_layer(layer_state);

    // Skip Function layer indicators if in preview mode
    if (layer == _FUNCTION && rgb_preview_mode) {
        return false;
    }

    if (layer == _LOWER) {
        // Turn off all LEDs first
        for (uint8_t i = led_min; i < led_max; i++) {
            rgb_matrix_set_color(i, RGB_OFF);
        }

        // Highlight movement keys on Lower layer
        for (uint8_t row = 0; row < MATRIX_ROWS; row++) {
            for (uint8_t col = 0; col < MATRIX_COLS; col++) {
                uint8_t led_index = g_led_config.matrix_co[row][col];
                if (led_index >= led_min && led_index < led_max && led_index != NO_LED) {
                    keypos_t pos = {.row = row, .col = col};
                    uint16_t keycode = keymap_key_to_keycode(_LOWER, pos);

                    // Arrow keys: magenta
                    if (keycode == KC_LEFT || keycode == KC_DOWN ||
                        keycode == KC_UP || keycode == KC_RGHT) {
                        rgb_matrix_set_color(led_index, 255, 0, 255);
                    }
                    // Delete/Backspace: orange
                    else if (keycode == KC_DEL || keycode == KC_BSPC) {
                        rgb_matrix_set_color(led_index, 255, 128, 0);
                    }
                }
            }
        }
    } else if (layer == _RAISE) {
        // Turn off all LEDs first
        for (uint8_t i = led_min; i < led_max; i++) {
            rgb_matrix_set_color(i, RGB_OFF);
        }

        // Highlight keys based on what's mapped on the Raise layer
        for (uint8_t row = 0; row < MATRIX_ROWS; row++) {
            for (uint8_t col = 0; col < MATRIX_COLS; col++) {
                uint8_t led_index = g_led_config.matrix_co[row][col];
                if (led_index >= led_min && led_index < led_max && led_index != NO_LED) {
                    keypos_t pos = {.row = row, .col = col};
                    uint16_t keycode = keymap_key_to_keycode(_RAISE, pos);

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
                }
            }
        }
    } else if (layer == _FUNCTION) {
        // Turn off all LEDs first
        for (uint8_t i = led_min; i < led_max; i++) {
            rgb_matrix_set_color(i, RGB_OFF);
        }

        // Determine which key to highlight based on OS (the "primary" modifier)
        // macOS: Command (KC_LGUI), Windows: Control (KC_LCTL)
        uint16_t os_indicator_key = is_windows() ? KC_LCTL : KC_LGUI;

        // Highlight keys based on what's mapped on the Function layer
        for (uint8_t row = 0; row < MATRIX_ROWS; row++) {
            for (uint8_t col = 0; col < MATRIX_COLS; col++) {
                uint8_t led_index = g_led_config.matrix_co[row][col];
                if (led_index >= led_min && led_index < led_max && led_index != NO_LED) {
                    keypos_t pos = {.row = row, .col = col};
                    uint16_t keycode = keymap_key_to_keycode(_FUNCTION, pos);
                    uint16_t default_keycode = keymap_key_to_keycode(_DEFAULT, pos);

                    // F-keys: cyan
                    if (keycode >= KC_F1 && keycode <= KC_F15) {
                        rgb_matrix_set_color(led_index, 0, 220, 220);
                    }
                    // RGB controls increase: bright green
                    else if (keycode == RM_TOGG || keycode == RM_NEXT ||
                             keycode == RM_HUEU || keycode == RM_SATU || keycode == RM_VALU) {
                        rgb_matrix_set_color(led_index, 0, 255, 0);
                    }
                    // RGB controls decrease: dark green
                    else if (keycode == RM_PREV || keycode == RM_HUED ||
                             keycode == RM_SATD || keycode == RM_VALD) {
                        rgb_matrix_set_color(led_index, 0, 50, 0);
                    }
                    // Boot keys: red
                    else if (keycode == QK_BOOT) {
                        rgb_matrix_set_color(led_index, 255, 68, 68);
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
