#if hasFeature(Embedded)
import ObbutKeymaps

/// Identifies Kyria as runtime profile 1 at the generated C ABI boundary.
@c @implementation
func obbut_firmware_profile() -> UInt8 { 1 }
#endif
