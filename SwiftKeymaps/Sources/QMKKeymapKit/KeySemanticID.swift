/// A stable, domain-owned semantic identifier carried by the firmware protocol.
public protocol KeySemanticID: RawRepresentable, Hashable, Sendable
where RawValue == UInt16 {}
