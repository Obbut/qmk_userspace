// Narrow ABI boundary between QMK and the selected Embedded Swift firmware.
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <stdint.h>
#include "quantum_keycodes.h"

#if defined(VIA_ENABLE) || defined(DYNAMIC_KEYMAP_ENABLE)
#    error "Swift firmware lookup is incompatible with VIA and dynamic keymaps."
#endif

#if defined(__clang__)
#    define KEYMAP_PROTOCOL_NONNULL _Nonnull
#else
#    define KEYMAP_PROTOCOL_NONNULL
#endif

enum obbut_custom_keycodes {
    PTR_SCROLL = SAFE_RANGE,
    PTR_SNIPER,
    PTR_DRAG_LOCK,
    PTR_SENS_DOWN,
    PTR_SENS_UP,
    PTR_SCROLL_DOWN,
    PTR_SCROLL_UP,
};

// Stable across firmware builds: retained crash records may outlive the image
// that produced them and must remain interpretable without its symbols.
typedef enum {
    OBBUT_CRASH_REASON_UNKNOWN = 0,
    OBBUT_CRASH_REASON_HARD_FAULT = 1,
    OBBUT_CRASH_REASON_MEMORY_MANAGEMENT_FAULT = 2,
    OBBUT_CRASH_REASON_BUS_FAULT = 3,
    OBBUT_CRASH_REASON_USAGE_FAULT = 4,
    OBBUT_CRASH_REASON_WATCHDOG = 5,
    OBBUT_CRASH_REASON_POWER_ON_OR_BROWNOUT = 6,
} obbut_crash_reason_t;

typedef enum {
    OBBUT_CRASH_PHASE_IDLE = 0,
    OBBUT_CRASH_PHASE_BOOT = 1,
    OBBUT_CRASH_PHASE_SWIFT_POST_INIT = 2,
    OBBUT_CRASH_PHASE_SWIFT_HOUSEKEEPING = 3,
    OBBUT_CRASH_PHASE_PROTOCOL_HOUSEKEEPING = 4,
    OBBUT_CRASH_PHASE_SPLIT_SYNCHRONIZATION = 5,
    OBBUT_CRASH_PHASE_KEY_LOOKUP = 6,
    OBBUT_CRASH_PHASE_PROCESS_RECORD = 7,
    OBBUT_CRASH_PHASE_LAYER_STATE = 8,
    OBBUT_CRASH_PHASE_POINTING_INITIALIZATION = 9,
    OBBUT_CRASH_PHASE_POINTING_TASK = 10,
    OBBUT_CRASH_PHASE_RGB_RENDERING = 11,
    OBBUT_CRASH_PHASE_RAW_HID = 12,
    OBBUT_CRASH_PHASE_METADATA_TRAVERSAL = 13,
} obbut_crash_phase_t;

enum obbut_crash_flags {
    OBBUT_CRASH_FLAG_FAULT_REGISTERS_VALID = 1 << 0,
    OBBUT_CRASH_FLAG_STACK_GUARD_VALID = 1 << 1,
    OBBUT_CRASH_FLAG_STACK_GUARD_DAMAGED = 1 << 2,
    OBBUT_CRASH_FLAG_STACK_HIGH_WATER_VALID = 1 << 3,
    OBBUT_CRASH_FLAG_DEEP_DIAGNOSTICS = 1 << 4,
};

// Exactly 26 bytes: this is the complete protocol-v4 crash payload.
typedef struct __attribute__((packed)) {
    uint8_t reason;
    uint8_t phase;
    uint8_t flags;
    uint8_t consecutive_failures;
    uint32_t build_id;
    uint32_t uptime;
    uint32_t program_counter;
    uint32_t link_register;
    uint32_t stack_pointer;
    uint16_t stack_free;
} obbut_crash_report_t;

