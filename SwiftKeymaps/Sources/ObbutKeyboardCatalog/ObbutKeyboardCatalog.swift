import EloraFirmware
import KyriaFirmware
import ObbutKeymaps
import PlanckFirmware
import Q15Firmware
import QMKFirmwareRuntime

/// The cycle-free aggregate catalog consumed by generators, previews, and companion apps.
public enum ObbutKeyboardCatalog {
    /// Every Obbut firmware definition in stable catalog order.
    public static let all: [AnyFirmware] = [
        AnyFirmware(KyriaFirmware.self),
        AnyFirmware(EloraFirmware.self),
        AnyFirmware(Q15Firmware.self),
        AnyFirmware(PlanckFirmware.self),
    ]

    /// Finds firmware by its stable keymap identifier or short build name.
    ///
    /// - Parameter identifier: A keymap identifier, output name, or supported short name.
    /// - Returns: The matching firmware definition, if one exists.
    public static func firmware(named identifier: String) -> AnyFirmware? {
        let aliases: [String: String] = [
            "kyria": "com.obbut.kyria-rev4",
            "elora": "com.obbut.elora-rev2",
            "q15": "com.obbut.keychron-q15-max",
            "planck": "com.obbut.planck-ez-glow",
        ]
        let resolvedIdentifier = aliases[identifier.lowercased()] ?? identifier
        return all.first {
            $0.id == resolvedIdentifier || $0.outputName == resolvedIdentifier
        }
    }

    /// Finds firmware by the stable protocol-v4 layout identifier.
    ///
    /// - Parameter layoutID: The opaque identifier reported by firmware.
    /// - Returns: The matching firmware definition, if this catalog contains it.
    public static func firmware(layoutID: UInt32) -> AnyFirmware? {
        all.first { $0.layoutID == layoutID }
    }
}
