import KeymapCompanionCore
import WinUI

/// The retained native elements and state for one encoder-turn action.
struct RenderedEncoderAction {
    /// The platform turn-direction glyph.
    let arrow: String

    /// The firmware-owned layer mappings.
    let key: KeymapKey

    /// The action's native border element.
    let border: Border

    /// The action's native label element.
    let label: TextBlock

    /// The legend represented by the native elements.
    var legend: KeyLegend?

    /// Whether the highest active layer directly maps the action.
    var isDirectlyMapped: Bool?
}
