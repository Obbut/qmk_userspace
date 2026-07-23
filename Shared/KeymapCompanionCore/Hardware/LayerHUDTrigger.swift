/// A firmware-authorized request to reveal the layer HUD for one state snapshot.
public struct LayerHUDTrigger: Equatable, Sendable {
    /// The keyboard layout that produced the trigger.
    public let layoutID: LayoutID

    /// The nonpersistent QMK layer-state mask at the reveal deadline.
    public let layerStateMask: UInt32

    /// The persistent QMK default-layer-state mask at the reveal deadline.
    public let defaultLayerStateMask: UInt32

    /// Creates a validated layer-HUD trigger.
    ///
    /// - Parameters:
    ///   - layoutID: The keyboard layout that produced the trigger.
    ///   - layerStateMask: The nonpersistent QMK layer-state mask.
    ///   - defaultLayerStateMask: The persistent QMK default-layer-state mask.
    init(
        layoutID: LayoutID,
        layerStateMask: UInt32,
        defaultLayerStateMask: UInt32
    ) {
        self.layoutID = layoutID
        self.layerStateMask = layerStateMask
        self.defaultLayerStateMask = defaultLayerStateMask
    }

    /// The union of momentary and default firmware layer masks.
    public var effectiveLayerMask: UInt32 {
        layerStateMask | defaultLayerStateMask
    }
}
