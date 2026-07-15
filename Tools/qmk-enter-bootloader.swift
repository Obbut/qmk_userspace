// Sends protocol v4's confirmed bootloader request over the QMK Raw HID endpoint.
// SPDX-License-Identifier: GPL-2.0-or-later

import CoreFoundation
import Foundation
@preconcurrency import IOKit.hid

final class ReportReceiver {
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: 32)
    var acknowledged = false

    init() {
        buffer.initialize(repeating: 0, count: 32)
    }

    deinit {
        buffer.deallocate()
    }
}

private func identifier(from argument: String, name: String) -> Int {
    let digits = argument.hasPrefix("0x") ? String(argument.dropFirst(2)) : argument
    let radix = argument.hasPrefix("0x") ? 16 : 10
    guard let value = Int(digits, radix: radix), (0...0xFFFF).contains(value) else {
        fatalError("Invalid \(name): \(argument)")
    }
    return value
}

guard CommandLine.arguments.count == 3 else {
    fatalError("Usage: qmk-enter-bootloader.swift <vendor-id> <product-id>")
}

let vendorID = identifier(from: CommandLine.arguments[1], name: "vendor ID")
let productID = identifier(from: CommandLine.arguments[2], name: "product ID")
let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
let matching: [String: Any] = [
    kIOHIDVendorIDKey: vendorID,
    kIOHIDProductIDKey: productID,
    kIOHIDDeviceUsagePageKey: 0xFF60,
    kIOHIDDeviceUsageKey: 0x61,
]
IOHIDManagerSetDeviceMatching(manager, matching as CFDictionary)
guard IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess,
    let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>,
    let device = devices.first,
    IOHIDDeviceOpen(device, IOOptionBits(kIOHIDOptionsTypeNone)) == kIOReturnSuccess
else {
    fatalError(
        String(format: "Raw HID endpoint %04X:%04X is unavailable.", vendorID, productID)
    )
}

let receiver = ReportReceiver()
IOHIDDeviceRegisterInputReportCallback(
    device,
    receiver.buffer,
    32,
    { context, result, _, _, _, report, reportLength in
        guard result == kIOReturnSuccess, reportLength == 32, let context else { return }
        let receiver = Unmanaged<ReportReceiver>.fromOpaque(context).takeUnretainedValue()
        let bytes = UnsafeBufferPointer(start: report, count: reportLength)
        receiver.acknowledged = Array(bytes[0..<10])
            == [0x4B, 0x4D, 0x41, 0x50, 4, 9, 0x44, 0x46, 0x55, 0x21]
        if receiver.acknowledged {
            CFRunLoopStop(CFRunLoopGetMain())
        }
    },
    Unmanaged.passUnretained(receiver).toOpaque()
)
IOHIDDeviceScheduleWithRunLoop(device, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)

var request = [UInt8](repeating: 0, count: 32)
request.replaceSubrange(
    0..<10,
    with: [0x4B, 0x4D, 0x41, 0x50, 4, 8, 0x44, 0x46, 0x55, 0x21]
)
let result = request.withUnsafeBufferPointer { bytes in
    IOHIDDeviceSetReport(
        device,
        kIOHIDReportTypeOutput,
        0,
        bytes.baseAddress!,
        bytes.count
    )
}
guard result == kIOReturnSuccess else {
    fatalError("Bootloader request failed with IOKit result \(result).")
}

let deadline = Date().addingTimeInterval(2)
while !receiver.acknowledged && Date() < deadline {
    CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 0.1, true)
}
guard receiver.acknowledged else {
    fatalError("Firmware did not acknowledge the bootloader request.")
}

print(String(format: "Bootloader request accepted by %04X:%04X.", vendorID, productID))
IOHIDDeviceUnscheduleFromRunLoop(
    device,
    CFRunLoopGetMain(),
    CFRunLoopMode.defaultMode.rawValue
)
IOHIDDeviceClose(device, IOOptionBits(kIOHIDOptionsTypeNone))
IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
