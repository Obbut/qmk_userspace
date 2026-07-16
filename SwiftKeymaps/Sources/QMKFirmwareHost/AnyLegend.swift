import QMKKeymapKit

/// A key legend paired with its deterministic firmware wire identifier.
public struct AnyLegend: Equatable, Sendable {
    /// The compact identifier emitted to firmware and companion traffic.
    public let id: UInt16

    /// The renderer label.
    public let label: String

    /// A renderer-neutral symbol inferred from the label when one is unambiguous.
    public var symbolName: String? {
        switch label {
        case "Screenshot": "camera"
        case "Aerospace": "window-management"
        case "Drag Lock": "locked-pointer"
        case "Bluetooth 1", "Bluetooth 2", "Bluetooth 3": "bluetooth"
        case "Battery": "battery"
        case "Left Click", "Right Click", "Middle Click": "pointer-button"
        case "Pointer −", "Pointer +", "Sniper": "pointer"
        case "Scroll", "Scroll −", "Scroll +": "scroll"
        case "Browser Back", "Browser Forward": "browser-navigation"
        case "2.4 GHz": "wireless"
        default: nil
        }
    }

    /// Pairs a source legend with its generated wire identifier.
    ///
    /// - Parameters:
    ///   - id: The nonzero generated wire identifier.
    ///   - legend: A legend referenced by the keymap.
    public init(id: UInt16, legend: StaticString) {
        precondition(id != 0, "Legend wire identifier zero is reserved for no legend.")
        self.id = id
        label = StaticStringContent.string(legend)
    }
}
