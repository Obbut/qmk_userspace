// Narrow generated-keymap boundary between QMK and Embedded Swift.
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <stdint.h>
#include "keymap.generated.h"

#if defined(__clang__)
#    define KEYMAP_PROTOCOL_NONNULL _Nonnull
#else
#    define KEYMAP_PROTOCOL_NONNULL
#endif

typedef struct {
    uint32_t timestamp;
    uint32_t layer_state_mask;
    uint32_t default_layer_state_mask;
    uint32_t layout_id;
    uint32_t semantic_fingerprint;
    uint32_t style_fingerprint;
    uint8_t  layer_count;
    uint8_t  matrix_row_count;
    uint8_t  matrix_column_count;
    uint8_t  encoder_count;
    uint8_t  includes_rgb_settings;
    uint8_t  rgb_effect_index;
    uint8_t  rgb_hue;
    uint8_t  rgb_saturation;
    uint8_t  rgb_brightness;
    uint8_t  is_rgb_enabled;
    uint8_t  rgb_speed;
} keymap_protocol_platform_snapshot_t;

typedef struct {
    uint16_t keycode;
    uint16_t semantic_id;
    uint16_t style_id;
} keymap_protocol_platform_entry_t;

void keymap_protocol_receive(const uint8_t *KEYMAP_PROTOCOL_NONNULL data, uint8_t length);
void keymap_protocol_housekeeping(void);

keymap_protocol_platform_snapshot_t keymap_protocol_platform_get_snapshot(void);
keymap_protocol_platform_entry_t keymap_protocol_platform_get_entry(uint16_t index);
void keymap_protocol_platform_send(uint8_t *KEYMAP_PROTOCOL_NONNULL data, uint8_t length);
uint8_t keymap_protocol_platform_apply_rgb(
    uint8_t effect_index,
    uint8_t hue,
    uint8_t saturation,
    uint8_t brightness,
    uint8_t is_enabled,
    uint8_t speed
);

// Embedded Swift module boundary. The selected firmware module supplies the
// profile; ObbutKeymaps supplies the shared behavior entry points.
uint8_t obbut_firmware_profile(void);
void obbut_swift_post_init(uint8_t profile);
void obbut_swift_housekeeping(void);
uint8_t obbut_swift_process_record(uint8_t kind, uint8_t pressed);
uint32_t obbut_swift_layer_state_changed(uint32_t state);
void obbut_swift_pointing_device_init(void);
void obbut_swift_transform_pointer(
    int8_t *KEYMAP_PROTOCOL_NONNULL x,
    int8_t *KEYMAP_PROTOCOL_NONNULL y,
    int8_t *KEYMAP_PROTOCOL_NONNULL horizontal,
    int8_t *KEYMAP_PROTOCOL_NONNULL vertical,
    uint8_t *KEYMAP_PROTOCOL_NONNULL buttons,
    uint8_t lower_layer_active
);
void obbut_swift_receive_split_state(uint8_t rgb_preview_mode, uint8_t drag_lock_active);
uint8_t obbut_swift_rgb_preview_mode(void);
uint8_t obbut_swift_pointer_drag_lock_active(void);
void obbut_swift_rgb_settings_applied(void);

// Narrow QMK services consumed by the shared Obbut Embedded Swift module.
void obbut_platform_register_split_sync(void);
uint8_t obbut_platform_sync_split_state(uint8_t rgb_preview_mode, uint8_t drag_lock_active);
uint8_t obbut_platform_is_keyboard_master(void);
uint32_t obbut_platform_timer_read32(void);
uint8_t obbut_platform_highest_layer(void);
uint8_t obbut_platform_is_windows(void);
void obbut_platform_layer_invert(uint8_t layer);
void obbut_platform_send_override(uint8_t kind, uint8_t pressed);
uint32_t obbut_platform_remove_auto_mouse_layer(uint32_t state);
void obbut_platform_set_auto_mouse_enabled(uint8_t enabled);
void obbut_platform_configure_auto_mouse(uint8_t layer);
void obbut_platform_auto_mouse_reset_trigger(void);
uint8_t obbut_platform_auto_mouse_toggle_state(void);
void obbut_platform_toggle_auto_mouse(void);
void obbut_platform_release_left_pointer_button(void);
