/// The statically composed firmware features selected by one board.
public struct FirmwareFeatures: Sendable {
    /// The feature descriptors in declaration order.
    public let descriptors: [FirmwareFeatureDescriptor]

    /// Creates a complete feature set.
    ///
    /// - Parameter descriptors: The feature descriptors in declaration order.
    public init(descriptors: [FirmwareFeatureDescriptor]) {
        precondition(
            Set(descriptors.map(\.id)).count == descriptors.count,
            "Firmware feature identifiers must be unique."
        )
        self.descriptors = descriptors
    }
}
