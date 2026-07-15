/// The synchronous transport operations required by one Windows HID session.
protocol WindowsHIDTransport: AnyObject, Sendable {
    /// Blocks until one input report arrives or the operation is cancelled.
    ///
    /// - Parameter buffer: Storage for one complete protocol report.
    /// - Returns: The number of bytes read, or a negative transport error.
    func readReport(into buffer: UnsafeMutableBufferPointer<UInt8>) -> Int32

    /// Writes one complete output report.
    ///
    /// - Parameter bytes: One complete protocol report.
    /// - Returns: The number of bytes written, or a negative transport error.
    func writeReport(_ bytes: UnsafeBufferPointer<UInt8>) -> Int32

    /// Cancels outstanding synchronous operations.
    func cancel()

    /// Releases the native transport after all operations have finished.
    func destroy()
}
