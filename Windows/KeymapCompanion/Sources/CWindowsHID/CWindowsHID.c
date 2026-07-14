#include "CWindowsHID.h"

#include <windows.h>
#include <hidsdi.h>
#include <setupapi.h>
#include <stdlib.h>
#include <string.h>

struct keymap_hid_handle {
    HANDLE file;
    uint16_t input_report_length;
    uint16_t output_report_length;
    volatile LONG cancelled;
};

static int keymap_hid_get_caps(const wchar_t *path, HIDP_CAPS *caps) {
    HANDLE file = CreateFileW(
        path,
        0,
        FILE_SHARE_READ | FILE_SHARE_WRITE,
        NULL,
        OPEN_EXISTING,
        0,
        NULL
    );
    if (file == INVALID_HANDLE_VALUE) {
        return 0;
    }

    PHIDP_PREPARSED_DATA preparsed = NULL;
    int succeeded = HidD_GetPreparsedData(file, &preparsed)
        && HidP_GetCaps(preparsed, caps) == HIDP_STATUS_SUCCESS;
    if (preparsed != NULL) {
        HidD_FreePreparsedData(preparsed);
    }
    CloseHandle(file);
    return succeeded;
}

size_t keymap_hid_enumerate(
    uint16_t usage_page,
    uint16_t usage,
    keymap_hid_enumeration_callback callback,
    void *context
) {
    GUID hid_guid;
    HidD_GetHidGuid(&hid_guid);
    HDEVINFO device_info = SetupDiGetClassDevsW(
        &hid_guid,
        NULL,
        NULL,
        DIGCF_PRESENT | DIGCF_DEVICEINTERFACE
    );
    if (device_info == INVALID_HANDLE_VALUE) {
        return 0;
    }

    size_t matches = 0;
    for (DWORD index = 0; ; ++index) {
        SP_DEVICE_INTERFACE_DATA interface_data;
        memset(&interface_data, 0, sizeof(interface_data));
        interface_data.cbSize = sizeof(interface_data);
        if (!SetupDiEnumDeviceInterfaces(
                device_info,
                NULL,
                &hid_guid,
                index,
                &interface_data)) {
            break;
        }

        DWORD required_size = 0;
        SetupDiGetDeviceInterfaceDetailW(
            device_info,
            &interface_data,
            NULL,
            0,
            &required_size,
            NULL
        );
        PSP_DEVICE_INTERFACE_DETAIL_DATA_W detail = malloc(required_size);
        if (detail == NULL) {
            continue;
        }
        detail->cbSize = sizeof(*detail);
        if (!SetupDiGetDeviceInterfaceDetailW(
                device_info,
                &interface_data,
                detail,
                required_size,
                NULL,
                NULL)) {
            free(detail);
            continue;
        }

        HIDP_CAPS caps;
        memset(&caps, 0, sizeof(caps));
        if (keymap_hid_get_caps(detail->DevicePath, &caps)
                && caps.UsagePage == usage_page
                && caps.Usage == usage) {
            ++matches;
            if (callback != NULL) {
                callback(
                    detail->DevicePath,
                    caps.InputReportByteLength,
                    caps.OutputReportByteLength,
                    context
                );
            }
        }
        free(detail);
    }

    SetupDiDestroyDeviceInfoList(device_info);
    return matches;
}

keymap_hid_handle *keymap_hid_open(
    const wchar_t *path,
    uint16_t input_report_length,
    uint16_t output_report_length
) {
    HANDLE file = CreateFileW(
        path,
        GENERIC_READ | GENERIC_WRITE,
        FILE_SHARE_READ | FILE_SHARE_WRITE,
        NULL,
        OPEN_EXISTING,
        0,
        NULL
    );
    if (file == INVALID_HANDLE_VALUE) {
        return NULL;
    }

    keymap_hid_handle *handle = calloc(1, sizeof(*handle));
    if (handle == NULL) {
        CloseHandle(file);
        return NULL;
    }
    handle->file = file;
    handle->input_report_length = input_report_length;
    handle->output_report_length = output_report_length;
    return handle;
}

int32_t keymap_hid_read_report(
    keymap_hid_handle *handle,
    uint8_t *report,
    uint32_t report_length
) {
    if (handle == NULL || report == NULL || report_length == 0) {
        return -1;
    }
    uint32_t wire_length = handle->input_report_length;
    if (wire_length < report_length || wire_length > 1024) {
        return -1;
    }
    uint8_t *wire_report = calloc(wire_length, 1);
    if (wire_report == NULL) {
        return -1;
    }

    DWORD bytes_read = 0;
    BOOL succeeded = ReadFile(
        handle->file,
        wire_report,
        wire_length,
        &bytes_read,
        NULL
    );
    if (!succeeded) {
        DWORD error = GetLastError();
        free(wire_report);
        return error == ERROR_OPERATION_ABORTED ? -2 : -1;
    }

    if (bytes_read == report_length + 1 && wire_report[0] == 0) {
        memcpy(report, wire_report + 1, report_length);
    } else if (bytes_read >= report_length) {
        memcpy(report, wire_report, report_length);
    } else {
        free(wire_report);
        return -1;
    }
    free(wire_report);
    return (int32_t)report_length;
}

int32_t keymap_hid_write_report(
    keymap_hid_handle *handle,
    const uint8_t *report,
    uint32_t report_length
) {
    if (handle == NULL || report == NULL || report_length == 0) {
        return -1;
    }
    uint32_t wire_length = handle->output_report_length;
    if (wire_length < report_length || wire_length > 1024) {
        return -1;
    }
    uint8_t *wire_report = calloc(wire_length, 1);
    if (wire_report == NULL) {
        return -1;
    }
    uint32_t offset = wire_length == report_length + 1 ? 1 : 0;
    memcpy(wire_report + offset, report, report_length);

    DWORD bytes_written = 0;
    BOOL succeeded = WriteFile(
        handle->file,
        wire_report,
        wire_length,
        &bytes_written,
        NULL
    );
    free(wire_report);
    return succeeded && bytes_written == wire_length ? (int32_t)report_length : -1;
}

void keymap_hid_cancel(keymap_hid_handle *handle) {
    if (handle == NULL || InterlockedExchange(&handle->cancelled, 1) != 0) {
        return;
    }
    CancelIoEx(handle->file, NULL);
}

void keymap_hid_destroy(keymap_hid_handle *handle) {
    if (handle == NULL) {
        return;
    }
    CloseHandle(handle->file);
    free(handle);
}
