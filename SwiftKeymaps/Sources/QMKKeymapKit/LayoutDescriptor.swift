/// QMK ABI and physical geometry for one keyboard layout macro.
public struct LayoutDescriptor: Equatable, Sendable {
    /// The stable protocol layout identifier.
    public let id: String

    /// The user-facing keyboard name.
    public let displayName: String

    /// The QMK layout macro called by generated C.
    public let cMacro: String

    /// The number of keys accepted by the layout macro.
    public let keyCount: Int

    /// The complete QMK matrix row count.
    public let matrixRowCount: Int

    /// The QMK matrix column count.
    public let matrixColumnCount: Int

    /// Matrix coordinates in complete QMK layout-macro argument order.
    public let matrixMapping: [MatrixPosition]

    /// The renderer's logical canvas width.
    public let canvasWidth: Double

    /// The renderer's logical canvas height.
    public let canvasHeight: Double

    /// The visible matrix-key geometry.
    public let keys: [KeyPlacement]

    /// The zero, one, or more physical encoders.
    public let encoders: [EncoderPlacement]

    /// Creates a complete layout descriptor.
    ///
    /// - Parameters:
    ///   - id: The stable protocol layout identifier.
    ///   - displayName: The user-facing keyboard name.
    ///   - cMacro: The QMK layout macro called by generated C.
    ///   - keyCount: The number of keys accepted by the layout macro.
    ///   - matrixRowCount: The complete QMK matrix row count.
    ///   - matrixColumnCount: The QMK matrix column count.
    ///   - matrixMapping: Matrix coordinates for every layout-macro argument.
    ///   - canvasWidth: The renderer's logical canvas width.
    ///   - canvasHeight: The renderer's logical canvas height.
    ///   - keys: The visible matrix-key geometry.
    ///   - encoders: The physical encoders.
    public init(
        id: String,
        displayName: String,
        cMacro: String,
        keyCount: Int,
        matrixRowCount: Int,
        matrixColumnCount: Int,
        matrixMapping: [MatrixPosition],
        canvasWidth: Double,
        canvasHeight: Double,
        keys: [KeyPlacement],
        encoders: [EncoderPlacement]
    ) {
        precondition(!id.isEmpty && !cMacro.isEmpty, "Layout identifiers cannot be empty.")
        precondition(keyCount > 0, "A QMK layout must contain at least one key.")
        precondition(matrixRowCount > 0 && matrixColumnCount > 0, "Matrix dimensions must be positive.")
        precondition(matrixMapping.count == keyCount, "Every layout argument needs a matrix coordinate.")
        precondition(Set(matrixMapping).count == keyCount, "Layout matrix coordinates must be unique.")
        precondition(Set(keys.map(\.matrixPosition)).count == keys.count, "Visible matrix positions must be unique.")
        precondition(Set(encoders.map(\.index)).count == encoders.count, "Encoder indices must be unique.")
        self.id = id
        self.displayName = displayName
        self.cMacro = cMacro
        self.keyCount = keyCount
        self.matrixRowCount = matrixRowCount
        self.matrixColumnCount = matrixColumnCount
        self.matrixMapping = matrixMapping
        self.canvasWidth = canvasWidth
        self.canvasHeight = canvasHeight
        self.keys = keys
        self.encoders = encoders
    }
}
