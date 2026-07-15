#if hasFeature(Embedded)
import ObbutKeymaps

/// Selects Elora-specific policy in the shared Obbut Embedded Swift runtime.
@c @implementation
func obbut_firmware_profile() -> UInt8 { 2 }
#endif
