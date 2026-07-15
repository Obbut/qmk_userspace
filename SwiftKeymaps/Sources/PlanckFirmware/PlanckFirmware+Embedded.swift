#if hasFeature(Embedded)
import ObbutKeymaps

/// Identifies Planck as runtime profile 4 at the generated C ABI boundary.
@c @implementation
func obbut_firmware_profile() -> UInt8 { 4 }
#endif
