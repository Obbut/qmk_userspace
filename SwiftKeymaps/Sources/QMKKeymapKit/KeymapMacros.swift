/// Creates a validated, domain-typed keymap while preserving a declarative call site.
///
/// - Parameters:
///   - id: The stable keymap identifier.
///   - layout: The keyboard layout and physical geometry.
///   - content: Layers, encoders, and reusable components.
/// - Returns: The validated keymap specification.
@freestanding(expression)
public macro Keymap<Domain: KeymapDomain>(
    id: String,
    layout: LayoutDescriptor,
    @KeymapBuilder<Domain> _ content: () -> [KeymapElement<Domain>]
) -> KeymapSpec<Domain> = #externalMacro(
    module: "QMKKeymapMacrosPlugin",
    type: "KeymapMacro"
)

/// Imports a fork-specific or custom QMK keycode as a domain-typed key.
///
/// The macro captures the first argument as a trusted token without requiring a
/// matching host declaration, while the generated QMK boundary validates it.
///
/// - Parameters:
///   - expression: A QMK keycode token or expression.
///   - legend: The renderer legend.
///   - semantic: An optional domain-owned semantic identifier.
///   - style: An optional domain-owned visual style.
/// - Returns: A domain-typed key.
@freestanding(expression)
public macro qmkKeycode<Domain: KeymapDomain>(
    _ expression: QMKToken,
    legend: String,
    semantic: Domain.Semantic? = nil,
    style: Domain.Style? = nil
) -> Key<Domain> = #externalMacro(
    module: "QMKKeymapMacrosPlugin",
    type: "QMKKeycodeMacro"
)
