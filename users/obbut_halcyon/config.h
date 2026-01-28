// Shared config for Obbut's Halcyon keyboards (Kyria, Elora)
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

// Define user transaction ID for syncing RGB preview mode between halves
#define SPLIT_TRANSACTION_IDS_USER USER_SYNC_RGB_PREVIEW

// Turn off RGB after 5 minutes of inactivity (300000ms)
#define RGB_MATRIX_TIMEOUT 300000

// Scroll speed tuning for drag scroll on Lower layer (lower = faster)
#define SCROLL_DIVISOR_H 32.0
#define SCROLL_DIVISOR_V 32.0

// Mouse cursor sensitivity (1.0 = default, lower = slower)
#define MOUSE_SENSITIVITY 0.67