static inline uint16_t obbut_qmk_keycode_brightness_down(void) { return KC_BRID; }
static inline uint16_t obbut_qmk_keycode_brightness_up(void) { return KC_BRIU; }
uint16_t obbut_qmk_keycode_mission_control(void);
static inline uint16_t obbut_qmk_keycode_launchpad(void) { return KC_LPAD; }
uint16_t obbut_qmk_keycode_task_view(void);
uint16_t obbut_qmk_keycode_file_explorer(void);
static inline uint16_t obbut_qmk_keycode_tri_layer_upper(void) { return TL_UPPR; }
static inline uint16_t obbut_qmk_keycode_tri_layer_lower(void) { return TL_LOWR; }
#if defined(OBBUT_KEYCHRON_FIRMWARE)
static inline uint16_t obbut_qmk_keycode_rgb_matrix_toggle(void) { return RGB_TOG; }
static inline uint16_t obbut_qmk_keycode_rgb_matrix_next(void) { return RGB_MOD; }
static inline uint16_t obbut_qmk_keycode_rgb_matrix_previous(void) { return RGB_RMOD; }
static inline uint16_t obbut_qmk_keycode_rgb_matrix_hue_up(void) { return RGB_HUI; }
static inline uint16_t obbut_qmk_keycode_rgb_matrix_hue_down(void) { return RGB_HUD; }
static inline uint16_t obbut_qmk_keycode_rgb_matrix_saturation_up(void) { return RGB_SAI; }
static inline uint16_t obbut_qmk_keycode_rgb_matrix_saturation_down(void) { return RGB_SAD; }
static inline uint16_t obbut_qmk_keycode_rgb_matrix_value_up(void) { return RGB_VAI; }
static inline uint16_t obbut_qmk_keycode_rgb_matrix_value_down(void) { return RGB_VAD; }
static inline uint16_t obbut_qmk_keycode_rgb_matrix_speed_up(void) { return RGB_SPI; }
static inline uint16_t obbut_qmk_keycode_rgb_matrix_speed_down(void) { return RGB_SPD; }
static inline uint16_t obbut_qmk_keycode_pointer_button_1(void) { return KC_BTN1; }
static inline uint16_t obbut_qmk_keycode_pointer_button_2(void) { return KC_BTN2; }
static inline uint16_t obbut_qmk_keycode_pointer_button_3(void) { return KC_BTN3; }
#else
static inline uint16_t obbut_qmk_keycode_rgb_matrix_toggle(void) { return RM_TOGG; }
static inline uint16_t obbut_qmk_keycode_rgb_matrix_next(void) { return RM_NEXT; }
static inline uint16_t obbut_qmk_keycode_rgb_matrix_previous(void) { return RM_PREV; }
static inline uint16_t obbut_qmk_keycode_rgb_matrix_hue_up(void) { return RM_HUEU; }
static inline uint16_t obbut_qmk_keycode_rgb_matrix_hue_down(void) { return RM_HUED; }
static inline uint16_t obbut_qmk_keycode_rgb_matrix_saturation_up(void) { return RM_SATU; }
static inline uint16_t obbut_qmk_keycode_rgb_matrix_saturation_down(void) { return RM_SATD; }
static inline uint16_t obbut_qmk_keycode_rgb_matrix_value_up(void) { return RM_VALU; }
static inline uint16_t obbut_qmk_keycode_rgb_matrix_value_down(void) { return RM_VALD; }
static inline uint16_t obbut_qmk_keycode_rgb_matrix_speed_up(void) { return RM_SPDU; }
static inline uint16_t obbut_qmk_keycode_rgb_matrix_speed_down(void) { return RM_SPDD; }
static inline uint16_t obbut_qmk_keycode_pointer_button_1(void) { return MS_BTN1; }
static inline uint16_t obbut_qmk_keycode_pointer_button_2(void) { return MS_BTN2; }
static inline uint16_t obbut_qmk_keycode_pointer_button_3(void) { return MS_BTN3; }
#endif
static inline uint16_t obbut_qmk_keycode_browser_back(void) { return KC_WBAK; }
static inline uint16_t obbut_qmk_keycode_browser_forward(void) { return KC_WFWD; }
static inline uint16_t obbut_qmk_keycode_pointer_scroll(void) { return PTR_SCROLL; }
static inline uint16_t obbut_qmk_keycode_pointer_sniper(void) { return PTR_SNIPER; }
static inline uint16_t obbut_qmk_keycode_pointer_drag_lock(void) { return PTR_DRAG_LOCK; }
static inline uint16_t obbut_qmk_keycode_pointer_sensitivity_down(void) { return PTR_SENS_DOWN; }
static inline uint16_t obbut_qmk_keycode_pointer_sensitivity_up(void) { return PTR_SENS_UP; }
static inline uint16_t obbut_qmk_keycode_pointer_scroll_speed_down(void) { return PTR_SCROLL_DOWN; }
static inline uint16_t obbut_qmk_keycode_pointer_scroll_speed_up(void) { return PTR_SCROLL_UP; }

uint16_t obbut_qmk_keycode_keychron_bluetooth_host_1(void);
uint16_t obbut_qmk_keycode_keychron_bluetooth_host_2(void);
uint16_t obbut_qmk_keycode_keychron_bluetooth_host_3(void);
uint16_t obbut_qmk_keycode_keychron_wireless_24_ghz(void);
uint16_t obbut_qmk_keycode_keychron_battery_level(void);

typedef struct {
    uint32_t timestamp;
    uint32_t layer_state_mask;
    uint32_t default_layer_state_mask;
    uint32_t layout_id;
    uint32_t legend_fingerprint;
    uint32_t style_fingerprint;
    uint8_t layer_count;
    uint8_t matrix_row_count;
    uint8_t matrix_column_count;
    uint8_t encoder_count;
    uint8_t includes_rgb_settings;
    uint8_t rgb_effect_index;
    uint8_t rgb_hue;
    uint8_t rgb_saturation;
    uint8_t rgb_brightness;
    uint8_t is_rgb_enabled;
    uint8_t rgb_speed;
} keymap_protocol_platform_snapshot_t;

typedef struct {
    uint16_t keycode;
    uint16_t legend_id;
    uint16_t style_id;
} keymap_protocol_platform_entry_t;

