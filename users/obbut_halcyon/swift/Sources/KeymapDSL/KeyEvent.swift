// Key event data structures for QMK keyboard firmware
// SPDX-License-Identifier: GPL-2.0-or-later

/// Key event data matching QMK's keyrecord_t
public struct KeyEvent {
    /// Whether the key was pressed (true) or released (false)
    public let pressed: Bool

    /// Matrix row of the key
    public let row: UInt8

    /// Matrix column of the key
    public let col: UInt8

    public init(pressed: Bool, row: UInt8, col: UInt8) {
        self.pressed = pressed
        self.row = row
        self.col = col
    }
}

// MARK: - OS Detection

/// Detected operating system (matches QMK's os_variant_t)
public enum DetectedOS: UInt8 {
    case unsure = 0
    case linux = 1
    case windows = 2
    case macos = 3
    case ios = 4

    /// Check if the detected OS is Windows
    public var isWindows: Bool {
        self == .windows
    }

    /// Check if the detected OS is macOS
    public var isMacOS: Bool {
        self == .macos
    }

    /// Check if the detected OS is Apple (macOS or iOS)
    public var isApple: Bool {
        self == .macos || self == .ios
    }
}

// MARK: - RGB Color

/// RGB color value
public struct RGB: Equatable {
    public let r: UInt8
    public let g: UInt8
    public let b: UInt8

    public init(r: UInt8, g: UInt8, b: UInt8) {
        self.r = r
        self.g = g
        self.b = b
    }

    // Common colors
    public static let off = RGB(r: 0, g: 0, b: 0)
    public static let white = RGB(r: 255, g: 255, b: 255)
    public static let red = RGB(r: 255, g: 68, b: 68)
    public static let green = RGB(r: 0, g: 255, b: 0)
    public static let darkGreen = RGB(r: 0, g: 50, b: 0)
    public static let blue = RGB(r: 0, g: 0, b: 255)
    public static let cyan = RGB(r: 0, g: 220, b: 220)
    public static let magenta = RGB(r: 255, g: 0, b: 255)
    public static let yellow = RGB(r: 255, g: 255, b: 0)
    public static let orange = RGB(r: 255, g: 128, b: 0)
    public static let purple = RGB(r: 148, g: 0, b: 211)
}
