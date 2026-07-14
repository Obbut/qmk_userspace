// Shared code for Obbut's Halcyon keyboards (Kyria, Elora)
// SPDX-License-Identifier: GPL-2.0-or-later

#include "obbut_halcyon.h"

#if defined(RAW_ENABLE)
#    include "raw_hid.h"
#endif

// Track if RGB controls should show the actual base-layer effect on Function.
static bool rgb_preview_mode = false;

// ============== KEYMAP COMPANION PROTOCOL ==============

#if defined(RAW_ENABLE)

#    define OBBUT_HID_MAGIC_0 'K'
#    define OBBUT_HID_MAGIC_1 'M'
#    define OBBUT_HID_MAGIC_2 'A'
#    define OBBUT_HID_MAGIC_3 'P'
#    define OBBUT_HID_PROTOCOL_VERSION 3
#    define OBBUT_HID_GET_STATE 1
#    define OBBUT_HID_STATE 2
#    define OBBUT_HID_GET_KEYMAP_INFO 3
#    define OBBUT_HID_KEYMAP_INFO 4
#    define OBBUT_HID_GET_KEYMAP_CHUNK 5
#    define OBBUT_HID_KEYMAP_CHUNK 6
#    define OBBUT_HID_SET_RGB_SETTINGS 7
#    define OBBUT_HID_REPORT_SIZE 32
#    define OBBUT_HID_CAPABILITY_LAYER_STATE (1UL << 0)
#    define OBBUT_HID_CAPABILITY_KEYMAP_READ (1UL << 1)
#    define OBBUT_HID_CAPABILITY_RGB_SETTINGS (1UL << 2)
#    define OBBUT_HID_MINIMUM_SEND_INTERVAL 5
#    define OBBUT_HID_KEYMAP_ENTRY_SIZE 4
#    define OBBUT_HID_KEYMAP_CHUNK_OFFSET 12
#    define OBBUT_HID_KEYMAP_ENTRIES_PER_CHUNK ((OBBUT_HID_REPORT_SIZE - OBBUT_HID_KEYMAP_CHUNK_OFFSET) / OBBUT_HID_KEYMAP_ENTRY_SIZE)
#    define OBBUT_HID_ENCODER_COUNT 1
#    define OBBUT_HID_ENCODER_DIRECTION_COUNT 2

enum keymap_companion_semantic {
    OBBUT_HID_SEMANTIC_NONE,
    OBBUT_HID_SEMANTIC_SCREENSHOT,
    OBBUT_HID_SEMANTIC_AEROSPACE,
};

enum keymap_companion_style {
    OBBUT_HID_STYLE_STANDARD,
    OBBUT_HID_STYLE_PURPLE,
    OBBUT_HID_STYLE_MAGENTA,
    OBBUT_HID_STYLE_BLUE,
    OBBUT_HID_STYLE_YELLOW,
    OBBUT_HID_STYLE_CYAN,
    OBBUT_HID_STYLE_GREEN,
    OBBUT_HID_STYLE_DARK_GREEN,
    OBBUT_HID_STYLE_RED,
    OBBUT_HID_STYLE_ORANGE,
};

static bool     keymap_companion_connected                = false;
static bool     keymap_companion_state_is_dirty           = true;
static uint32_t keymap_companion_sequence                 = 0;
static uint32_t keymap_companion_last_send                = 0;
static uint32_t keymap_companion_last_layer_state         = UINT32_MAX;
static uint32_t keymap_companion_last_default_layer_state = UINT32_MAX;

#    if defined(RGB_MATRIX_ENABLE)

static uint8_t keymap_companion_last_rgb_enabled    = UINT8_MAX;
static uint8_t keymap_companion_last_rgb_effect     = UINT8_MAX;
static uint8_t keymap_companion_last_rgb_hue        = UINT8_MAX;
static uint8_t keymap_companion_last_rgb_saturation = UINT8_MAX;
static uint8_t keymap_companion_last_rgb_brightness = UINT8_MAX;
static uint8_t keymap_companion_last_rgb_speed      = UINT8_MAX;

