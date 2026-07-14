// Shared stable RGB effect identifiers.
// SPDX-License-Identifier: GPL-2.0-or-later

extension KeymapProtocol {
    /// A stable identifier for one supported QMK RGB Matrix effect.
    public enum RGBEffect: UInt8, CaseIterable, Equatable, Hashable, Sendable {
        /// A uniform color across the keyboard.
        case solidColor = 1
        /// Separate colors for alphanumeric and modifier keys.
        case alphasAndModifiers = 2
        /// A vertical color gradient.
        case verticalGradient = 3
        /// A horizontal color gradient.
        case horizontalGradient = 4
        /// A color that repeatedly fades in and out.
        case breathing = 5
        /// Moving saturation bands.
        case saturationBands = 6
        /// Moving color bands.
        case colorBands = 7
        /// Pinwheel-shaped saturation bands.
        case pinwheelSaturation = 8
        /// Pinwheel-shaped color bands.
        case pinwheel = 9
        /// Spiral-shaped saturation bands.
        case spiralSaturation = 10
        /// Spiral-shaped color bands.
        case spiral = 11
        /// A rainbow cycling across every key together.
        case rainbowCycle = 12
        /// A rainbow traveling horizontally.
        case rainbowLeftToRight = 13
        /// A rainbow traveling vertically.
        case rainbowUpAndDown = 14
        /// A moving rainbow chevron.
        case movingChevron = 15
        /// A rainbow cycling outward and inward.
        case cycleOutAndIn = 16
        /// Two mirrored rainbows cycling outward and inward.
        case dualCycleOutAndIn = 17
        /// A rotating rainbow pinwheel.
        case pinwheelCycle = 18
        /// A rotating rainbow spiral.
        case spiralCycle = 19
        /// Two rotating color beacons.
        case dualBeacon = 20
        /// A rotating rainbow beacon.
        case rainbowBeacon = 21
        /// Multiple rotating rainbow pinwheels.
        case rainbowPinwheels = 22
        /// Random drops derived from the selected color.
        case raindrops = 23
        /// Random drops spanning the full color range.
        case jellybeanRaindrops = 24
        /// A breathing animation that also shifts hue.
        case hueBreathing = 25
        /// A hue that swings back and forth.
        case huePendulum = 26
        /// A traveling hue wave.
        case hueWave = 27
        /// Random colored pixels falling like rain.
        case pixelRain = 28
        /// Colored pixels flowing across the keyboard.
        case pixelFlow = 29
        /// A shifting colored fractal.
        case pixelFractal = 30
    }
}
