// QMK services consumed by the Embedded Swift protocol-v4 runtime.
// SPDX-License-Identifier: GPL-2.0-or-later

#include QMK_KEYBOARD_H
#include "keymap_protocol_bridge.h"
#include "raw_hid.h"

__attribute__((weak)) void obbut_keymap_rgb_settings_applied(void) {}

#if defined(RGB_MATRIX_ENABLE)
// QMK's effect enum is build-dependent. Protocol v4 carries stable IDs and
// this table contains only the effects enabled by the selected keyboard fork.
typedef struct {
    uint8_t protocol_effect;
    uint8_t qmk_effect;
} obbut_protocol_rgb_effect_t;

static const obbut_protocol_rgb_effect_t obbut_protocol_rgb_effects[] = {
#    if defined(ENABLE_RGB_MATRIX_SOLID_COLOR)
    {1, RGB_MATRIX_SOLID_COLOR},
#    endif
#    if defined(ENABLE_RGB_MATRIX_ALPHAS_MODS)
    {2, RGB_MATRIX_ALPHAS_MODS},
#    endif
#    if defined(ENABLE_RGB_MATRIX_GRADIENT_UP_DOWN)
    {3, RGB_MATRIX_GRADIENT_UP_DOWN},
#    endif
#    if defined(ENABLE_RGB_MATRIX_GRADIENT_LEFT_RIGHT)
    {4, RGB_MATRIX_GRADIENT_LEFT_RIGHT},
#    endif
#    if defined(ENABLE_RGB_MATRIX_BREATHING)
    {5, RGB_MATRIX_BREATHING},
#    endif
#    if defined(ENABLE_RGB_MATRIX_BAND_SAT)
    {6, RGB_MATRIX_BAND_SAT},
#    endif
#    if defined(ENABLE_RGB_MATRIX_BAND_VAL)
    {7, RGB_MATRIX_BAND_VAL},
#    endif
#    if defined(ENABLE_RGB_MATRIX_BAND_PINWHEEL_SAT)
    {8, RGB_MATRIX_BAND_PINWHEEL_SAT},
#    endif
#    if defined(ENABLE_RGB_MATRIX_BAND_PINWHEEL_VAL)
    {9, RGB_MATRIX_BAND_PINWHEEL_VAL},
#    endif
#    if defined(ENABLE_RGB_MATRIX_BAND_SPIRAL_SAT)
    {10, RGB_MATRIX_BAND_SPIRAL_SAT},
#    endif
#    if defined(ENABLE_RGB_MATRIX_BAND_SPIRAL_VAL)
    {11, RGB_MATRIX_BAND_SPIRAL_VAL},
#    endif
#    if defined(ENABLE_RGB_MATRIX_CYCLE_ALL)
    {12, RGB_MATRIX_CYCLE_ALL},
#    endif
#    if defined(ENABLE_RGB_MATRIX_CYCLE_LEFT_RIGHT)
    {13, RGB_MATRIX_CYCLE_LEFT_RIGHT},
#    endif
#    if defined(ENABLE_RGB_MATRIX_CYCLE_UP_DOWN)
    {14, RGB_MATRIX_CYCLE_UP_DOWN},
#    endif
#    if defined(ENABLE_RGB_MATRIX_RAINBOW_MOVING_CHEVRON)
    {15, RGB_MATRIX_RAINBOW_MOVING_CHEVRON},
#    endif
#    if defined(ENABLE_RGB_MATRIX_CYCLE_OUT_IN)
    {16, RGB_MATRIX_CYCLE_OUT_IN},
#    endif
#    if defined(ENABLE_RGB_MATRIX_CYCLE_OUT_IN_DUAL)
    {17, RGB_MATRIX_CYCLE_OUT_IN_DUAL},
#    endif
#    if defined(ENABLE_RGB_MATRIX_CYCLE_PINWHEEL)
    {18, RGB_MATRIX_CYCLE_PINWHEEL},
#    endif
#    if defined(ENABLE_RGB_MATRIX_CYCLE_SPIRAL)
    {19, RGB_MATRIX_CYCLE_SPIRAL},
#    endif
#    if defined(ENABLE_RGB_MATRIX_DUAL_BEACON)
    {20, RGB_MATRIX_DUAL_BEACON},
#    endif
#    if defined(ENABLE_RGB_MATRIX_RAINBOW_BEACON)
    {21, RGB_MATRIX_RAINBOW_BEACON},
#    endif
#    if defined(ENABLE_RGB_MATRIX_RAINBOW_PINWHEELS)
    {22, RGB_MATRIX_RAINBOW_PINWHEELS},
#    endif
#    if defined(ENABLE_RGB_MATRIX_RAINDROPS)
    {23, RGB_MATRIX_RAINDROPS},
#    endif
#    if defined(ENABLE_RGB_MATRIX_JELLYBEAN_RAINDROPS)
    {24, RGB_MATRIX_JELLYBEAN_RAINDROPS},
#    endif
#    if defined(ENABLE_RGB_MATRIX_HUE_BREATHING)
    {25, RGB_MATRIX_HUE_BREATHING},
#    endif
#    if defined(ENABLE_RGB_MATRIX_HUE_PENDULUM)
    {26, RGB_MATRIX_HUE_PENDULUM},
#    endif
#    if defined(ENABLE_RGB_MATRIX_HUE_WAVE)
    {27, RGB_MATRIX_HUE_WAVE},
#    endif
#    if defined(ENABLE_RGB_MATRIX_PIXEL_RAIN)
    {28, RGB_MATRIX_PIXEL_RAIN},
#    endif
#    if defined(ENABLE_RGB_MATRIX_PIXEL_FLOW)
    {29, RGB_MATRIX_PIXEL_FLOW},
#    endif
#    if defined(ENABLE_RGB_MATRIX_PIXEL_FRACTAL)
    {30, RGB_MATRIX_PIXEL_FRACTAL},
#    endif
};

