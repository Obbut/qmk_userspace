import KeymapCompanionCore

typealias KeyLegend = KeymapCompanionCore.KeyLegend
typealias KeySymbol = KeymapCompanionCore.KeySymbol

extension KeymapCompanionCore.KeyLegend {
    /// The SF Symbol used by the existing SwiftUI renderer.
    var systemImageName: String? {
        symbol?.systemImageName
    }
}

private extension KeymapCompanionCore.KeySymbol {
    var systemImageName: String {
        switch self {
        case .returnKey: "return"
        case .escape: "escape"
        case .deleteBackward: "delete.left"
        case .tab: "arrow.right.to.line"
        case .space: "space"
        case .capsLock: "capslock"
        case .deleteForward: "delete.right"
        case .arrowRight: "arrow.right"
        case .arrowLeft: "arrow.left"
        case .arrowDown: "arrow.down"
        case .arrowUp: "arrow.up"
        case .mute: "speaker.slash.fill"
        case .volumeUp: "speaker.wave.3.fill"
        case .volumeDown: "speaker.wave.1.fill"
        case .nextTrack: "forward.end.fill"
        case .previousTrack: "backward.end.fill"
        case .playPause: "playpause.fill"
        case .control: "control"
        case .shift: "shift"
        case .option: "option"
        case .command: "command"
        }
    }
}
