/// Message identifiers for the protocol request and response envelope.
extension KeymapProtocol {
    /// Message identifiers carried in byte five of a report.
    enum MessageType: UInt8 {
        /// A host request for an immediate state packet.
        case getState = 1

        /// A keyboard state response or unsolicited state-change event.
        case state = 2

        /// A host request for keymap metadata.
        case getKeymapMetadata = 3

        /// Firmware keymap dimensions and fingerprint metadata.
        case keymapMetadata = 4

        /// A host request for a page of keymap entries.
        case getKeymapChunk = 5

        /// A firmware page of keymap entries.
        case keymapChunk = 6

        /// A host request to persist a complete RGB Matrix configuration.
        case setRGBSettings = 7
    }
}
