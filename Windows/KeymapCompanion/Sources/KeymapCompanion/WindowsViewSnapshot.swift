import KeymapCompanionCore

/// The shared-model values that affect the Windows visual tree.
@MainActor
struct WindowsViewSnapshot: Equatable {
    /// The current hardware connection phase.
    let connectionStatus: ConnectionStatus

    /// The connected keyboard model.
    let layoutID: LayoutID?

    /// The downloaded renderer input.
    let keymapDefinition: KeymapDefinition?

    /// The union of active and default firmware layers.
    let effectiveLayerMask: UInt32

    /// Whether explicit RGB Matrix settings are available.
    let supportsRGBSettings: Bool

    /// The current RGB Matrix configuration.
    let rgbSettings: RGBSettings

    /// Creates a rendering snapshot from the shared model.
    ///
    /// - Parameter model: The shared observable source of truth.
    init(model: KeymapCompanionModel) {
        connectionStatus = model.connectionStatus
        layoutID = model.layoutID
        keymapDefinition = model.keymapDefinition
        effectiveLayerMask = model.effectiveLayerMask
        supportsRGBSettings = model.supportsRGBSettings
        rgbSettings = model.rgbSettings
    }
}
