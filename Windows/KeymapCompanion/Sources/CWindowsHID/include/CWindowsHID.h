#pragma once

#include <stddef.h>
#include <stdint.h>
#include <wchar.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct keymap_hid_handle keymap_hid_handle;

typedef void (*keymap_hid_enumeration_callback)(
    const wchar_t *path,
    uint16_t input_report_length,
    uint16_t output_report_length,
    void *context
);

size_t keymap_hid_enumerate(
    uint16_t usage_page,
    uint16_t usage,
    keymap_hid_enumeration_callback callback,
    void *context
);

keymap_hid_handle *keymap_hid_open(
    const wchar_t *path,
    uint16_t input_report_length,
    uint16_t output_report_length
);

int32_t keymap_hid_read_report(
    keymap_hid_handle *handle,
    uint8_t *report,
    uint32_t report_length
);

int32_t keymap_hid_write_report(
    keymap_hid_handle *handle,
    const uint8_t *report,
    uint32_t report_length
);

void keymap_hid_cancel(keymap_hid_handle *handle);
void keymap_hid_destroy(keymap_hid_handle *handle);

#ifdef __cplusplus
}
#endif