// Stable companion-protocol IDs mapped to QMK's build-dependent effect enum.
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

#        define OBBUT_HID_RGB_EFFECT_COUNT (sizeof(keymap_companion_rgb_effects) / sizeof(keymap_companion_rgb_effects[0]))

static uint8_t keymap_companion_protocol_effect(uint8_t qmk_effect) {
    for (uint8_t index = 0; index < OBBUT_HID_RGB_EFFECT_COUNT; index++) {
        if (keymap_companion_rgb_effects[index] == qmk_effect) {
            return index + 1;
        }
    }
    return 0;
}

static uint8_t keymap_companion_qmk_effect(uint8_t protocol_effect) {
    if (protocol_effect == 0 || protocol_effect > OBBUT_HID_RGB_EFFECT_COUNT) {
        return RGB_MATRIX_NONE;
    }
    return keymap_companion_rgb_effects[protocol_effect - 1];
}

#    endif

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

static void keymap_companion_write_u16(uint8_t *data, uint8_t offset, uint16_t value) {
    data[offset]     = (uint8_t)(value & 0xFF);
    data[offset + 1] = (uint8_t)((value >> 8) & 0xFF);
}

static uint16_t keymap_companion_read_u16(const uint8_t *data, uint8_t offset) {
    return (uint16_t)data[offset] | ((uint16_t)data[offset + 1] << 8);
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

static uint16_t keymap_companion_entry_count(void) {
    return keymap_companion_matrix_entry_count() + (uint16_t)OBBUT_KEYMAP_LAYER_COUNT * OBBUT_HID_ENCODER_COUNT * OBBUT_HID_ENCODER_DIRECTION_COUNT;
}

static uint8_t keymap_companion_layer_at(uint16_t index) {
    uint16_t matrix_size = MATRIX_ROWS * MATRIX_COLS;
    uint16_t matrix_entry_count = keymap_companion_matrix_entry_count();
    if (index < matrix_entry_count) {
        return index / matrix_size;
    }
    return (index - matrix_entry_count) / (OBBUT_HID_ENCODER_COUNT * OBBUT_HID_ENCODER_DIRECTION_COUNT);
}

static uint16_t keymap_companion_keycode_at(uint16_t index) {
    uint16_t matrix_size        = MATRIX_ROWS * MATRIX_COLS;
    uint16_t matrix_entry_count = keymap_companion_matrix_entry_count();
    if (index >= matrix_entry_count) {
        uint16_t encoder_offset = index - matrix_entry_count;
        uint8_t  layer          = encoder_offset / (OBBUT_HID_ENCODER_COUNT * OBBUT_HID_ENCODER_DIRECTION_COUNT);
        uint8_t  direction      = encoder_offset % OBBUT_HID_ENCODER_DIRECTION_COUNT;
        return keymap_companion_encoder_keycode(layer, direction);
    }

    uint8_t  layer       = index / matrix_size;
    uint16_t position    = index % matrix_size;
    keypos_t key         = {
                .row = position / MATRIX_COLS,
                .col = position % MATRIX_COLS,
    };
    return keymap_key_to_keycode(layer, key);
}

static uint8_t keymap_companion_semantic_for_keycode(uint16_t keycode) {
    if (keycode == SCREENSHOT) {
        return OBBUT_HID_SEMANTIC_SCREENSHOT;
    }
    if (keycode == AEROSPACE) {
        return OBBUT_HID_SEMANTIC_AEROSPACE;
    }
    return OBBUT_HID_SEMANTIC_NONE;
}

static bool keymap_companion_is_raise_symbol(uint16_t keycode) {
    return keycode == KC_GRV || keycode == KC_EXLM || keycode == KC_AT || keycode == KC_HASH || keycode == KC_DLR || keycode == KC_PERC || keycode == KC_CIRC || keycode == KC_LBRC || keycode == KC_RBRC || keycode == KC_LPRN || keycode == KC_RPRN || keycode == KC_LCBR || keycode == KC_RCBR || keycode == KC_COLN || keycode == KC_MINS || keycode == KC_PLUS || keycode == KC_EQL || keycode == KC_DOT || keycode == KC_BSLS;
}

static uint8_t keymap_companion_style_for_keycode(uint8_t layer, uint16_t keycode) {
    switch (layer) {
        case _QWERTY:
            if (keycode == KC_W || keycode == KC_A || keycode == KC_S || keycode == KC_D || keycode == KC_LCTL || keycode == KC_LALT || keycode == KC_SPC) {
                return OBBUT_HID_STYLE_PURPLE;
            }
            break;
        case _LOWER:
            if (keycode == KC_LEFT || keycode == KC_DOWN || keycode == KC_UP || keycode == KC_RGHT) {
                return OBBUT_HID_STYLE_MAGENTA;
            }
            if (keycode == KC_DEL || keycode == KC_BSPC) {
                return OBBUT_HID_STYLE_ORANGE;
            }
            break;
        case _RAISE:
            if (keycode >= KC_1 && keycode <= KC_0) {
                return OBBUT_HID_STYLE_BLUE;
            }
            if (keymap_companion_is_raise_symbol(keycode)) {
                return OBBUT_HID_STYLE_YELLOW;
            }
            break;
        case _FUNCTION:
            if ((keycode >= KC_F1 && keycode <= KC_F12) || (keycode >= KC_F13 && keycode <= KC_F15)) {
                return OBBUT_HID_STYLE_CYAN;
            }
            if (keycode == RM_TOGG || keycode == RM_NEXT || keycode == RM_HUEU || keycode == RM_SATU || keycode == RM_VALU) {
                return OBBUT_HID_STYLE_GREEN;
            }
            if (keycode == RM_PREV || keycode == RM_HUED || keycode == RM_SATD || keycode == RM_VALD) {
                return OBBUT_HID_STYLE_DARK_GREEN;
            }
            if (keycode == QK_BOOT) {
                return OBBUT_HID_STYLE_RED;
            }
            if (keycode == TG_QWERTY) {
                return OBBUT_HID_STYLE_PURPLE;
            }
            break;
    }
    return OBBUT_HID_STYLE_STANDARD;
}

static uint32_t keymap_companion_fingerprint(void) {
    uint32_t hash = 2166136261UL;
#    define OBBUT_HID_FINGERPRINT_BYTE(value) \
        do {                                    \
            hash ^= (uint8_t)(value);           \
            hash *= 16777619UL;                 \
        } while (0)

    OBBUT_HID_FINGERPRINT_BYTE(keymap_companion_keyboard_kind());
    OBBUT_HID_FINGERPRINT_BYTE(OBBUT_KEYMAP_LAYER_COUNT);
    OBBUT_HID_FINGERPRINT_BYTE(MATRIX_ROWS);
    OBBUT_HID_FINGERPRINT_BYTE(MATRIX_COLS);
    OBBUT_HID_FINGERPRINT_BYTE(OBBUT_HID_ENCODER_COUNT);
    OBBUT_HID_FINGERPRINT_BYTE(OBBUT_HID_ENCODER_DIRECTION_COUNT);

    uint16_t entry_count = keymap_companion_entry_count();
    for (uint16_t index = 0; index < entry_count; index++) {
        uint16_t keycode = keymap_companion_keycode_at(index);
        uint8_t  layer   = keymap_companion_layer_at(index);
        OBBUT_HID_FINGERPRINT_BYTE(keycode);
        OBBUT_HID_FINGERPRINT_BYTE(keycode >> 8);
        OBBUT_HID_FINGERPRINT_BYTE(keymap_companion_semantic_for_keycode(keycode));
        OBBUT_HID_FINGERPRINT_BYTE(keymap_companion_style_for_keycode(layer, keycode));
    }

#    undef OBBUT_HID_FINGERPRINT_BYTE
    return hash;
}

static bool keymap_companion_has_valid_header(const uint8_t *data, uint8_t length) {
    return length == OBBUT_HID_REPORT_SIZE && data[0] == OBBUT_HID_MAGIC_0 && data[1] == OBBUT_HID_MAGIC_1 && data[2] == OBBUT_HID_MAGIC_2 && data[3] == OBBUT_HID_MAGIC_3 && data[4] == OBBUT_HID_PROTOCOL_VERSION;
}

static void keymap_companion_send_state(void) {
    uint8_t response[OBBUT_HID_REPORT_SIZE] = {0};
    uint32_t current_layer_state         = (uint32_t)layer_state;
    uint32_t current_default_layer_state = (uint32_t)default_layer_state;
    uint32_t capabilities                = OBBUT_HID_CAPABILITY_LAYER_STATE | OBBUT_HID_CAPABILITY_KEYMAP_READ;

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
#    if defined(RGB_MATRIX_ENABLE)
    hsv_t rgb_hsv = rgb_matrix_get_hsv();
    capabilities |= OBBUT_HID_CAPABILITY_RGB_SETTINGS;
    response[24] = keymap_companion_protocol_effect(rgb_matrix_get_mode());
    response[25] = rgb_hsv.h;
    response[26] = rgb_hsv.s;
    response[27] = rgb_hsv.v;
    response[28] = rgb_matrix_is_enabled();
    response[29] = rgb_matrix_get_speed();
    response[30] = OBBUT_HID_RGB_EFFECT_COUNT;
#    endif

    keymap_companion_write_u32(response, 20, capabilities);

    raw_hid_send(response, OBBUT_HID_REPORT_SIZE);
    keymap_companion_last_send                = timer_read32();
    keymap_companion_last_layer_state         = current_layer_state;
    keymap_companion_last_default_layer_state = current_default_layer_state;
#    if defined(RGB_MATRIX_ENABLE)
    keymap_companion_last_rgb_enabled          = rgb_matrix_is_enabled();
    keymap_companion_last_rgb_effect           = response[24];
    keymap_companion_last_rgb_hue              = response[25];
    keymap_companion_last_rgb_saturation       = response[26];
    keymap_companion_last_rgb_brightness       = response[27];
    keymap_companion_last_rgb_speed            = response[29];
#    endif
    keymap_companion_state_is_dirty           = false;
}

static void keymap_companion_send_keymap_info(void) {
    uint8_t response[OBBUT_HID_REPORT_SIZE] = {0};
    response[0]                             = OBBUT_HID_MAGIC_0;
    response[1]                             = OBBUT_HID_MAGIC_1;
    response[2]                             = OBBUT_HID_MAGIC_2;
    response[3]                             = OBBUT_HID_MAGIC_3;
    response[4]                             = OBBUT_HID_PROTOCOL_VERSION;
    response[5]                             = OBBUT_HID_KEYMAP_INFO;
    response[6]                             = keymap_companion_keyboard_kind();
    response[7]                             = OBBUT_KEYMAP_LAYER_COUNT;
    response[8]                             = MATRIX_ROWS;
    response[9]                             = MATRIX_COLS;
    response[10]                            = OBBUT_HID_KEYMAP_ENTRY_SIZE;
    response[11]                            = OBBUT_HID_KEYMAP_ENTRIES_PER_CHUNK;
    keymap_companion_write_u32(response, 12, keymap_companion_fingerprint());
    keymap_companion_write_u16(response, 16, keymap_companion_entry_count());
    response[18] = OBBUT_HID_ENCODER_COUNT;
    response[19] = OBBUT_HID_ENCODER_DIRECTION_COUNT;
    raw_hid_send(response, OBBUT_HID_REPORT_SIZE);
}

static void keymap_companion_send_keymap_chunk(uint16_t start_index) {
    uint8_t  response[OBBUT_HID_REPORT_SIZE] = {0};
    uint16_t entry_count                    = keymap_companion_entry_count();
    if (start_index >= entry_count) {
        return;
    }

    uint16_t remaining = entry_count - start_index;
    uint8_t  count     = remaining > OBBUT_HID_KEYMAP_ENTRIES_PER_CHUNK ? OBBUT_HID_KEYMAP_ENTRIES_PER_CHUNK : (uint8_t)remaining;

    response[0] = OBBUT_HID_MAGIC_0;
    response[1] = OBBUT_HID_MAGIC_1;
    response[2] = OBBUT_HID_MAGIC_2;
    response[3] = OBBUT_HID_MAGIC_3;
    response[4] = OBBUT_HID_PROTOCOL_VERSION;
    response[5] = OBBUT_HID_KEYMAP_CHUNK;
    response[6] = keymap_companion_keyboard_kind();
    response[7] = count;
    keymap_companion_write_u16(response, 8, start_index);
    keymap_companion_write_u16(response, 10, entry_count);

    for (uint8_t entry = 0; entry < count; entry++) {
        uint16_t index   = start_index + entry;
        uint16_t keycode = keymap_companion_keycode_at(index);
        uint8_t  layer   = keymap_companion_layer_at(index);
        uint8_t  offset  = OBBUT_HID_KEYMAP_CHUNK_OFFSET + entry * OBBUT_HID_KEYMAP_ENTRY_SIZE;
        keymap_companion_write_u16(response, offset, keycode);
        response[offset + 2] = keymap_companion_semantic_for_keycode(keycode);
        response[offset + 3] = keymap_companion_style_for_keycode(layer, keycode);
    }

    raw_hid_send(response, OBBUT_HID_REPORT_SIZE);
}

#    if defined(RGB_MATRIX_ENABLE)

static bool keymap_companion_apply_rgb_settings(const uint8_t *data) {
    uint8_t qmk_effect = keymap_companion_qmk_effect(data[7]);
    if (qmk_effect == RGB_MATRIX_NONE) {
        return false;
    }

    rgb_matrix_enable_noeeprom();
    rgb_matrix_mode_noeeprom(qmk_effect);
    rgb_matrix_sethsv_noeeprom(data[8], data[9], data[10]);
    rgb_matrix_set_speed_noeeprom(data[11]);
    if (data[6] == 0) {
        rgb_matrix_disable_noeeprom();
    }
    eeconfig_force_flush_rgb_matrix();
    rgb_preview_mode = get_highest_layer(layer_state) == _FUNCTION;
    return true;
}

#    endif

void obbut_raw_hid_receive(uint8_t *data, uint8_t length) {
    if (!is_keyboard_master() || !keymap_companion_has_valid_header(data, length)) {
        return;
    }

    switch (data[5]) {
        case OBBUT_HID_GET_STATE:
            keymap_companion_connected = true;
            keymap_companion_send_state();
            break;
        case OBBUT_HID_GET_KEYMAP_INFO:
            keymap_companion_connected = true;
            keymap_companion_send_keymap_info();
            break;
        case OBBUT_HID_GET_KEYMAP_CHUNK:
            keymap_companion_send_keymap_chunk(keymap_companion_read_u16(data, 6));
            break;
#    if defined(RGB_MATRIX_ENABLE)
        case OBBUT_HID_SET_RGB_SETTINGS:
            if (keymap_companion_apply_rgb_settings(data)) {
                keymap_companion_connected = true;
                keymap_companion_send_state();
            }
            break;
#    endif
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

#    if defined(RGB_MATRIX_ENABLE)
    hsv_t current_rgb_hsv    = rgb_matrix_get_hsv();
    uint8_t current_rgb_mode = keymap_companion_protocol_effect(rgb_matrix_get_mode());
    if (rgb_matrix_is_enabled() != keymap_companion_last_rgb_enabled || current_rgb_mode != keymap_companion_last_rgb_effect || current_rgb_hsv.h != keymap_companion_last_rgb_hue || current_rgb_hsv.s != keymap_companion_last_rgb_saturation || current_rgb_hsv.v != keymap_companion_last_rgb_brightness || rgb_matrix_get_speed() != keymap_companion_last_rgb_speed) {
        keymap_companion_state_is_dirty = true;
    }
#    endif

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
