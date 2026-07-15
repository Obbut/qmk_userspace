/// A validated keyboard-state packet received from QMK.
public struct KeyboardStateReport: Equatable, Sendable {
    /// The keyboard layout that produced the report.
    public let layoutID: LayoutID

    /// The nonpersistent QMK layer-state mask.
    public let layerStateMask: UInt32

    /// The persistent QMK default-layer-state mask.
    public let defaultLayerStateMask: UInt32

    /// The monotonically increasing firmware sequence number.
    public let sequence: UInt32

    /// The protocol capabilities advertised by the firmware.
    public let capabilities: UInt32

    /// The reported lighting configuration, when supported.
    public let rgbSettings: RGBSettings?

    /// Creates a validated keyboard-state report.
    ///
    /// - Parameters:
    ///   - layoutID: The keyboard layout that produced the report.
    ///   - layerStateMask: The nonpersistent QMK layer-state mask.
    ///   - defaultLayerStateMask: The persistent QMK default-layer-state mask.
    ///   - sequence: The monotonically increasing firmware sequence number.
    ///   - capabilities: The protocol capabilities advertised by the firmware.
    ///   - rgbSettings: The reported lighting configuration, when supported.
    init(
        layoutID: LayoutID,
        layerStateMask: UInt32,
        defaultLayerStateMask: UInt32,
        sequence: UInt32,
        capabilities: UInt32,
        rgbSettings: RGBSettings?
    ) {
        self.layoutID = layoutID
        self.layerStateMask = layerStateMask
        self.defaultLayerStateMask = defaultLayerStateMask
        self.sequence = sequence
        self.capabilities = capabilities
        self.rgbSettings = rgbSettings
    }

    /// The effective QMK layer mask used to resolve transparent mappings.
    public var effectiveLayerMask: UInt32 {
        layerStateMask | defaultLayerStateMask
    }
}
