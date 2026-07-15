import QMKKeymapKit

/// Reusable encoder maps for Obbut keyboards.
public enum ObbutEncoder {
    /// Uses the pointer-layer mapping only on Kyria.
    ///
    /// - Parameter includesPointerLayer: Whether the Kyria pointer layer is present.
    /// - Returns: The right encoder's mappings in layer order.
    public static func halcyon(includesPointerLayer: Bool) -> Encoder {
        Encoder(0, id: "right") {
            On(ObbutLayer.base, counterclockwise: .keyboardVolumeDown, clockwise: .keyboardVolumeUp)
            On(ObbutLayer.qwerty, counterclockwise: .keyboardVolumeDown, clockwise: .keyboardVolumeUp)
            On(ObbutLayer.lower, counterclockwise: .previousTrack, clockwise: .nextTrack)
            On(ObbutLayer.raise, counterclockwise: .keyboardVolumeDown, clockwise: .keyboardVolumeUp)
            On(
                ObbutLayer.function,
                counterclockwise: .qmk("RM_PREV", legend: "Previous").style(.decrease),
                clockwise: .qmk("RM_NEXT", legend: "Next").style(.increase)
            )
            if includesPointerLayer {
                On(ObbutLayer.pointer, counterclockwise: .keyboardVolumeDown, clockwise: .keyboardVolumeUp)
            }
        }
    }
}
