import QMKFirmwareRuntime
import QMKKeymapKit

/// Platform-aware screenshot and Command/Control behavior shared by Obbut keyboards.
public struct ObbutWindowsOverrides: FirmwareFeature, Sendable {
    public typealias State = EmptyFeatureState
    public static let initialState = EmptyFeatureState()

    public init() {}

    public static func processRecord(
        _ event: KeyEvent,
        state: inout EmptyFeatureState,
        context: inout FirmwareContext
    ) -> KeyEventDisposition {
        guard context.isWindows else { return .continueProcessing }

        if event.keycode == QMKKeycode.pointerButton1.rawValue,
            !context.pointerFeatureActive
        {
#if hasFeature(Embedded)
            if event.isPressed { obbut_platform_layer_invert(1) }
#endif
            return .handled
        }

        let replacement: UInt16? = switch event.keycode {
        case Key.screenshot.keycode.rawValue: Key.printScreen.keycode.rawValue
        case 0x00E0: 0x00E3
        case 0x00E3: 0x00E0
        case 0x00A9: 0x0080
        case 0x00AA: 0x0081
        default: nil
        }
        guard let replacement else { return .continueProcessing }
        context.sendKeycode(replacement, isPressed: event.isPressed)
        return .handled
    }
}
