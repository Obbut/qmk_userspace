// C Glue Layer for Swift-QMK Integration
// Overrides weak QMK callbacks and delegates to Swift functions
// Also provides wrapper functions for QMK macros (Swift can't see C macros)
// SPDX-License-Identifier: GPL-2.0-or-later

#include "quantum.h"
#include "transactions.h"

// ============== SWIFT FUNCTION DECLARATIONS ==============
// These functions are implemented in Swift and exported via @_cdecl

extern void swift_keyboard_post_init(void);
extern void swift_housekeeping_task(void);
extern bool swift_process_record(uint16_t keycode, bool pressed, uint8_t row, uint8_t col);
extern uint32_t swift_layer_state_set(uint32_t state);

#if defined(RGB_MATRIX_ENABLE)
extern bool swift_rgb_matrix_indicators(uint8_t led_min, uint8_t led_max);
#endif

// ============== RGB PREVIEW SYNC ==============
// Shared state for RGB preview mode (synced between keyboard halves)

static bool rgb_preview_mode = false;

// Allow Swift to read/write this state
bool glue_get_rgb_preview_mode(void) {
    return rgb_preview_mode;
}

void glue_set_rgb_preview_mode(bool mode) {
    rgb_preview_mode = mode;
}

// Handler for receiving RGB preview mode sync from master
static void rgb_preview_sync_handler(uint8_t in_buflen, const void* in_data, uint8_t out_buflen, void* out_data) {
    if (in_buflen == sizeof(rgb_preview_mode)) {
        memcpy(&rgb_preview_mode, in_data, sizeof(rgb_preview_mode));
    }
}

// ============== QMK CALLBACK OVERRIDES ==============
// These override the weak-linked QMK callbacks and delegate to Swift

void keyboard_post_init_user(void) {
    // Register the sync handler for RGB preview mode
    transaction_register_rpc(USER_SYNC_RGB_PREVIEW, rgb_preview_sync_handler);

    // Call Swift initialization
    swift_keyboard_post_init();
}

void housekeeping_task_user(void) {
    // Sync RGB preview mode to slave half
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

    // Call Swift housekeeping
    swift_housekeeping_task();
}

bool process_record_user(uint16_t keycode, keyrecord_t *record) {
    return swift_process_record(
        keycode,
        record->event.pressed,
        record->event.key.row,
        record->event.key.col
    );
}

layer_state_t layer_state_set_user(layer_state_t state) {
    return swift_layer_state_set(state);
}

#if defined(RGB_MATRIX_ENABLE)
bool rgb_matrix_indicators_advanced_user(uint8_t led_min, uint8_t led_max) {
    return swift_rgb_matrix_indicators(led_min, led_max);
}
#endif

// ============== GLUE FUNCTIONS FOR SWIFT ==============
// These wrap QMK functions/macros so Swift can call them

// Keyboard state
bool glue_is_keyboard_master(void) {
    return is_keyboard_master();
}

os_variant_t glue_detected_host_os(void) {
    return detected_host_os();
}

uint8_t glue_get_highest_layer(layer_state_t state) {
    return get_highest_layer(state);
}

layer_state_t glue_get_layer_state(void) {
    return layer_state;
}

// Layer control
void glue_layer_invert(uint8_t layer) {
    layer_invert(layer);
}

// Key sending
void glue_tap_code(uint8_t keycode) {
    tap_code(keycode);
}

void glue_tap_code16(uint16_t keycode) {
    tap_code16(keycode);
}

void glue_register_code(uint8_t keycode) {
    register_code(keycode);
}

void glue_unregister_code(uint8_t keycode) {
    unregister_code(keycode);
}

void glue_register_code16(uint16_t keycode) {
    register_code16(keycode);
}

void glue_unregister_code16(uint16_t keycode) {
    unregister_code16(keycode);
}

// Timer functions
uint32_t glue_timer_read32(void) {
    return timer_read32();
}

uint32_t glue_timer_elapsed32(uint32_t t) {
    return timer_elapsed32(t);
}

// RGB Matrix functions
#if defined(RGB_MATRIX_ENABLE)

void glue_rgb_matrix_set_color(uint8_t index, uint8_t r, uint8_t g, uint8_t b) {
    rgb_matrix_set_color(index, r, g, b);
}

void glue_rgb_matrix_set_color_all(uint8_t r, uint8_t g, uint8_t b) {
    rgb_matrix_set_color_all(r, g, b);
}

