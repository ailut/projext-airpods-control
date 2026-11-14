import Foundation
#if canImport(AppKit)
import AppKit
import CoreGraphics

/// Read-only diagnostic: observe system-defined media-key messages through a
/// session-level Quartz event tap. This is not an AirPods/AAP packet decoder.
func monitorCoreGraphics() {
    let sysDefined = CGEventType(rawValue: 14)! // NX_SYSDEFINED
    let mask = CGEventMask(1) << 14

    let callback: CGEventTapCallBack = { proxy, type, event, info in
        if type == .tapDisabledByTimeout {
            // A timed-out tap may be re-enabled from the caller's tap port,
            // but we don't have that object in this callback.
            print("\(Date()) CG tap timed out; restart monitor if needed")
            fflush(stdout)
            return Unmanaged.passUnretained(event)
        }
        guard type.rawValue == 14, let ns = NSEvent(cgEvent: event) else {
            return Unmanaged.passUnretained(event)
        }
        guard ns.subtype.rawValue == 8 else {
            return Unmanaged.passUnretained(event)
        }
        let data = UInt32(truncatingIfNeeded: ns.data1)
        let keyCode = (data >> 16) & 0xffff
        let keyFlags = (data >> 8) & 0xff
        let state = keyFlags == 0x0a ? "down" : (keyFlags == 0x0b ? "up" : "flags-\(keyFlags)")
        let name: String
        switch keyCode {
        case 16: name = "play-pause"
        case 17: name = "next"
        case 18: name = "previous"
        case 0: name = "volume-up"
        case 1: name = "volume-down"
        default: name = "other"
        }
        print("CG MEDIA code=\(keyCode) action=\(name) state=\(state) side=UNKNOWN")
        fflush(stdout)
        return Unmanaged.passUnretained(event)
    }

    guard let tap = CGEvent.tapCreate(
        tap: .cgSessionEventTap,
        place: .headInsertEventTap,
        options: .listenOnly,
        eventsOfInterest: mask,
        callback: callback,
        userInfo: nil
    ) else {
        print("Could not create Core Graphics event tap. Check Input Monitoring/Accessibility permission for the host Terminal app, restart it, and retry.")
        return
    }
    guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
        print("Could not create run-loop source for event tap.")
        return
    }
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
    CGEvent.tapEnable(tap: tap, enable: true)
    print("Core Graphics listen-only media monitor active. Press Mac media key and AirPods stem. Ctrl+C to stop.")
    print("Note: No events may appear if the OS processes the commands outside CG events.")
    fflush(stdout)
    CFRunLoopRun()
    CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
}
#else
func monitorCoreGraphics() {
    print("Core Graphics monitoring is available only on macOS.")
}
#endif
