// Narrow QMK platform services for the Obbut Embedded Swift runtime.
// SPDX-License-Identifier: GPL-2.0-or-later

#include QMK_KEYBOARD_H
#include "keymap_protocol_bridge.h"
#include "os_detection.h"
#include "transactions.h"

typedef struct {
    uint8_t rgb_preview_mode;
    uint8_t pointer_drag_lock_active;
} obbut_split_wire_state_t;

static void obbut_split_state_handler(uint8_t in_buflen, const void *in_data, uint8_t out_buflen, void *out_data) {
    (void)out_buflen;
    (void)out_data;
    if (in_buflen != sizeof(obbut_split_wire_state_t)) return;
    const obbut_split_wire_state_t *state = in_data;
#if !defined(OBBUT_BYPASS_SPLIT)
#    if defined(OBBUT_DIAGNOSTICS)
    obbut_crash_recovery_mark_phase(OBBUT_CRASH_PHASE_SPLIT_SYNCHRONIZATION);
#    endif
    qmk_swift_receive_split_state(state->rgb_preview_mode, state->pointer_drag_lock_active);
#    if defined(OBBUT_DIAGNOSTICS)
    obbut_crash_recovery_mark_phase(OBBUT_CRASH_PHASE_IDLE);
#    endif
#endif
}

void obbut_platform_register_split_sync(void) {
    transaction_register_rpc(USER_SYNC_RGB_PREVIEW, obbut_split_state_handler);
}

uint8_t obbut_platform_sync_split_state(uint8_t rgb_preview_mode, uint8_t drag_lock_active) {
#if defined(OBBUT_BYPASS_SPLIT)
    (void)rgb_preview_mode;
    (void)drag_lock_active;
    return 0;
#else
#    if defined(OBBUT_DIAGNOSTICS)
    obbut_crash_recovery_mark_phase(OBBUT_CRASH_PHASE_SPLIT_SYNCHRONIZATION);
#    endif
    const obbut_split_wire_state_t state = {
        .rgb_preview_mode = rgb_preview_mode,
        .pointer_drag_lock_active = drag_lock_active,
    };
    uint8_t result = transaction_rpc_send(USER_SYNC_RGB_PREVIEW, sizeof(state), &state) ? 1 : 0;
#    if defined(OBBUT_DIAGNOSTICS)
    obbut_crash_recovery_mark_phase(OBBUT_CRASH_PHASE_SWIFT_HOUSEKEEPING);
#    endif
    return result;
#endif
}

uint32_t obbut_platform_remove_auto_mouse_layer(uint32_t state) {
#if defined(POINTING_DEVICE_AUTO_MOUSE_ENABLE)
    return (uint32_t)remove_auto_mouse_layer((layer_state_t)state, true);
#else
    return state;
#endif
}

void obbut_platform_set_auto_mouse_enabled(uint8_t enabled) {
#if defined(POINTING_DEVICE_AUTO_MOUSE_ENABLE)
    set_auto_mouse_enable(enabled != 0);
#else
    (void)enabled;
#endif
}

void obbut_platform_configure_auto_mouse(uint8_t layer) {
#if defined(POINTING_DEVICE_AUTO_MOUSE_ENABLE)
    set_auto_mouse_layer(layer);
    set_auto_mouse_enable(true);
#else
    (void)layer;
#endif
}

void obbut_platform_auto_mouse_reset_trigger(void) {
#if defined(POINTING_DEVICE_AUTO_MOUSE_ENABLE)
    auto_mouse_reset_trigger(true);
#endif
}

uint8_t obbut_platform_auto_mouse_toggle_state(void) {
#if defined(POINTING_DEVICE_AUTO_MOUSE_ENABLE)
    return get_auto_mouse_toggle() ? 1 : 0;
#else
    return 0;
#endif
}

void obbut_platform_toggle_auto_mouse(void) {
#if defined(POINTING_DEVICE_AUTO_MOUSE_ENABLE)
    auto_mouse_toggle();
#endif
}

void obbut_platform_release_left_pointer_button(void) {
#if defined(POINTING_DEVICE_ENABLE)
    report_mouse_t report = pointing_device_get_report();
    report.buttons &= ~MOUSE_BTN1;
    pointing_device_set_report(report);
#endif
}

void obbut_keymap_rgb_settings_applied(void) {
    qmk_swift_rgb_settings_applied();
}