uint8_t glue_rgb_matrix_get_led_index(uint8_t row, uint8_t col) {
    return g_led_config.matrix_co[row][col];
}

uint8_t glue_matrix_rows(void) {
    return MATRIX_ROWS;
}

uint8_t glue_matrix_cols(void) {
    return MATRIX_COLS;
}

bool glue_led_index_valid(uint8_t led_index, uint8_t led_min, uint8_t led_max) {
    return led_index >= led_min && led_index < led_max && led_index != NO_LED;
}

#endif

// Keymap access
uint16_t glue_keymap_key_to_keycode(uint8_t layer, uint8_t row, uint8_t col) {
    keypos_t pos = {.row = row, .col = col};
    return keymap_key_to_keycode(layer, pos);
}

// ============== SWIFT RUNTIME STUBS ==============
// These provide missing functions that Swift's embedded runtime needs
// For ARMv6-M (Cortex-M0+) which lacks native atomic instructions

#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <stdint.h>

// Use ChibiOS critical sections for atomicity
// On single-core RP2040, disabling interrupts is sufficient
#include "ch.h"

// Atomic load (acquire semantics)
uint32_t __atomic_load_4(volatile void *ptr, int memorder) {
    (void)memorder;
    chSysLock();
    uint32_t val = *(volatile uint32_t*)ptr;
    chSysUnlock();
    return val;
}

// Atomic store (release semantics)
void __atomic_store_4(volatile void *ptr, uint32_t val, int memorder) {
    (void)memorder;
    chSysLock();
    *(volatile uint32_t*)ptr = val;
    chSysUnlock();
}

// Atomic fetch-add
uint32_t __atomic_fetch_add_4(volatile void *ptr, uint32_t val, int memorder) {
    (void)memorder;
    chSysLock();
    uint32_t old = *(volatile uint32_t*)ptr;
    *(volatile uint32_t*)ptr = old + val;
    chSysUnlock();
    return old;
}

// Atomic fetch-sub
uint32_t __atomic_fetch_sub_4(volatile void *ptr, uint32_t val, int memorder) {
    (void)memorder;
    chSysLock();
    uint32_t old = *(volatile uint32_t*)ptr;
    *(volatile uint32_t*)ptr = old - val;
    chSysUnlock();
    return old;
}

// Atomic compare-exchange (strong)
_Bool __atomic_compare_exchange_4(volatile void *ptr, void *expected, uint32_t desired,
                                   _Bool weak, int success_memorder, int failure_memorder) {
    (void)weak;
    (void)success_memorder;
    (void)failure_memorder;
    chSysLock();
    uint32_t current = *(volatile uint32_t*)ptr;
    uint32_t exp = *(uint32_t*)expected;
    _Bool success = (current == exp);
    if (success) {
        *(volatile uint32_t*)ptr = desired;
    } else {
        *(uint32_t*)expected = current;
    }
    chSysUnlock();
    return success;
}

// posix_memalign - aligned memory allocation
// Swift's runtime uses this for aligned allocations
int posix_memalign(void **memptr, size_t alignment, size_t size) {
    // For simplicity, use malloc and hope for natural alignment
    // On ARM Cortex-M, malloc typically returns 8-byte aligned memory
    // which is sufficient for most Swift use cases
    if (alignment <= sizeof(void*)) {
        void *ptr = malloc(size);
        if (ptr) {
            *memptr = ptr;
            return 0;
        }
        return ENOMEM;
    }

    // For larger alignments, allocate extra space and align manually
    void *ptr = malloc(size + alignment - 1 + sizeof(void*));
    if (!ptr) {
        return ENOMEM;
    }

    // Align the pointer
    void *aligned = (void*)(((uintptr_t)ptr + sizeof(void*) + alignment - 1) & ~(alignment - 1));
    // Store the original pointer just before the aligned pointer
    ((void**)aligned)[-1] = ptr;
    *memptr = aligned;
    return 0;
}

// _getentropy - entropy source for random number generation
// On embedded systems without a TRNG, we provide a simple fallback
int _getentropy(void *buffer, size_t length) {
    // Use timer as a source of pseudo-randomness
    // This is NOT cryptographically secure, but sufficient for non-crypto Swift code
    uint8_t *buf = (uint8_t*)buffer;
    uint32_t seed = timer_read32();

    for (size_t i = 0; i < length; i++) {
        // Simple LCG for pseudo-random bytes
        seed = seed * 1103515245 + 12345;
        buf[i] = (seed >> 16) & 0xFF;
    }

    return 0;
}
