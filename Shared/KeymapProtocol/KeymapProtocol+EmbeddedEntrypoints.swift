// C-callable entry points for the Embedded Swift protocol engine.
// SPDX-License-Identifier: GPL-2.0-or-later

#if hasFeature(Embedded)
    /// Delivers one QMK Raw HID report to the Swift protocol engine.
    @c @implementation
    func keymap_protocol_receive(
        _ data: UnsafePointer<UInt8>,
        _ length: UInt8
    ) {
        KeymapProtocolFirmware.receive(data, length: length)
    }

    /// Gives the Swift protocol engine an opportunity to send changed state.
    @c @implementation
    func keymap_protocol_housekeeping() {
        KeymapProtocolFirmware.housekeeping()
    }
#endif
