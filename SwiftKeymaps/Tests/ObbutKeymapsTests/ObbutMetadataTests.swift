import ObbutKeymaps
import QMKKeymapKit
import Testing

/// Pins the stable metadata supplied by the shared Obbut module.
@Suite
struct ObbutMetadataTests {
    @Test
    func qmkForkMirrorsMatchCommittedABIValues() {
        #expect(QMKKeycode.triLayerLower.rawValue == 0x7C77)
        #expect(QMKKeycode.triLayerUpper.rawValue == 0x7C78)
        #expect(QMKKeycode.rgbMatrixToggle.rawValue == 0x7842)
        #expect(QMKKeycode.pointerButton1.rawValue == 0x00D1)
        #expect(QMKKeycode.pointerScroll.rawValue == 0x7E40)
        #expect(QMKKeycode.keychronRGBToggle.rawValue == 0x7820)
        #expect(QMKKeycode.keychronRGBValueUp.rawValue == 0x7827)
        #expect(QMKKeycode.keychronRGBSpeedDown.rawValue == 0x782A)
        #expect(QMKKeycode.keychronBluetoothHost1.rawValue == 0x7E0B)
        #expect(QMKKeycode.keychronBatteryLevel.rawValue == 0x7E0F)
    }

    @Test
    func protocolContentIdentifiersAreNonzeroAndUnique() {
        let legendIDs = Self.keys.map(\.legendID)
        let appearances = Set(Self.styles.map {
            $0.makeAppearance(
                configuration: KeyStyleConfiguration(keycode: QMKKeycode(rawValue: 0))
            )
        })
        let styleIDs = appearances.map(\.contentID)

        #expect(legendIDs.allSatisfy { $0 != 0 })
        #expect(Set(legendIDs).count == legendIDs.count)
        #expect(styleIDs.allSatisfy { $0 != 0 })
        #expect(Set(styleIDs).count == styleIDs.count)
    }

    /// Verifies Obbut's named styles retain their intended portable colors.
    @Test
    func namedStyleColorsAreStable() {
        let configuration = KeyStyleConfiguration(keycode: QMKKeycode(rawValue: 0x0004))
        let colors = Self.styles.map {
            $0.makeAppearance(configuration: configuration).color
        }
        let expectedColors: [RGBColor] = [
            .rgb(148, 0, 211),
            .rgb(255, 0, 255),
            .rgb(0, 0, 255),
            .rgb(255, 255, 0),
            .rgb(0, 220, 220),
            .rgb(0, 255, 0),
            .rgb(0, 50, 0),
            .rgb(255, 128, 0),
            .rgb(255, 68, 68),
            .rgb(0, 220, 220),
            .rgb(0, 180, 220),
            .rgb(255, 255, 255),
        ]

        #expect(colors == expectedColors)
    }

    fileprivate static let keys: [Key] = [
        .screenshot,
        .aerospace,
        .pointerLeftClick,
        .pointerRightClick,
        .pointerMiddleClick,
        .browserBack,
        .browserForward,
        .pointerScroll,
        .pointerSniper,
        .pointerDragLock,
        .pointerSensitivityDown,
        .pointerSensitivityUp,
        .pointerScrollSpeedDown,
        .pointerScrollSpeedUp,
        .bluetoothHost1,
        .bluetoothHost2,
        .bluetoothHost3,
        .wireless24GHz,
        .batteryLevel,
    ]

    fileprivate static let styles: [SolidKeyStyle] = [
        .gaming,
        .navigation,
        .number,
        .symbol,
        .function,
        .increase,
        .decrease,
        .destructive,
        .bootloader,
        .wireless,
        .pointer,
        .operatingSystem,
    ]
}
