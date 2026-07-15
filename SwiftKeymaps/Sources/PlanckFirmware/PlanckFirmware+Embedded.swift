#if hasFeature(Embedded)
import ObbutKeymaps

/// Selects Planck-specific policy for custom Embedded Swift extensions.
@c @implementation
func obbut_firmware_profile() -> UInt8 { 4 }
#endif
