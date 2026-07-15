#if hasFeature(Embedded)
import ObbutKeymaps

/// Selects Q15-specific policy for custom Embedded Swift extensions.
@c @implementation
func obbut_firmware_profile() -> UInt8 { 3 }
#endif
