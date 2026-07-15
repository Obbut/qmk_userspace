import CWindowsHID

/// The native C transport around one Windows HID handle.
///
/// The owning session guarantees a single reader, a single serialized writer, and destruction
/// only after both operation paths have drained.
final class NativeWindowsHIDTransport: WindowsHIDTransport, @unchecked Sendable {
    /// The native Windows HID handle.
    private let handle: OpaquePointer

    /// Creates and opens a native transport for a device descriptor.
    ///
    /// Returns `nil` when Windows cannot open the endpoint.
    ///
    /// - Parameter descriptor: The endpoint to open.
    init?(descriptor: WindowsHIDDescriptor) {
        let pathUnits = Array(descriptor.path.utf16) + [0]
        let opened = pathUnits.withUnsafeBufferPointer { pathBuffer in
            keymap_hid_open(
                pathBuffer.baseAddress,
                descriptor.inputReportLength,
                descriptor.outputReportLength
            )
        }
        guard let opened else { return nil }
        handle = opened
    }

    /// Blocks until one input report arrives or the operation is cancelled.
    ///
    /// - Parameter buffer: Storage for one complete protocol report.
    /// - Returns: The number of bytes read, or a negative transport error.
    func readReport(into buffer: UnsafeMutableBufferPointer<UInt8>) -> Int32 {
        keymap_hid_read_report(handle, buffer.baseAddress, UInt32(buffer.count))
    }

    /// Writes one complete output report.
    ///
    /// - Parameter bytes: One complete protocol report.
    /// - Returns: The number of bytes written, or a negative transport error.
    func writeReport(_ bytes: UnsafeBufferPointer<UInt8>) -> Int32 {
        keymap_hid_write_report(handle, bytes.baseAddress, UInt32(bytes.count))
    }

    /// Cancels outstanding synchronous operations.
    func cancel() {
        keymap_hid_cancel(handle)
    }

    /// Releases the native transport after all operations have finished.
    func destroy() {
        keymap_hid_destroy(handle)
    }
}
