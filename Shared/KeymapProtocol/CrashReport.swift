// Stable retained-crash vocabulary shared by firmware and companions.
// SPDX-License-Identifier: GPL-2.0-or-later

public enum CrashReason: UInt8, Equatable, Sendable {
    case unknown = 0
    case hardFault = 1
    case memoryManagementFault = 2
    case busFault = 3
    case usageFault = 4
    case watchdog = 5
    case powerOnOrBrownout = 6
}

public enum CrashPhase: UInt8, Equatable, Sendable {
    case idle = 0
    case boot = 1
    case swiftPostInitialize = 2
    case swiftHousekeeping = 3
    case protocolHousekeeping = 4
    case splitSynchronization = 5
    case keyLookup = 6
    case processRecord = 7
    case layerState = 8
    case pointingInitialization = 9
    case pointingTask = 10
    case rgbRendering = 11
    case rawHID = 12
    case metadataTraversal = 13
}

public struct CrashReport: Equatable, Sendable {
    public let reason: CrashReason
    public let phase: CrashPhase
    public let flags: UInt8
    public let consecutiveFailures: UInt8
    public let buildID: UInt32
    public let uptime: UInt32
    public let programCounter: UInt32
    public let linkRegister: UInt32
    public let stackPointer: UInt32
    public let stackFree: UInt16

    public init(
        reason: CrashReason,
        phase: CrashPhase,
        flags: UInt8,
        consecutiveFailures: UInt8,
        buildID: UInt32,
        uptime: UInt32,
        programCounter: UInt32,
        linkRegister: UInt32,
        stackPointer: UInt32,
        stackFree: UInt16
    ) {
        self.reason = reason
        self.phase = phase
        self.flags = flags
        self.consecutiveFailures = consecutiveFailures
        self.buildID = buildID
        self.uptime = uptime
        self.programCounter = programCounter
        self.linkRegister = linkRegister
        self.stackPointer = stackPointer
        self.stackFree = stackFree
    }
}

#if !hasFeature(Embedded)
extension CrashReason: Codable {}
extension CrashPhase: Codable {}
extension CrashReport: Codable {}
#endif
