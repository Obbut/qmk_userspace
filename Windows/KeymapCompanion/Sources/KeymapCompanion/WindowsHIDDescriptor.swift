import CWindowsHID
import KeymapCompanionCore

/// The Windows path and report lengths for one compatible HID endpoint.
struct WindowsHIDDescriptor: Sendable {
    /// The Windows device path.
    let path: String

    /// The endpoint's complete input-report length.
    let inputReportLength: UInt16

    /// The endpoint's complete output-report length.
    let outputReportLength: UInt16

    /// Creates an open transport for this endpoint.
    ///
    /// - Returns: An open transport, or `nil` when Windows cannot open the endpoint.
    func makeTransport() -> (any WindowsHIDTransport)? {
        NativeWindowsHIDTransport(descriptor: self)
    }

    /// Returns all HID endpoints matching QMK's Raw HID usage pair.
    ///
    /// - Returns: The compatible endpoints available at enumeration time.
    static func compatibleEndpoints() -> [Self] {
        let box = WindowsHIDEnumerationResultBox()
        let context = Unmanaged.passUnretained(box).toOpaque()
        keymap_hid_enumerate(
            UInt16(KeymapProtocol.usagePage),
            UInt16(KeymapProtocol.usage),
            { path, inputLength, outputLength, context in
                guard let path, let context else { return }
                let box = Unmanaged<WindowsHIDEnumerationResultBox>.fromOpaque(context).takeUnretainedValue()
                box.descriptors.append(
                    WindowsHIDDescriptor(
                        path: String(decodingCString: path, as: UTF16.self),
                        inputReportLength: inputLength,
                        outputReportLength: outputLength
                    )
                )
            },
            context
        )
        return box.descriptors
    }
}

/// Mutable callback storage whose lifetime is bounded by synchronous enumeration.
fileprivate final class WindowsHIDEnumerationResultBox {
    /// The descriptors accumulated by the C callback.
    var descriptors: [WindowsHIDDescriptor] = []
}
