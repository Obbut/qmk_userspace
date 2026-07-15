/// Two statically typed encoder mapping sequences in declaration order.
public struct EncoderMappingGroup<First: EncoderMappings, Second: EncoderMappings>: EncoderMappings {
    @usableFromInline internal let first: First
    @usableFromInline internal let second: Second

    @_alwaysEmitIntoClient
    @inline(__always)
    public init(_ first: First, _ second: Second) {
        self.first = first
        self.second = second
    }

    @_alwaysEmitIntoClient
    @inline(__always)
    public var mappingCount: Int { first.mappingCount + second.mappingCount }

    @_alwaysEmitIntoClient
    @inline(__always)
    public func mapping(at ordinal: Int) -> On? {
        if ordinal < first.mappingCount { return first.mapping(at: ordinal) }
        return second.mapping(at: ordinal - first.mappingCount)
    }
}
