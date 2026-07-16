// Static QMK boundary for the selected Embedded Swift firmware.
// SPDX-License-Identifier: GPL-2.0-or-later

#include QMK_KEYBOARD_H
#include "keymap_protocol_bridge.h"

// Cortex-M0+ has naturally atomic aligned 32-bit loads and stores, but the
// bare-metal toolchain ships without libatomic. Swift uses these helpers only
// for its one-time initialization tokens before QMK begins processing input.
uint32_t __atomic_load_4(const volatile void *pointer, int memory_order) {
    (void)memory_order;
    return *(const volatile uint32_t *)pointer;
}

void __atomic_store_4(volatile void *pointer, uint32_t value, int memory_order) {
    (void)memory_order;
    *(volatile uint32_t *)pointer = value;
}

bool __atomic_compare_exchange_4(
    volatile void *pointer,
    void *expected_pointer,
    uint32_t desired,
    bool weak,
    int success_memory_order,
    int failure_memory_order
) {
    (void)weak;
    (void)success_memory_order;
    (void)failure_memory_order;
    volatile uint32_t *value = (volatile uint32_t *)pointer;
    uint32_t *expected = (uint32_t *)expected_pointer;
    if (*value != *expected) {
        *expected = *value;
        return false;
    }
    *value = desired;
    return true;
}

#if defined(OS_DETECTION_ENABLE)
#    include "os_detection.h"
#endif

#if defined(OBBUT_KEYCHRON_FIRMWARE)
#    include "keychron_common.h"
#endif

static keyrecord_t *obbut_current_keyrecord;

uint16_t obbut_qmk_keycode_mission_control(void) {
#if defined(OBBUT_KEYCHRON_FIRMWARE)
    return KC_MCTRL;
#else
    return KC_MCTL;
#endif
}

uint16_t obbut_qmk_keycode_task_view(void) {
#if defined(OBBUT_KEYCHRON_FIRMWARE)
    return KC_TASK;
#else
    return KC_NO;
#endif
}

uint16_t obbut_qmk_keycode_file_explorer(void) {
#if defined(OBBUT_KEYCHRON_FIRMWARE)
    return KC_FILE;
#else
    return KC_NO;
#endif
}

uint16_t obbut_qmk_keycode_keychron_bluetooth_host_1(void) {
#if defined(OBBUT_KEYCHRON_FIRMWARE)
    return BT_HST1;
#else
    return KC_NO;
#endif
}

uint16_t obbut_qmk_keycode_keychron_bluetooth_host_2(void) {
#if defined(OBBUT_KEYCHRON_FIRMWARE)
    return BT_HST2;
#else
    return KC_NO;
#endif
}

uint16_t obbut_qmk_keycode_keychron_bluetooth_host_3(void) {
#if defined(OBBUT_KEYCHRON_FIRMWARE)
    return BT_HST3;
#else
    return KC_NO;
#endif
}

uint16_t obbut_qmk_keycode_keychron_wireless_24_ghz(void) {
#if defined(OBBUT_KEYCHRON_FIRMWARE)
    return P2P4G;
#else
    return KC_NO;
#endif
}

uint16_t obbut_qmk_keycode_keychron_battery_level(void) {
#if defined(OBBUT_KEYCHRON_FIRMWARE)
    return BAT_LVL;
#else
    return KC_NO;
#endif
}

__attribute__((weak)) void obbut_platform_register_split_sync(void) {}

__attribute__((weak)) uint8_t obbut_platform_sync_split_state(uint8_t rgb_preview_mode, uint8_t drag_lock_active) {
    (void)rgb_preview_mode;
    (void)drag_lock_active;
    return 0;
}

uint8_t obbut_platform_is_keyboard_master(void) {
#if defined(SPLIT_KEYBOARD)
    return is_keyboard_master() ? 1 : 0;
#else
    return 1;
#endif
}

uint32_t obbut_platform_timer_read32(void) {
    return timer_read32();
}

uint8_t obbut_platform_is_windows(void) {
#if defined(OS_DETECTION_ENABLE)
    return detected_host_os() == OS_WINDOWS ? 1 : 0;
#else
    return 0;
#endif
}

void obbut_platform_layer_invert(uint8_t layer) {
    layer_invert(layer);
}

void obbut_platform_send_keycode(uint16_t keycode, uint8_t pressed) {
    if (pressed) {
        register_code16(keycode);
    } else {
        unregister_code16(keycode);
    }
}

uint8_t obbut_platform_process_keychron_common(uint16_t keycode, uint8_t pressed) {
    (void)pressed;
#if defined(OBBUT_KEYCHRON_FIRMWARE)
    if (obbut_current_keyrecord == NULL) return 1;
    return process_record_keychron_common(keycode, obbut_current_keyrecord) ? 1 : 0;
#else
    (void)keycode;
    return 1;
#endif
}

__attribute__((weak)) uint32_t obbut_platform_remove_auto_mouse_layer(uint32_t state) {
    return state;
}

__attribute__((weak)) void obbut_platform_set_auto_mouse_enabled(uint8_t enabled) {
    (void)enabled;
}

__attribute__((weak)) void obbut_platform_configure_auto_mouse(uint8_t layer) {
    (void)layer;
}

