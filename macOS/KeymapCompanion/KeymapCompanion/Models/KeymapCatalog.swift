/// Static keymap definitions mirrored from the QMK and keymap-drawer sources.
enum KeymapCatalog {
    /// The Kyria definition, built once and shared by every view update.
    static let kyria = makeDefinition(for: .kyria)

    /// The Elora definition, built once and shared by every view update.
    static let elora = makeDefinition(for: .elora)

    /// Returns the cached keymap for a keyboard model.
    /// - Parameter keyboardKind: The keyboard model to display.
    /// - Returns: The matching cached definition.
    static func definition(for keyboardKind: KeyboardKind) -> KeymapDefinition {
        switch keyboardKind {
        case .kyria:
            kyria
        case .elora:
            elora
        }
    }

    /// Builds the visual rows shared by the two Halcyon boards.
    /// - Parameter keyboardKind: The board whose physical rows should be included.
    /// - Returns: A complete keymap definition.
    private static func makeDefinition(for keyboardKind: KeyboardKind) -> KeymapDefinition {
        var rows: [KeymapRow] = []

        if keyboardKind == .elora {
            rows.append(
                KeymapRow(
                    id: "numbers",
                    leftKeys: [
                        makeKey(id: "n-l0", base: "`"),
                        makeKey(id: "n-l1", base: "1"),
                        makeKey(id: "n-l2", base: "2"),
                        makeKey(id: "n-l3", base: "3"),
                        makeKey(id: "n-l4", base: "4"),
                        makeKey(id: "n-l5", base: "5")
                    ],
                    rightKeys: [
                        makeKey(id: "n-r0", base: "6"),
                        makeKey(id: "n-r1", base: "7"),
                        makeKey(id: "n-r2", base: "8"),
                        makeKey(id: "n-r3", base: "9"),
                        makeKey(id: "n-r4", base: "0"),
                        makeKey(id: "n-r5", base: "-")
                    ],
                    isThumbRow: false
                )
            )
        }

        rows.append(contentsOf: [
            KeymapRow(
                id: "alpha-top",
                leftKeys: [
                    makeKey(id: "a1-l0", base: "TAB", raise: makeLegend("`", style: .yellow)),
                    makeKey(id: "a1-l1", base: "Q", raise: makeLegend("!", style: .yellow), function: makeLegend("F11", style: .cyan)),
                    makeKey(id: "a1-l2", base: "W", qwerty: makeLegend("W", style: .purple), raise: makeLegend("@", style: .yellow), function: makeLegend("F12", style: .cyan)),
                    makeKey(id: "a1-l3", base: "F", qwerty: makeLegend("E"), raise: makeLegend("[", style: .yellow), function: makeLegend("F13", style: .cyan)),
                    makeKey(id: "a1-l4", base: "P", qwerty: makeLegend("R"), raise: makeLegend("]", style: .yellow), function: makeLegend("F14", style: .cyan)),
                    makeKey(id: "a1-l5", base: "B", qwerty: makeLegend("T"), function: makeLegend("F15", style: .cyan))
                ],
                rightKeys: [
                    makeKey(id: "a1-r0", base: "J", qwerty: makeLegend("Y"), raise: makeLegend(":", style: .yellow)),
                    makeKey(id: "a1-r1", base: "L", qwerty: makeLegend("U"), raise: makeLegend("7", style: .blue)),
                    makeKey(id: "a1-r2", base: "U", qwerty: makeLegend("I"), raise: makeLegend("8", style: .blue)),
                    makeKey(id: "a1-r3", base: "Y", qwerty: makeLegend("O"), raise: makeLegend("9", style: .blue)),
                    makeKey(id: "a1-r4", base: ";", qwerty: makeLegend("P"), lower: makeLegend("DEL", style: .orange), raise: makeLegend("-", style: .yellow)),
                    makeKey(id: "a1-r5", base: "BSPC", lower: makeLegend("BSPC", style: .orange))
                ],
                isThumbRow: false
            ),
            KeymapRow(
                id: "alpha-home",
                leftKeys: [
                    makeKey(id: "a2-l0", base: "ESC", function: makeLegend("Boot", style: .red)),
                    makeKey(id: "a2-l1", base: "A", qwerty: makeLegend("A", style: .purple), raise: makeLegend("#", style: .yellow), function: makeLegend("F6", style: .cyan)),
                    makeKey(id: "a2-l2", base: "R", qwerty: makeLegend("S", style: .purple), raise: makeLegend("$", style: .yellow), function: makeLegend("F7", style: .cyan)),
                    makeKey(id: "a2-l3", base: "S", qwerty: makeLegend("D", style: .purple), raise: makeLegend("(", style: .yellow), function: makeLegend("F8", style: .cyan)),
                    makeKey(id: "a2-l4", base: "T", qwerty: makeLegend("F"), raise: makeLegend(")", style: .yellow), function: makeLegend("F9", style: .cyan)),
                    makeKey(id: "a2-l5", base: "G", raise: makeLegend(":", style: .yellow), function: makeLegend("F10", style: .cyan))
                ],
                rightKeys: [
                    makeKey(id: "a2-r0", base: "M", qwerty: makeLegend("H"), lower: makeLegend("←", style: .magenta), function: makeLegend("RGB", style: .green)),
                    makeKey(id: "a2-r1", base: "N", qwerty: makeLegend("J"), lower: makeLegend("↓", style: .magenta), raise: makeLegend("4", style: .blue), function: makeLegend("Sat+", style: .green)),
                    makeKey(id: "a2-r2", base: "E", qwerty: makeLegend("K"), lower: makeLegend("↑", style: .magenta), raise: makeLegend("5", style: .blue), function: makeLegend("Hue+", style: .green)),
                    makeKey(id: "a2-r3", base: "I", qwerty: makeLegend("L"), lower: makeLegend("→", style: .magenta), raise: makeLegend("6", style: .blue), function: makeLegend("Brt+", style: .green)),
                    makeKey(id: "a2-r4", base: "O", qwerty: makeLegend(";"), raise: makeLegend("+", style: .yellow), function: makeLegend("Next", style: .green)),
                    makeKey(id: "a2-r5", base: "'", raise: makeLegend("=", style: .yellow), function: makeLegend("Boot", style: .red))
                ],
                isThumbRow: false
            ),
            KeymapRow(
                id: "alpha-bottom",
                leftKeys: [
                    makeKey(id: "a3-l0", base: "LSFT"),
                    makeKey(id: "a3-l1", base: "Z", raise: makeLegend("%", style: .yellow), function: makeLegend("F1", style: .cyan)),
                    makeKey(id: "a3-l2", base: "X", raise: makeLegend("^", style: .yellow), function: makeLegend("F2", style: .cyan)),
                    makeKey(id: "a3-l3", base: "C", raise: makeLegend("{", style: .yellow), function: makeLegend("F3", style: .cyan)),
                    makeKey(id: "a3-l4", base: "D", qwerty: makeLegend("V"), raise: makeLegend("}", style: .yellow), function: makeLegend("F4", style: .cyan)),
                    makeKey(id: "a3-l5", base: "V", qwerty: makeLegend("B"), function: makeLegend("F5", style: .cyan)),
                    makeKey(id: "a3-l6", base: "OPT"),
                    makeKey(
                        id: "a3-l7",
                        base: keyboardKind == .elora ? "QWERTY" : "Click",
                        baseStyle: keyboardKind == .elora ? .purple : .standard,
                        qwerty: keyboardKind == .elora ? makeLegend("Default", style: .purple) : nil,
                        function: makeLegend("QWERTY", style: .purple)
                    )
                ],
                rightKeys: [
                    makeKey(id: "a3-rm0", base: "Fn"),
                    makeKey(id: "a3-rm1", base: ""),
                    makeKey(id: "a3-r0", base: "K", qwerty: makeLegend("N"), raise: makeLegend("0", style: .blue)),
                    makeKey(id: "a3-r1", base: "H", qwerty: makeLegend("M"), raise: makeLegend("1", style: .blue), function: makeLegend("Sat-", style: .darkGreen)),
                    makeKey(id: "a3-r2", base: ",", raise: makeLegend("2", style: .blue), function: makeLegend("Hue-", style: .darkGreen)),
                    makeKey(id: "a3-r3", base: ".", raise: makeLegend("3", style: .blue), function: makeLegend("Brt-", style: .darkGreen)),
                    makeKey(id: "a3-r4", base: "/", raise: makeLegend(".", style: .yellow), function: makeLegend("Prev", style: .darkGreen)),
                    makeKey(id: "a3-r5", base: "ENT", raise: makeLegend("\\", style: .yellow))
                ],
                isThumbRow: false
            ),
            KeymapRow(
                id: "thumbs",
                leftKeys: [
                    makeKey(id: "t-l0", base: "Screenshot", qwerty: makeLegend("LCTL", style: .purple)),
                    makeKey(id: "t-l1", base: "LCTL", qwerty: makeLegend("LALT", style: .purple)),
                    makeKey(id: "t-l2", base: "LGUI", qwerty: makeLegend("SPC", style: .purple)),
                    makeKey(id: "t-l3", base: "Aerospace", qwerty: makeLegend("SPC", style: .purple)),
                    makeKey(id: "t-l4", base: "SPC", qwerty: makeLegend("SPC", style: .purple))
                ],
                rightKeys: [
                    makeKey(id: "t-r0", base: ""),
                    makeKey(id: "t-r1", base: "SPC"),
                    makeKey(id: "t-r2", base: "Raise"),
                    makeKey(id: "t-r3", base: "Lower"),
                    makeKey(id: "t-r4", base: "")
                ],
                isThumbRow: true
            )
        ])

        return KeymapDefinition(keyboardKind: keyboardKind, rows: rows)
    }

