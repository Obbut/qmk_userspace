#if hasFeature(Embedded)
import ObbutKeymaps

/// Selects Kyria-specific policy in the shared Obbut Embedded Swift runtime.
@c @implementation
func obbut_firmware_profile() -> UInt8 { 1 }
#endif
