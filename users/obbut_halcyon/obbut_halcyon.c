// Shared code for Obbut's Halcyon keyboards (Kyria, Elora)
// SPDX-License-Identifier: GPL-2.0-or-later

#include "obbut_halcyon.h"

#if defined(RAW_ENABLE)
#    include "raw_hid.h"
#endif

// ============== KEYMAP COMPANION PROTOCOL ==============

#if defined(RAW_ENABLE)

#    define OBBUT_HID_MAGIC_0 'K'
#    define OBBUT_HID_MAGIC_1 'M'
#    define OBBUT_HID_MAGIC_2 'A'
#    define OBBUT_HID_MAGIC_3 'P'
#    define OBBUT_HID_PROTOCOL_VERSION 1
#    define OBBUT_HID_GET_STATE 1
#    define OBBUT_HID_STATE 2
#    define OBBUT_HID_REPORT_SIZE 32
#    define OBBUT_HID_CAPABILITY_LAYER_STATE (1UL << 0)
#    define OBBUT_HID_MINIMUM_SEND_INTERVAL 5

static bool     keymap_companion_connected       = false;
static bool     keymap_companion_state_is_dirty  = true;
static uint32_t keymap_companion_sequence         = 0;
static uint32_t keymap_companion_last_send         = 0;
static uint32_t keymap_companion_last_layer_state  = UINT32_MAX;
static uint32_t keymap_companion_last_default_layer_state = UINT32_MAX;

static uint8_t keymap_companion_keyboard_kind(void) {
#    if defined(KEYBOARD_splitkb_halcyon_kyria_rev4)
    return 1;
#    elif defined(KEYBOARD_splitkb_halcyon_elora_rev2)
    return 2;
#    else
    return 0;
#    endif
}

static void keymap_companion_write_u32(uint8_t *data, uint8_t offset, uint32_t value) {
    data[offset]     = (uint8_t)(value & 0xFF);
    data[offset + 1] = (uint8_t)((value >> 8) & 0xFF);
    data[offset + 2] = (uint8_t)((value >> 16) & 0xFF);
    data[offset + 3] = (uint8_t)((value >> 24) & 0xFF);
}

static bool keymap_companion_has_valid_header(const uint8_t *data, uint8_t length) {
    return length == OBBUT_HID_REPORT_SIZE && data[0] == OBBUT_HID_MAGIC_0 && data[1] == OBBUT_HID_MAGIC_1 && data[2] == OBBUT_HID_MAGIC_2 && data[3] == OBBUT_HID_MAGIC_3 && data[4] == OBBUT_HID_PROTOCOL_VERSION;
}

static void keymap_companion_send_state(void) {
    uint8_t  response[OBBUT_HID_REPORT_SIZE] = {0};
    uint32_t current_layer_state         = (uint32_t)layer_state;
    uint32_t current_default_layer_state = (uint32_t)default_layer_state;

    response[0] = OBBUT_HID_MAGIC_0;
    response[1] = OBBUT_HID_MAGIC_1;
    response[2] = OBBUT_HID_MAGIC_2;
    response[3] = OBBUT_HID_MAGIC_3;
    response[4] = OBBUT_HID_PROTOCOL_VERSION;
    response[5] = OBBUT_HID_STATE;
    response[6] = keymap_companion_keyboard_kind();
    response[7] = get_highest_layer(layer_state | default_layer_state);
    keymap_companion_write_u32(response, 8, current_layer_state);
    keymap_companion_write_u32(response, 12, current_default_layer_state);
    keymap_companion_write_u32(response, 16, ++keymap_companion_sequence);
    keymap_companion_write_u32(response, 20, OBBUT_HID_CAPABILITY_LAYER_STATE);

    raw_hid_send(response, OBBUT_HID_REPORT_SIZE);
    keymap_companion_last_send                = timer_read32();
    keymap_companion_last_layer_state         = current_layer_state;
    keymap_companion_last_default_layer_state = current_default_layer_state;
    keymap_companion_state_is_dirty           = false;
}

void obbut_raw_hid_receive(uint8_t *data, uint8_t length) {
    if (!is_keyboard_master() || !keymap_companion_has_valid_header(data, length)) {
        return;
    }

    if (data[5] == OBBUT_HID_GET_STATE) {
        keymap_companion_connected = true;
        keymap_companion_send_state();
    }
}

static void keymap_companion_housekeeping_task(void) {
    uint32_t current_layer_state         = (uint32_t)layer_state;
    uint32_t current_default_layer_state = (uint32_t)default_layer_state;

    if (!is_keyboard_master() || !keymap_companion_connected) {
        return;
    }

    if (current_layer_state != keymap_companion_last_layer_state || current_default_layer_state != keymap_companion_last_default_layer_state) {
        keymap_companion_state_is_dirty = true;
    }

    if (keymap_companion_state_is_dirty && timer_elapsed32(keymap_companion_last_send) >= OBBUT_HID_MINIMUM_SEND_INTERVAL) {
        keymap_companion_send_state();
    }
}

