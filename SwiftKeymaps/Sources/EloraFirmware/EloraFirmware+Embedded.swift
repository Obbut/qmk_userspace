#if hasFeature(Embedded)
import ObbutKeymaps

/// Identifies Elora as runtime profile 2 at the generated C ABI boundary.
@c @implementation
func obbut_firmware_profile() -> UInt8 { 2 }
#endif
