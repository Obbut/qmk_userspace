/// A statically composed collection of encoder mappings.
public protocol EncoderMappings: Sendable {
    /// The number of mappings.
    var mappingCount: Int { get }

    /// Returns one mapping by declaration ordinal.
    func mapping(at ordinal: Int) -> On?
}

extension On: EncoderMappings {
    public var mappingCount: Int { 1 }

    public func mapping(at ordinal: Int) -> On? {
        ordinal == 0 ? self : nil
    }
}