void keymap_protocol_receive(const uint8_t *KEYMAP_PROTOCOL_NONNULL data, uint8_t length);
void keymap_protocol_housekeeping(void);
keymap_protocol_platform_snapshot_t keymap_protocol_platform_get_snapshot(void);
keymap_protocol_platform_entry_t keymap_protocol_platform_get_entry(uint16_t index);
void keymap_protocol_platform_send(uint8_t *KEYMAP_PROTOCOL_NONNULL data, uint8_t length);
uint8_t keymap_protocol_platform_apply_rgb(uint8_t, uint8_t, uint8_t, uint8_t, uint8_t, uint8_t);
void keymap_protocol_platform_enter_bootloader(void);
uint8_t keymap_protocol_platform_get_crash_report(obbut_crash_report_t *KEYMAP_PROTOCOL_NONNULL report);
void keymap_protocol_platform_clear_crash_report(void);

void qmk_swift_post_init(void);
void qmk_swift_housekeeping(void);
uint8_t qmk_swift_process_record(uint16_t keycode, uint8_t pressed);
uint32_t qmk_swift_layer_state_set(uint32_t state);
void qmk_swift_pointing_device_init(void);
void qmk_swift_pointing_device_task(int8_t *, int8_t *, int8_t *, int8_t *, uint8_t *);
uint8_t qmk_swift_rgb_matrix_indicators(uint8_t lower_bound, uint8_t upper_bound);
uint8_t qmk_swift_raw_hid_receive(uint8_t *data, uint8_t length);
void qmk_swift_receive_split_state(uint8_t rgb_preview_mode, uint8_t pointer_drag_lock_active);
void qmk_swift_rgb_settings_applied(void);
uint16_t qmk_swift_keycode_at(uint8_t layer, uint8_t row, uint8_t column);
uint16_t qmk_swift_legend_id_at(uint8_t layer, uint8_t row, uint8_t column);
uint16_t qmk_swift_style_id_at(uint8_t layer, uint8_t row, uint8_t column);
uint32_t qmk_swift_style_color_at(uint8_t layer, uint8_t row, uint8_t column);
uint16_t qmk_swift_encoder_keycode_at(uint8_t layer, uint8_t encoder, uint8_t direction);
uint16_t qmk_swift_encoder_legend_id_at(uint8_t layer, uint8_t encoder, uint8_t direction);
uint16_t qmk_swift_encoder_style_id_at(uint8_t layer, uint8_t encoder, uint8_t direction);
uint8_t qmk_swift_layer_count(void);
uint8_t qmk_swift_encoder_count(void);
uint32_t qmk_swift_layout_id(void);
uint32_t qmk_swift_legend_fingerprint(void);
uint32_t qmk_swift_style_fingerprint(void);

void obbut_platform_register_split_sync(void);
uint8_t obbut_platform_sync_split_state(uint8_t rgb_preview_mode, uint8_t drag_lock_active);
uint8_t obbut_platform_is_keyboard_master(void);
uint32_t obbut_platform_timer_read32(void);
uint8_t obbut_platform_is_windows(void);
void obbut_platform_layer_invert(uint8_t layer);
void obbut_platform_send_keycode(uint16_t keycode, uint8_t pressed);
uint8_t obbut_platform_process_keychron_common(uint16_t keycode, uint8_t pressed);
uint32_t obbut_platform_remove_auto_mouse_layer(uint32_t state);
void obbut_platform_set_auto_mouse_enabled(uint8_t enabled);
void obbut_platform_configure_auto_mouse(uint8_t layer);
void obbut_platform_auto_mouse_reset_trigger(void);
uint8_t obbut_platform_auto_mouse_toggle_state(void);
void obbut_platform_toggle_auto_mouse(void);
void obbut_platform_release_left_pointer_button(void);
void obbut_platform_initialize_planck_leds(void);
uint32_t obbut_platform_update_tri_layer_state(uint32_t state, uint8_t lower, uint8_t upper, uint8_t adjust);
uint8_t obbut_platform_matrix_row_count(void);
uint8_t obbut_platform_matrix_column_count(void);
uint8_t obbut_platform_matrix_led_index(uint8_t row, uint8_t column);
void obbut_platform_rgb_set_color(uint8_t led, uint8_t red, uint8_t green, uint8_t blue);
uint16_t obbut_platform_swift_keycode(uint8_t layer, uint8_t row, uint8_t column);
uint16_t obbut_platform_swift_legend_id(uint8_t layer, uint8_t row, uint8_t column);
uint16_t obbut_platform_swift_style_id(uint8_t layer, uint8_t row, uint8_t column);
uint32_t obbut_platform_swift_style_color(uint8_t layer, uint8_t row, uint8_t column);
void obbut_crash_recovery_init(void);
void obbut_crash_recovery_initialize_stack(void);
void obbut_crash_recovery_mark_phase(uint8_t phase);
void obbut_crash_recovery_heartbeat(void);
uint8_t obbut_crash_recovery_get_report(obbut_crash_report_t *KEYMAP_PROTOCOL_NONNULL report);
void obbut_crash_recovery_clear_report(void);
