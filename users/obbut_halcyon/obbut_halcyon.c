// Shared code for Obbut's Halcyon keyboards (Kyria, Elora)
// SPDX-License-Identifier: GPL-2.0-or-later

#include "obbut_halcyon.h"

#if defined(RAW_ENABLE)
#    include "keymap_protocol_bridge.h"
#    include "raw_hid.h"
#endif

// Track if RGB controls should show the actual base-layer effect on Function.
static bool rgb_preview_mode = false;

// ============== KEYMAP COMPANION PROTOCOL ==============

#if defined(RAW_ENABLE)

#    define KEYMAP_COMPANION_ENCODER_COUNT 1

#    if defined(RGB_MATRIX_ENABLE)

// QMK's build-dependent effects ordered to match Swift's stable identifiers.
static const uint8_t keymap_companion_rgb_effects[] = {
    RGB_MATRIX_SOLID_COLOR,
    RGB_MATRIX_ALPHAS_MODS,
    RGB_MATRIX_GRADIENT_UP_DOWN,
    RGB_MATRIX_GRADIENT_LEFT_RIGHT,
    RGB_MATRIX_BREATHING,
    RGB_MATRIX_BAND_SAT,
    RGB_MATRIX_BAND_VAL,
    RGB_MATRIX_BAND_PINWHEEL_SAT,
    RGB_MATRIX_BAND_PINWHEEL_VAL,
    RGB_MATRIX_BAND_SPIRAL_SAT,
    RGB_MATRIX_BAND_SPIRAL_VAL,
    RGB_MATRIX_CYCLE_ALL,
    RGB_MATRIX_CYCLE_LEFT_RIGHT,
    RGB_MATRIX_CYCLE_UP_DOWN,
    RGB_MATRIX_RAINBOW_MOVING_CHEVRON,
    RGB_MATRIX_CYCLE_OUT_IN,
    RGB_MATRIX_CYCLE_OUT_IN_DUAL,
    RGB_MATRIX_CYCLE_PINWHEEL,
    RGB_MATRIX_CYCLE_SPIRAL,
    RGB_MATRIX_DUAL_BEACON,
    RGB_MATRIX_RAINBOW_BEACON,
    RGB_MATRIX_RAINBOW_PINWHEELS,
    RGB_MATRIX_RAINDROPS,
    RGB_MATRIX_JELLYBEAN_RAINDROPS,
    RGB_MATRIX_HUE_BREATHING,
    RGB_MATRIX_HUE_PENDULUM,
    RGB_MATRIX_HUE_WAVE,
    RGB_MATRIX_PIXEL_RAIN,
    RGB_MATRIX_PIXEL_FLOW,
    RGB_MATRIX_PIXEL_FRACTAL,
};

#        define KEYMAP_COMPANION_QMK_RGB_EFFECT_COUNT (sizeof(keymap_companion_rgb_effects) / sizeof(keymap_companion_rgb_effects[0]))

static uint8_t keymap_companion_rgb_effect_index(uint8_t qmk_effect) {
    for (uint8_t index = 0; index < KEYMAP_COMPANION_QMK_RGB_EFFECT_COUNT; index++) {
        if (keymap_companion_rgb_effects[index] == qmk_effect) {
            return index;
        }
    }
    return UINT8_MAX;
}

static uint8_t keymap_companion_qmk_effect(uint8_t effect_index) {
    if (effect_index < KEYMAP_COMPANION_QMK_RGB_EFFECT_COUNT) {
        return keymap_companion_rgb_effects[effect_index];
    }
    return RGB_MATRIX_NONE;
}

#    endif

static uint8_t keymap_companion_platform_keyboard(void) {
#    if defined(KEYBOARD_splitkb_halcyon_kyria_rev4)
    return KEYMAP_PROTOCOL_PLATFORM_KEYBOARD_KYRIA;
#    elif defined(KEYBOARD_splitkb_halcyon_elora_rev2)
    return KEYMAP_PROTOCOL_PLATFORM_KEYBOARD_ELORA;
#    else
#        error "The keymap protocol requires a supported Halcyon keyboard"
#    endif
}

static uint16_t keymap_companion_matrix_entry_count(void) {
    return (uint16_t)OBBUT_KEYMAP_LAYER_COUNT * MATRIX_ROWS * MATRIX_COLS;
}

