import KeymapCompanionCore
import WinUI

/// The retained native elements and state for one visible switch.
struct RenderedKey {
    /// The firmware-owned layer mappings.
    let key: KeymapKey

    /// The switch's native border element.
    let border: Border

    /// The switch's native label element.
    let label: TextBlock

    /// The legend represented by the native elements.
    var legend: KeyLegend?

    /// Whether the highest active layer directly maps the switch.
    var isDirectlyMapped: Bool?
}
