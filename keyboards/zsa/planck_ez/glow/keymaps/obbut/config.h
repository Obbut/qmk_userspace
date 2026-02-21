// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

// Fix layer-tap delay: activate hold when another key is tapped while holding
#define PERMISSIVE_HOLD

// Turn off RGB after 5 minutes of inactivity (300000ms)
#undef RGB_MATRIX_TIMEOUT
#define RGB_MATRIX_TIMEOUT 300000

// Map layer indicator LEDs to our layer numbers
#define PLANCK_EZ_LED_LOWER 2    // _LOWER
#define PLANCK_EZ_LED_RAISE 3    // _RAISE
#define PLANCK_EZ_LED_ADJUST 4   // _FUNCTION

// Tri-layer: holding Lower + Raise activates Function
#define TRI_LAYER_LOWER_LAYER 2  // _LOWER
#define TRI_LAYER_UPPER_LAYER 3  // _RAISE
#define TRI_LAYER_ADJUST_LAYER 4 // _FUNCTION