__attribute__((weak)) void obbut_platform_auto_mouse_reset_trigger(void) {}

__attribute__((weak)) uint8_t obbut_platform_auto_mouse_toggle_state(void) {
    return 0;
}

__attribute__((weak)) void obbut_platform_toggle_auto_mouse(void) {}

__attribute__((weak)) void obbut_platform_release_left_pointer_button(void) {}

void obbut_platform_initialize_planck_leds(void) {
#if defined(OBBUT_PLANCK_FIRMWARE)
    planck_ez_right_led_level(255 / 4);
    planck_ez_left_led_level(255 / 4);
    planck_ez_left_led_off();
    planck_ez_right_led_off();
#endif
}

uint32_t obbut_platform_update_tri_layer_state(
    uint32_t state,
    uint8_t lower,
    uint8_t upper,
    uint8_t adjust
) {
#if defined(TRI_LAYER_ENABLE)
    return (uint32_t)update_tri_layer_state((layer_state_t)state, lower, upper, adjust);
#else
    (void)lower;
    (void)upper;
    (void)adjust;
    return state;
#endif
}

uint8_t obbut_platform_matrix_row_count(void) {
    return MATRIX_ROWS;
}

uint8_t obbut_platform_matrix_column_count(void) {
    return MATRIX_COLS;
}

uint8_t obbut_platform_matrix_led_index(uint8_t row, uint8_t column) {
#if defined(RGB_MATRIX_ENABLE)
    if (row >= MATRIX_ROWS || column >= MATRIX_COLS) return NO_LED;
    return g_led_config.matrix_co[row][column];
#else
    (void)row;
    (void)column;
    return UINT8_MAX;
#endif
}

void obbut_platform_rgb_set_color(
    uint8_t led,
    uint8_t red,
    uint8_t green,
    uint8_t blue
) {
#if defined(RGB_MATRIX_ENABLE)
    rgb_matrix_set_color(led, red, green, blue);
#else
    (void)led;
    (void)red;
    (void)green;
    (void)blue;
#endif
}

uint16_t obbut_platform_swift_keycode(uint8_t layer, uint8_t row, uint8_t column) {
    return qmk_swift_keycode_at(layer, row, column);
}

uint16_t obbut_platform_swift_legend_id(uint8_t layer, uint8_t row, uint8_t column) {
    return qmk_swift_legend_id_at(layer, row, column);
}

uint16_t obbut_platform_swift_style_id(uint8_t layer, uint8_t row, uint8_t column) {
    return qmk_swift_style_id_at(layer, row, column);
}

uint32_t obbut_platform_swift_style_color(uint8_t layer, uint8_t row, uint8_t column) {
    return qmk_swift_style_color_at(layer, row, column);
}

uint8_t keymap_layer_count(void) {
    return qmk_swift_layer_count();
}

uint16_t keycode_at_keymap_location(uint8_t layer, uint8_t row, uint8_t column) {
    return qmk_swift_keycode_at(layer, row, column);
}

#if defined(ENCODER_MAP_ENABLE)
uint8_t encodermap_layer_count(void) {
    return qmk_swift_layer_count();
}

uint16_t keycode_at_encodermap_location(uint8_t layer, uint8_t encoder, bool clockwise) {
    uint8_t encoder_count = qmk_swift_encoder_count();
    if (encoder_count == 0) {
        return KC_NO;
    }
    return qmk_swift_encoder_keycode_at(layer, encoder % encoder_count, clockwise ? 1 : 0);
}
#endif

void keyboard_post_init_user(void) {
    qmk_swift_post_init();
}

void housekeeping_task_user(void) {
    qmk_swift_housekeeping();
}

bool process_record_user(uint16_t keycode, keyrecord_t *record) {
    obbut_current_keyrecord = record;
    bool should_continue = qmk_swift_process_record(keycode, record->event.pressed ? 1 : 0) != 0;
    obbut_current_keyrecord = NULL;
    return should_continue;
}

layer_state_t layer_state_set_user(layer_state_t state) {
    return (layer_state_t)qmk_swift_layer_state_set((uint32_t)state);
}

#if defined(POINTING_DEVICE_ENABLE)
void pointing_device_init_user(void) {
    qmk_swift_pointing_device_init();
}

report_mouse_t pointing_device_task_user(report_mouse_t report) {
    qmk_swift_pointing_device_task(&report.x, &report.y, &report.h, &report.v, &report.buttons);
    return report;
}
#endif

#if defined(RGB_MATRIX_ENABLE)
bool rgb_matrix_indicators_advanced_user(uint8_t led_min, uint8_t led_max) {
    return qmk_swift_rgb_matrix_indicators(led_min, led_max) != 0;
}
#endif

#if defined(RAW_ENABLE)
#    if defined(OBBUT_KEYCHRON_FIRMWARE)
bool keychron_raw_hid_receive_user(uint8_t *data, uint8_t length) {
    return qmk_swift_raw_hid_receive(data, length) != 0;
}
#    else
void raw_hid_receive(uint8_t *data, uint8_t length) {
    (void)qmk_swift_raw_hid_receive(data, length);
}
#    endif
#endif
