import KeymapCompanionCore

/// A key label and its layer-specific appearance.
typealias KeyLegend = KeymapCompanionCore.KeyLegend

/// SF Symbol presentation for shared key legends.
extension KeymapCompanionCore.KeyLegend {
    /// The SF Symbol used by the existing SwiftUI renderer.
    var systemImageName: String? {
        symbol?.systemImageName
    }
}

/// SF Symbol names for platform-neutral key symbols.
fileprivate extension KeymapCompanionCore.KeySymbol {
    /// The SF Symbol name for this semantic symbol.
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
        case .camera: "camera"
        case .windowManagement: "macwindow.on.rectangle"
        case .lockedPointer: "lock.fill"
        case .bluetooth: "wave.3.right"
        case .battery: "battery.75percent"
        case .pointerButton: "cursorarrow.click"
        case .pointer: "cursorarrow.motionlines"
        case .scroll: "scroll"
        case .browserNavigation: "arrow.left.arrow.right"
        case .wireless: "antenna.radiowaves.left.and.right"
        }
    }
}
