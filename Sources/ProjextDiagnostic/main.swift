import Foundation
import GestureCore
#if canImport(AppKit)
import AppKit
#endif

func stamp() -> String { ISO8601DateFormatter().string(from: Date()) }
func usage() {
    print("""
    projext-diagnostic — macOS AirPods feasibility utility
      swift run projext-diagnostic simulate left [seconds]
      swift run projext-diagnostic simulate right [seconds]
      swift run projext-diagnostic monitor
      swift run projext-diagnostic monitor-cg
      swift run projext-diagnostic analyze <path-to-pklg>

    'simulate' prints signed volume steps (dry run; does NOT change volume).
    'monitor' watches macOS system-defined media-key events, if exposed.
    Neither command captures raw Bluetooth/AAP or identifies which AirPod was pressed.
    """)
}

func simulate(_ side: EarbudSide, seconds: Double) {
    var engine = GestureEngine()
    guard engine.accept(.began(side)) else { return }
    print("\(stamp()) SIMULATED HOLD_START side=\(side.rawValue)")
    let interval = 0.25
    for _ in 0..<max(1, Int((seconds / interval).rounded(.up))) {
        print("\(stamp()) SIMULATED volumeDelta=\(engine.step())")
        Thread.sleep(forTimeInterval: interval)
    }
    _ = engine.accept(.ended(side))
    print("\(stamp()) SIMULATED HOLD_END side=\(side.rawValue) volumeDelta=\(engine.step())")
}

#if canImport(AppKit)
func monitor() {
    print("\(stamp()) Listening for macOS system-defined events. Press Ctrl+C to exit.")
    print("NOTE: AirPods stem events may be consumed by macOS and never reach this monitor.")
    let mask: NSEvent.EventTypeMask = [.systemDefined]
    let handler: (NSEvent) -> Void = { event in
        guard event.subtype.rawValue == 8 else { return }
        let data = UInt32(truncatingIfNeeded: event.data1)
        let keyCode = (data >> 16) & 0xffff
        let flags = (data >> 8) & 0xff
        let state = (flags & 0x1) == 0 ? "down" : "up"
        let action: String
        switch keyCode {
        case 16: action = "play-pause"
        case 17: action = "next-track"
        case 18: action = "previous-track"
        case 0: action = "volume-up"
        case 1: action = "volume-down"
        default: action = "other"
        }
        print("\(stamp()) media-key code=\(keyCode) action=\(action) state=\(state) side=UNKNOWN")
        fflush(stdout)
    }
    let global = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler)
    let local = NSEvent.addLocalMonitorForEvents(matching: mask) { event in handler(event); return event }
    defer {
        if let global { NSEvent.removeMonitor(global) }
        if let local { NSEvent.removeMonitor(local) }
    }
    RunLoop.current.run()
}
#else
func monitor() { print("The media-event monitor requires macOS with AppKit.") }
#endif

let args = Array(CommandLine.arguments.dropFirst())
switch args.first {
case "simulate":
    if args.count >= 2, let side = EarbudSide(rawValue: args[1]) {
        let seconds = args.count >= 3 ? (Double(args[2]) ?? 3) : 3
        guard (0.1...30).contains(seconds) else { fatalError("Seconds must be 0.1–30") }
        simulate(side, seconds: seconds)
    } else { usage() }
case "monitor": monitor()
case "monitor-cg": monitorCoreGraphics()
case "analyze":
    if args.count == 2 {
        do { try PklgAnalyzer.analyze(path: args[1]) }
        catch { fputs("Analyze failed: \(error)\n", stderr); exit(1) }
    } else { usage() }
default: usage()
}
