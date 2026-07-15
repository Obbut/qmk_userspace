/// Builder output containing a firmware's layer and encoder declarations.
public struct Keymap: Sendable {
    let elements: [KeymapElement]

    init(elements: [KeymapElement]) {
        self.elements = elements
    }
}