    /// Creates a legend while keeping the catalog declarations compact.
    /// - Parameters:
    ///   - label: The technical key label.
    ///   - style: The RGB-inspired visual category.
    /// - Returns: A key legend.
    private static func makeLegend(_ label: String, style: KeyStyle = .standard) -> KeyLegend {
        KeyLegend(label: label, style: style)
    }

    /// Creates a physical key from optional per-layer mappings.
    /// - Parameters:
    ///   - id: Stable physical-position identity.
    ///   - base: The base-layer label.
    ///   - baseStyle: The base-layer visual category.
    ///   - qwerty: An optional QWERTY override.
    ///   - lower: An optional Lower override.
    ///   - raise: An optional Raise override.
    ///   - function: An optional Function override.
    /// - Returns: A keymap key whose missing overrides are transparent.
    private static func makeKey(
        id: String,
        base: String,
        baseStyle: KeyStyle = .standard,
        qwerty: KeyLegend? = nil,
        lower: KeyLegend? = nil,
        raise: KeyLegend? = nil,
        function: KeyLegend? = nil
    ) -> KeymapKey {
        var overrides: [KeymapLayer: KeyLegend] = [:]
        overrides[.qwerty] = qwerty
        overrides[.lower] = lower
        overrides[.raise] = raise
        overrides[.function] = function
        return KeymapKey(
            id: id,
            baseLegend: KeyLegend(label: base, style: baseStyle),
            overrides: overrides
        )
    }
}
