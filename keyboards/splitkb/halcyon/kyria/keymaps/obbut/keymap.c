#include QMK_KEYBOARD_H
#include "transactions.h"
#include "os_detection.h"

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
     KC_LSFT , KC_Z ,  KC_X   ,  KC_C  ,   KC_D ,   KC_V , KC_LOPT, MS_BTN1 ,  FKEYS  , KC_NO  , KC_K,   KC_H ,KC_COMM, KC_DOT ,KC_SLSH, KC_ENT ,
                                SCREENSHOT, KC_LCTL, KC_LGUI, AEROSPACE, KC_SPC,     KC_NO  , KC_SPC , RAISE , LOWER  , KC_NO  ,
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
      QK_BOOT,  KC_F6 ,  KC_F7 ,  KC_F8 ,  KC_F9 ,  KC_F10,                                     RM_TOGG, RM_SATU, RM_HUEU, RM_VALU, RM_NEXT, QK_BOOT,
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

// Track if RGB controls were used on Function layer (to show actual RGB effect)
static bool rgb_preview_mode = false;

// Handler for receiving RGB preview mode sync from master
void rgb_preview_sync_handler(uint8_t in_buflen, const void* in_data, uint8_t out_buflen, void* out_data) {
    if (in_buflen == sizeof(rgb_preview_mode)) {
        memcpy(&rgb_preview_mode, in_data, sizeof(rgb_preview_mode));
    }
}

void keyboard_post_init_user(void) {
    // Register the sync handler for RGB preview mode
    transaction_register_rpc(USER_SYNC_RGB_PREVIEW, rgb_preview_sync_handler);
}

void housekeeping_task_user(void) {
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

// Check if we're running on Windows
static inline bool is_windows(void) {
    return detected_host_os() == OS_WINDOWS;
}

bool process_record_user(uint16_t keycode, keyrecord_t *record) {
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

layer_state_t layer_state_set_user(layer_state_t state) {
    // Reset preview mode when leaving Function layer
    if (get_highest_layer(state) != _FUNCTION) {
        rgb_preview_mode = false;
    }
    return state;
}

#if defined(RGB_MATRIX_ENABLE)
bool rgb_matrix_indicators_advanced_user(uint8_t led_min, uint8_t led_max) {
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
