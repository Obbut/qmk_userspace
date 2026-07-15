import KeymapCompanionCore
import WinUI

/// The retained native elements and state for one encoder.
struct RenderedEncoder {
    /// The firmware-owned encoder-press mappings.
    let pressKey: KeymapKey

    /// The encoder's native knob element.
    let knob: Border

    /// The encoder-press native label element.
    let pressLabel: TextBlock

    /// The press legend represented by the native elements.
    var pressLegend: KeyLegend?

    /// The retained counterclockwise action.
    var counterclockwise: RenderedEncoderAction

    /// The retained clockwise action.
    var clockwise: RenderedEncoderAction
}
