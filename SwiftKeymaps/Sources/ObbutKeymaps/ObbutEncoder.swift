import QMKKeymapKit

/// Reusable encoder maps for Obbut keyboards.
public enum ObbutEncoder {
    /// Creates the shared Halcyon encoder map.
    ///
    /// - Parameter includesPointerLayer: Whether the Kyria pointer layer is present.
    /// - Returns: The right encoder's complete layer map.
    public static func halcyon(includesPointerLayer: Bool) -> Encoder<ObbutKeymapDomain> {
        Encoder(0, id: "right") {
            On(ObbutLayer.base, counterclockwise: .keyboardVolumeDown, clockwise: .keyboardVolumeUp)
            On(ObbutLayer.qwerty, counterclockwise: .keyboardVolumeDown, clockwise: .keyboardVolumeUp)
            On(ObbutLayer.lower, counterclockwise: .previousTrack, clockwise: .nextTrack)
            On(ObbutLayer.raise, counterclockwise: .keyboardVolumeDown, clockwise: .keyboardVolumeUp)
            On(
                ObbutLayer.function,
                counterclockwise: .qmk("RM_PREV", legend: "Previous", style: .decrease),
                clockwise: .qmk("RM_NEXT", legend: "Next", style: .increase)
            )
            if includesPointerLayer {
                On(ObbutLayer.pointer, counterclockwise: .keyboardVolumeDown, clockwise: .keyboardVolumeUp)
            }
        }
    }
}
