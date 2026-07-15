/// Builder output containing a firmware's layer and encoder declarations.
public struct Keymap<Domain: KeymapDomain>: Sendable {
    let elements: [KeymapElement<Domain>]

    init(elements: [KeymapElement<Domain>]) {
        self.elements = elements
    }
}