#endif

// ============== POINTING DEVICE SETTINGS ==============

#ifndef SCROLL_DIVISOR_H
#define SCROLL_DIVISOR_H 4.0
#endif
#ifndef SCROLL_DIVISOR_V
#define SCROLL_DIVISOR_V 4.0
#endif
#ifndef MOUSE_SENSITIVITY
#define MOUSE_SENSITIVITY 1.0
#endif

static float scroll_accumulated_h = 0;
static float scroll_accumulated_v = 0;
static float mouse_accumulated_x = 0;
static float mouse_accumulated_y = 0;

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

#if defined(RAW_ENABLE)
    keymap_companion_housekeeping_task();
#endif
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

    // Swap keys on Windows
    if (is_windows()) {
        switch (keycode) {
#if defined(KEYBOARD_splitkb_halcyon_elora_rev2)
            // Elora only: Heart key (MS_BTN1) toggles QWERTY layer
            case MS_BTN1:
                if (record->event.pressed) {
                    layer_invert(_QWERTY);
                }
                return false;
#endif
            // Volume: use consumer codes on Windows (KB_VOLUME codes don't work reliably)
            case KC_KB_VOLUME_UP:
                if (record->event.pressed) {
                    register_code(KC_VOLU);
                } else {
                    unregister_code(KC_VOLU);
                }
                return false;
            case KC_KB_VOLUME_DOWN:
                if (record->event.pressed) {
                    register_code(KC_VOLD);
                } else {
                    unregister_code(KC_VOLD);
                }
                return false;
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

layer_state_t obbut_layer_state_set(layer_state_t state) {
    // Reset preview mode when leaving Function layer
    if (get_highest_layer(state) != _FUNCTION) {
        rgb_preview_mode = false;
    }
#if defined(RAW_ENABLE)
    keymap_companion_state_is_dirty = true;
#endif
    return state;
}

// ============== POINTING DEVICE (TRACKPAD SCROLL) ==============

#ifdef POINTING_DEVICE_ENABLE
report_mouse_t pointing_device_task_user(report_mouse_t mouse_report) {
    // On Lower layer, convert mouse movement to scrolling
    if (get_highest_layer(layer_state) == _LOWER) {
        // Accumulate for smooth scrolling with fractional values
        scroll_accumulated_h += (float)mouse_report.x / SCROLL_DIVISOR_H;
        scroll_accumulated_v += (float)mouse_report.y / SCROLL_DIVISOR_V;

        // Convert to scroll values
        mouse_report.h = (int8_t)scroll_accumulated_h;
        mouse_report.v = -(int8_t)scroll_accumulated_v;  // Negative for natural scroll direction

        // Keep fractional remainder for next iteration
        scroll_accumulated_h -= (int8_t)scroll_accumulated_h;
        scroll_accumulated_v -= (int8_t)scroll_accumulated_v;

        // Clear mouse movement (cursor shouldn't move while scrolling)
        mouse_report.x = 0;
        mouse_report.y = 0;
    } else {
        // Apply mouse sensitivity scaling
        mouse_accumulated_x += (float)mouse_report.x * MOUSE_SENSITIVITY;
        mouse_accumulated_y += (float)mouse_report.y * MOUSE_SENSITIVITY;

        mouse_report.x = (mouse_xy_report_t)mouse_accumulated_x;
        mouse_report.y = (mouse_xy_report_t)mouse_accumulated_y;

        // Keep fractional remainder for smooth movement
        mouse_accumulated_x -= (mouse_xy_report_t)mouse_accumulated_x;
        mouse_accumulated_y -= (mouse_xy_report_t)mouse_accumulated_y;
    }
    return mouse_report;
}
#endif

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
                    // QWERTY toggle key: purple
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
    } else if (layer == _QWERTY) {
        // Keep normal RGB effect running, only override gaming-critical keys
        // (No "turn off all LEDs" step - let the effect show through)

        for (uint8_t row = 0; row < MATRIX_ROWS; row++) {
            for (uint8_t col = 0; col < MATRIX_COLS; col++) {
                uint8_t led_index = g_led_config.matrix_co[row][col];
                if (led_index >= led_min && led_index < led_max && led_index != NO_LED) {
                    keypos_t pos = {.row = row, .col = col};
                    uint16_t keycode = keymap_key_to_keycode(_QWERTY, pos);

                    // WASD keys + left thumb cluster: bright purple
                    if (keycode == KC_W || keycode == KC_A ||
                        keycode == KC_S || keycode == KC_D ||
                        keycode == KC_LCTL || keycode == KC_LALT ||
                        keycode == KC_SPC) {
                        rgb_matrix_set_color(led_index, 148, 0, 211);
                    }
                }
            }
        }
    }
    return false;
}
#endif
