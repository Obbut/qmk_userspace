/// One matrix entry downloaded from keyboard firmware.
public struct FirmwareKeymapEntry: Equatable, Sendable {
    public let keycode: UInt16
    public let semantic: UInt8
    public let style: KeyStyle

    public init(keycode: UInt16, semantic: UInt8, style: KeyStyle) {
        self.keycode = keycode
        self.semantic = semantic
        self.style = style
    }
}

/// A validated keyboard-state packet received from QMK.
public struct KeyboardStateReport: Equatable, Sendable {
    public let keyboardKind: KeyboardKind
    public let layerStateMask: UInt32
    public let defaultLayerStateMask: UInt32
    public let sequence: UInt32
    public let capabilities: UInt32
    public let rgbSettings: RGBSettings?

    public init(
        keyboardKind: KeyboardKind,
        layerStateMask: UInt32,
        defaultLayerStateMask: UInt32,
        sequence: UInt32,
        capabilities: UInt32,
        rgbSettings: RGBSettings?
    ) {
        self.keyboardKind = keyboardKind
        self.layerStateMask = layerStateMask
        self.defaultLayerStateMask = defaultLayerStateMask
        self.sequence = sequence
        self.capabilities = capabilities
        self.rgbSettings = rgbSettings
    }

    public var effectiveLayerMask: UInt32 {
        layerStateMask | defaultLayerStateMask
    }
}

/// Metadata that starts a firmware keymap transfer.
public struct KeymapMetadataReport: Equatable, Sendable {
    public let keyboardKind: KeyboardKind
    public let layerCount: Int
    public let matrixRowCount: Int
    public let matrixColumnCount: Int
    public let entrySize: Int
    public let entriesPerChunk: Int
    public let fingerprint: UInt32
    public let entryCount: Int
    public let encoderCount: Int

    public init(
        keyboardKind: KeyboardKind,
        layerCount: Int,
        matrixRowCount: Int,
        matrixColumnCount: Int,
        entrySize: Int,
        entriesPerChunk: Int,
        fingerprint: UInt32,
        entryCount: Int,
        encoderCount: Int
    ) {
        self.keyboardKind = keyboardKind
        self.layerCount = layerCount
        self.matrixRowCount = matrixRowCount
        self.matrixColumnCount = matrixColumnCount
        self.entrySize = entrySize
        self.entriesPerChunk = entriesPerChunk
        self.fingerprint = fingerprint
        self.entryCount = entryCount
        self.encoderCount = encoderCount
    }
}

/// One ordered page of firmware keymap entries.
public struct KeymapChunkReport: Equatable, Sendable {
    public let keyboardKind: KeyboardKind
    public let startIndex: Int
    public let totalEntryCount: Int
    public let entries: [FirmwareKeymapEntry]

    public init(
        keyboardKind: KeyboardKind,
        startIndex: Int,
        totalEntryCount: Int,
        entries: [FirmwareKeymapEntry]
    ) {
        self.keyboardKind = keyboardKind
        self.startIndex = startIndex
        self.totalEntryCount = totalEntryCount
        self.entries = entries
    }
}