static uint16_t keymap_companion_encoder_keycode(uint8_t layer, uint8_t direction) {
    bool clockwise = direction == 1;
    switch (layer) {
        case _DEFAULT:
            return clockwise ? ENCODER_DEFAULT_CW : ENCODER_DEFAULT_CCW;
        case _QWERTY:
            return clockwise ? ENCODER_QWERTY_CW : ENCODER_QWERTY_CCW;
        case _LOWER:
            return clockwise ? ENCODER_LOWER_CW : ENCODER_LOWER_CCW;
        case _RAISE:
            return clockwise ? ENCODER_RAISE_CW : ENCODER_RAISE_CCW;
        case _FUNCTION:
            return clockwise ? ENCODER_FUNCTION_CW : ENCODER_FUNCTION_CCW;
        default:
            return KC_NO;
    }
}

static uint8_t keymap_companion_layer_at(uint16_t index) {
    uint16_t matrix_size        = MATRIX_ROWS * MATRIX_COLS;
    uint16_t matrix_entry_count = keymap_companion_matrix_entry_count();
    if (index < matrix_entry_count) {
        return index / matrix_size;
    }
    return (index - matrix_entry_count) / (KEYMAP_COMPANION_ENCODER_COUNT * 2);
}

static uint16_t keymap_companion_keycode_at(uint16_t index) {
    uint16_t matrix_size        = MATRIX_ROWS * MATRIX_COLS;
    uint16_t matrix_entry_count = keymap_companion_matrix_entry_count();
    if (index >= matrix_entry_count) {
        uint16_t encoder_offset = index - matrix_entry_count;
        uint8_t  layer          = encoder_offset / (KEYMAP_COMPANION_ENCODER_COUNT * 2);
        uint8_t  direction      = encoder_offset % 2;
        return keymap_companion_encoder_keycode(layer, direction);
    }

    uint8_t  layer    = index / matrix_size;
    uint16_t position = index % matrix_size;
    keypos_t key      = {
             .row = position / MATRIX_COLS,
             .col = position % MATRIX_COLS,
    };
    return keymap_key_to_keycode(layer, key);
}

static uint8_t keymap_companion_semantic_for_keycode(uint16_t keycode) {
    if (keycode == SCREENSHOT) {
        return KEYMAP_PROTOCOL_PLATFORM_SEMANTIC_SCREENSHOT;
    }
    if (keycode == AEROSPACE) {
        return KEYMAP_PROTOCOL_PLATFORM_SEMANTIC_AEROSPACE;
    }
    return KEYMAP_PROTOCOL_PLATFORM_SEMANTIC_NONE;
}

static bool keymap_companion_is_raise_symbol(uint16_t keycode) {
    return keycode == KC_GRV || keycode == KC_EXLM || keycode == KC_AT || keycode == KC_HASH || keycode == KC_DLR || keycode == KC_PERC || keycode == KC_CIRC || keycode == KC_LBRC || keycode == KC_RBRC || keycode == KC_LPRN || keycode == KC_RPRN || keycode == KC_LCBR || keycode == KC_RCBR || keycode == KC_COLN || keycode == KC_MINS || keycode == KC_PLUS || keycode == KC_EQL || keycode == KC_DOT || keycode == KC_BSLS;
}

static uint8_t keymap_companion_style_for_keycode(uint8_t layer, uint16_t keycode) {
    switch (layer) {
        case _QWERTY:
            if (keycode == KC_W || keycode == KC_A || keycode == KC_S || keycode == KC_D || keycode == KC_LCTL || keycode == KC_LALT || keycode == KC_SPC) {
                return KEYMAP_PROTOCOL_PLATFORM_STYLE_PURPLE;
            }
            break;
        case _LOWER:
            if (keycode == KC_LEFT || keycode == KC_DOWN || keycode == KC_UP || keycode == KC_RGHT) {
                return KEYMAP_PROTOCOL_PLATFORM_STYLE_MAGENTA;
            }
            if (keycode == KC_DEL || keycode == KC_BSPC) {
                return KEYMAP_PROTOCOL_PLATFORM_STYLE_ORANGE;
            }
            break;
        case _RAISE:
            if (keycode >= KC_1 && keycode <= KC_0) {
                return KEYMAP_PROTOCOL_PLATFORM_STYLE_BLUE;
            }
            if (keymap_companion_is_raise_symbol(keycode)) {
                return KEYMAP_PROTOCOL_PLATFORM_STYLE_YELLOW;
            }
            break;
        case _FUNCTION:
            if ((keycode >= KC_F1 && keycode <= KC_F12) || (keycode >= KC_F13 && keycode <= KC_F15)) {
                return KEYMAP_PROTOCOL_PLATFORM_STYLE_CYAN;
            }
            if (keycode == RM_TOGG || keycode == RM_NEXT || keycode == RM_HUEU || keycode == RM_SATU || keycode == RM_VALU) {
                return KEYMAP_PROTOCOL_PLATFORM_STYLE_GREEN;
            }
            if (keycode == RM_PREV || keycode == RM_HUED || keycode == RM_SATD || keycode == RM_VALD) {
                return KEYMAP_PROTOCOL_PLATFORM_STYLE_DARK_GREEN;
            }
            if (keycode == QK_BOOT) {
                return KEYMAP_PROTOCOL_PLATFORM_STYLE_RED;
            }
            if (keycode == TG_QWERTY) {
                return KEYMAP_PROTOCOL_PLATFORM_STYLE_PURPLE;
            }
            break;
    }
    return KEYMAP_PROTOCOL_PLATFORM_STYLE_STANDARD;
}

