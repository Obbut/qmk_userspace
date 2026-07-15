/// A stable, domain-owned visual-style identifier carried by the firmware protocol.
public protocol KeyStyleID: RawRepresentable, Hashable, Sendable
where RawValue == UInt16 {}
