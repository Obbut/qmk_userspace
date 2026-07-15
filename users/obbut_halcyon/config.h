// Shared config for Obbut's Halcyon keyboards (Kyria, Elora)
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

// Define user transaction ID for syncing RGB preview mode between halves
#define SPLIT_TRANSACTION_IDS_USER USER_SYNC_RGB_PREVIEW

// Turn off RGB after 5 minutes of inactivity (300000ms)
#define RGB_MATRIX_TIMEOUT 300000

#if defined(KEYBOARD_splitkb_halcyon_kyria_rev4)
// Activate the Kyria pointer layer automatically from Cirque input.
#    define POINTING_DEVICE_AUTO_MOUSE_ENABLE
#    define AUTO_MOUSE_DEFAULT_LAYER 5
#    define AUTO_MOUSE_TIME 650
#    define AUTO_MOUSE_DELAY 200
#    define AUTO_MOUSE_DEBOUNCE 25
#    define AUTO_MOUSE_THRESHOLD 10
#endif
