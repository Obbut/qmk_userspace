#if hasFeature(Embedded)
import ObbutKeymaps

/// Identifies Q15 as runtime profile 3 at the generated C ABI boundary.
@c @implementation
func obbut_firmware_profile() -> UInt8 { 3 }
#endif