keymap_protocol_platform_snapshot_t keymap_protocol_platform_get_snapshot(void) {
    keymap_protocol_platform_snapshot_t snapshot = {
        .timestamp                = timer_read32(),
        .layer_state_mask         = (uint32_t)layer_state,
        .default_layer_state_mask = (uint32_t)default_layer_state,
        .keyboard                 = keymap_companion_platform_keyboard(),
        .highest_active_layer     = get_highest_layer(layer_state | default_layer_state),
        .layer_count              = OBBUT_KEYMAP_LAYER_COUNT,
        .matrix_row_count         = MATRIX_ROWS,
        .matrix_column_count      = MATRIX_COLS,
        .encoder_count            = KEYMAP_COMPANION_ENCODER_COUNT,
        .rgb_effect_index         = UINT8_MAX,
    };

#    if defined(RGB_MATRIX_ENABLE)
    hsv_t rgb_hsv                  = rgb_matrix_get_hsv();
    snapshot.includes_rgb_settings = 1;
    snapshot.rgb_effect_index       = keymap_companion_rgb_effect_index(rgb_matrix_get_mode());
    snapshot.rgb_hue                = rgb_hsv.h;
    snapshot.rgb_saturation         = rgb_hsv.s;
    snapshot.rgb_brightness         = rgb_hsv.v;
    snapshot.is_rgb_enabled         = rgb_matrix_is_enabled();
    snapshot.rgb_speed              = rgb_matrix_get_speed();
#    endif

    return snapshot;
}

keymap_protocol_platform_entry_t keymap_protocol_platform_get_entry(uint16_t index) {
    uint16_t keycode = keymap_companion_keycode_at(index);
    uint8_t  layer   = keymap_companion_layer_at(index);
    keymap_protocol_platform_entry_t entry = {
        .keycode       = keycode,
        .semantic_role = keymap_companion_semantic_for_keycode(keycode),
        .style_role    = keymap_companion_style_for_keycode(layer, keycode),
    };
    return entry;
}

void keymap_protocol_platform_send(uint8_t *data, uint8_t length) {
    raw_hid_send(data, length);
}

uint8_t keymap_protocol_platform_apply_rgb(uint8_t effect_index, uint8_t hue, uint8_t saturation, uint8_t brightness, uint8_t is_enabled, uint8_t speed) {
#    if defined(RGB_MATRIX_ENABLE)
    uint8_t qmk_effect = keymap_companion_qmk_effect(effect_index);
    if (qmk_effect == RGB_MATRIX_NONE) {
        return 0;
    }

    rgb_matrix_enable_noeeprom();
    rgb_matrix_mode_noeeprom(qmk_effect);
    rgb_matrix_sethsv_noeeprom(hue, saturation, brightness);
    rgb_matrix_set_speed_noeeprom(speed);
    if (!is_enabled) {
        rgb_matrix_disable_noeeprom();
    }
    eeconfig_force_flush_rgb_matrix();
    rgb_preview_mode = get_highest_layer(layer_state) == _FUNCTION;
    return 1;
#    else
    (void)effect_index;
    (void)hue;
    (void)saturation;
    (void)brightness;
    (void)is_enabled;
    (void)speed;
    return 0;
#    endif
}

void obbut_raw_hid_receive(uint8_t *data, uint8_t length) {
    if (is_keyboard_master()) {
        keymap_protocol_receive(data, length);
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
    if (is_keyboard_master()) {
        keymap_protocol_housekeeping();
    }
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