#    define OBBUT_PROTOCOL_RGB_EFFECT_COUNT (sizeof(obbut_protocol_rgb_effects) / sizeof(obbut_protocol_rgb_effects[0]))

static uint8_t obbut_protocol_effect_for_qmk(uint8_t qmk_effect) {
    for (uint8_t index = 0; index < OBBUT_PROTOCOL_RGB_EFFECT_COUNT; index++) {
        if (obbut_protocol_rgb_effects[index].qmk_effect == qmk_effect) {
            return obbut_protocol_rgb_effects[index].protocol_effect;
        }
    }
    return UINT8_MAX;
}

static uint8_t obbut_qmk_effect_for_protocol(uint8_t protocol_effect) {
    for (uint8_t index = 0; index < OBBUT_PROTOCOL_RGB_EFFECT_COUNT; index++) {
        if (obbut_protocol_rgb_effects[index].protocol_effect == protocol_effect) {
            return obbut_protocol_rgb_effects[index].qmk_effect;
        }
    }
    return RGB_MATRIX_NONE;
}
#endif

static uint16_t matrix_entry_count(void) {
    return (uint16_t)qmk_swift_layer_count() * MATRIX_ROWS * MATRIX_COLS;
}

keymap_protocol_platform_snapshot_t keymap_protocol_platform_get_snapshot(void) {
    keymap_protocol_platform_snapshot_t snapshot = {
        .timestamp                    = timer_read32(),
        .layer_state_mask             = (uint32_t)layer_state,
        .default_layer_state_mask     = (uint32_t)default_layer_state,
        .layout_id                    = qmk_swift_layout_id(),
        .semantic_fingerprint          = qmk_swift_semantic_fingerprint(),
        .style_fingerprint             = qmk_swift_style_fingerprint(),
        .layer_count                  = qmk_swift_layer_count(),
        .matrix_row_count             = MATRIX_ROWS,
        .matrix_column_count          = MATRIX_COLS,
        .encoder_count                = qmk_swift_encoder_count(),
        .rgb_effect_index             = UINT8_MAX,
    };

#if defined(RGB_MATRIX_ENABLE)
    HSV rgb_hsv                    = rgb_matrix_get_hsv();
    snapshot.includes_rgb_settings = 1;
    snapshot.rgb_effect_index       = obbut_protocol_effect_for_qmk(rgb_matrix_get_mode());
    snapshot.rgb_hue                = rgb_hsv.h;
    snapshot.rgb_saturation         = rgb_hsv.s;
    snapshot.rgb_brightness         = rgb_hsv.v;
    snapshot.is_rgb_enabled         = rgb_matrix_is_enabled();
    snapshot.rgb_speed              = rgb_matrix_get_speed();
#endif
    return snapshot;
}

keymap_protocol_platform_entry_t keymap_protocol_platform_get_entry(uint16_t index) {
    uint16_t matrix_count = matrix_entry_count();
    keymap_protocol_platform_entry_t entry = {0};
    if (index < matrix_count) {
        uint16_t matrix_size = MATRIX_ROWS * MATRIX_COLS;
        uint8_t layer = index / matrix_size;
        uint16_t position = index % matrix_size;
        uint8_t row = position / MATRIX_COLS;
        uint8_t column = position % MATRIX_COLS;
        entry.keycode = qmk_swift_keycode_at(layer, row, column);
        entry.semantic_id = qmk_swift_semantic_id_at(layer, row, column);
        entry.style_id = qmk_swift_style_id_at(layer, row, column);
        return entry;
    }

    uint8_t encoder_count = qmk_swift_encoder_count();
    if (encoder_count == 0) return entry;
    uint16_t encoder_offset = index - matrix_count;
    uint8_t layer = encoder_offset / (encoder_count * 2);
    uint8_t encoder = (encoder_offset / 2) % encoder_count;
    uint8_t direction = encoder_offset % 2;
    entry.keycode = qmk_swift_encoder_keycode_at(layer, encoder, direction);
    entry.semantic_id = qmk_swift_encoder_semantic_id_at(layer, encoder, direction);
    entry.style_id = qmk_swift_encoder_style_id_at(layer, encoder, direction);
    return entry;
}

void keymap_protocol_platform_send(uint8_t *data, uint8_t length) {
    raw_hid_send(data, length);
}

void keymap_protocol_platform_enter_bootloader(void) {
#if defined(OBBUT_TEST_CRASH_RECOVERY)
    __asm volatile("udf #0");
#else
    reset_keyboard();
#endif
}

uint8_t keymap_protocol_platform_apply_rgb(
    uint8_t effect_index,
    uint8_t hue,
    uint8_t saturation,
    uint8_t brightness,
    uint8_t is_enabled,
    uint8_t speed
) {
#if defined(RGB_MATRIX_ENABLE)
    uint8_t qmk_effect = obbut_qmk_effect_for_protocol(effect_index);
    if (qmk_effect == RGB_MATRIX_NONE) return 0;
    rgb_matrix_enable();
    rgb_matrix_mode(qmk_effect);
    rgb_matrix_sethsv(hue, saturation, brightness);
    rgb_matrix_set_speed(speed);
    if (!is_enabled) rgb_matrix_disable();
    obbut_keymap_rgb_settings_applied();
    return 1;
#else
    (void)effect_index;
    (void)hue;
    (void)saturation;
    (void)brightness;
    (void)is_enabled;
    (void)speed;
    return 0;
#endif
}
