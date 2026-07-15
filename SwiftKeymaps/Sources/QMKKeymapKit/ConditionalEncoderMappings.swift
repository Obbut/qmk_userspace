/// One selected branch of a statically typed encoder-mapping conditional.
public enum ConditionalEncoderMappings<First: EncoderMappings, Second: EncoderMappings>:
    EncoderMappings
{
    case first(First)
    case second(Second)

    public var mappingCount: Int {
        switch self {
        case let .first(content): content.mappingCount
        case let .second(content): content.mappingCount
        }
    }

    public func mapping(at ordinal: Int) -> On? {
        switch self {
        case let .first(content): content.mapping(at: ordinal)
        case let .second(content): content.mapping(at: ordinal)
        }
    }
}
