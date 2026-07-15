import QMKKeymapKit
import QMKKeymapRenderer

/// Conversion from live protocol data to the production renderer document.
public extension KeymapDefinition {
    /// The renderer input shared with authored-firmware Xcode previews.
    var renderDocument: KeymapRenderDocument {
        KeymapRenderDocument(
            layoutID: layoutID.rawValue,
            displayName: displayName,
            canvasWidth: geometry.canvasWidth,
            canvasHeight: geometry.canvasHeight,
            layers: supportedLayers.map {
                KeymapRenderLayer(id: $0.rawValue, name: $0.displayName, showsHUD: $0.isHUDLayer)
            },
            keys: positionedKeys.map { positionedKey in
                KeymapRenderKey(
                    id: positionedKey.id,
                    placement: positionedKey.placement.renderPlacement,
                    legends: positionedKey.key.legends.map(\.renderLegend)
                )
            },
            encoders: encoders.map { encoder in
                KeymapRenderEncoder(
                    id: encoder.id,
                    placement: encoder.placement.renderPlacement,
                    counterclockwiseLegends: encoder.counterclockwiseKey.legends.map(\.renderLegend),
                    pressLegends: encoder.pressKey.legends.map(\.renderLegend),
                    clockwiseLegends: encoder.clockwiseKey.legends.map(\.renderLegend)
                )
            }
        )
    }
}

/// Converts companion geometry to renderer geometry.
fileprivate extension PhysicalKeyPlacement {
    var renderPlacement: QMKKeymapKit.PhysicalKeyPlacement {
        QMKKeymapKit.PhysicalKeyPlacement(
            centerX: centerX,
            centerY: centerY,
            width: width,
            height: height,
            rotationDegrees: rotationDegrees
        )
    }
}

/// Converts live catalog-resolved legends to renderer legends.
fileprivate extension KeyLegend {
    var renderLegend: KeymapRenderLegend {
        KeymapRenderLegend(
            label: label,
            symbolName: symbol?.rendererName,
            style: KeymapRenderStyle(
                red: style.red,
                green: style.green,
                blue: style.blue,
                isKnown: style.isKnown
            )
        )
    }
}

/// Stable renderer symbol names for standard and domain actions.
fileprivate extension KeySymbol {
    var rendererName: String {
        switch self {
        case .returnKey: "return"
        case .escape: "escape"
        case .deleteBackward: "delete-backward"
        case .tab: "tab"
        case .space: "space"
        case .capsLock: "caps-lock"
        case .deleteForward: "delete-forward"
        case .arrowRight: "arrow-right"
        case .arrowLeft: "arrow-left"
        case .arrowDown: "arrow-down"
        case .arrowUp: "arrow-up"
        case .mute: "mute"
        case .volumeUp: "volume-up"
        case .volumeDown: "volume-down"
        case .nextTrack: "next-track"
        case .previousTrack: "previous-track"
        case .playPause: "play-pause"
        case .control: "control"
        case .shift: "shift"
        case .option: "option"
        case .command: "command"
        case .camera: "camera"
        case .windowManagement: "window-management"
        case .lockedPointer: "locked-pointer"
        case .bluetooth: "bluetooth"
        case .battery: "battery"
        case .pointerButton: "pointer-button"
        case .pointer: "pointer"
        case .scroll: "scroll"
        case .browserNavigation: "browser-navigation"
        case .wireless: "wireless"
        }
    }
}
