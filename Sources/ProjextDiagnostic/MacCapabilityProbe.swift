import Foundation

#if canImport(IOBluetooth)
import IOBluetooth

/// Passive inspection only: never opens or closes Bluetooth connections.
/// We intentionally avoid printing Bluetooth MAC addresses and serial numbers.
func inspectAirPodsBluetooth() {
    guard let devices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] else {
        print("No paired devices reported by IOBluetooth.")
        return
    }
    let airpods = devices.filter { ($0.name ?? "").localizedCaseInsensitiveContains("AirPods") }
    guard !airpods.isEmpty else {
        print("No paired device with 'AirPods' in its name was found.")
        print("Check Bluetooth Settings; device-name matching may miss renamed AirPods.")
        return
    }
    for device in airpods {
        print("AirPods device: \(device.name ?? "(unnamed)")")
        print("  connected: \(device.isConnected())")
        print("  paired: \(device.isPaired())")
        print("  cached SDP services: \(device.services?.count ?? 0)")
    }
    print("Passive inspection complete. No channel was opened and no packets were intercepted.")
    print("Connection state and cached SDP services do NOT expose proprietary stem events.")
}
#else
func inspectAirPodsBluetooth() {
    print("This Bluetooth probe requires macOS with IOBluetooth.")
}
#endif

/// Explicit opt-in output control. Never invoked by monitoring or analyzing.
func adjustMacVolume(direction: String, steps: Int) {
    guard ["up", "down"].contains(direction), (1...20).contains(steps) else {
        print("Usage: volume-step up|down [1...20]")
        return
    }
    // AppleScript's Standard Additions set/get volume commands control the Mac's
    // default output, not a private Bluetooth channel. Clamp to 0...100 percent.
    let delta = direction == "up" ? 5 * steps : -5 * steps
    let script = """
    set currentVolume to output volume of (get volume settings)
    set targetVolume to currentVolume + (\(delta))
    if targetVolume > 100 then set targetVolume to 100
    if targetVolume < 0 then set targetVolume to 0
    set volume output volume targetVolume
    return output volume of (get volume settings)
    """
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", script]
    let output = Pipe()
    process.standardOutput = output
    process.standardError = output
    do {
        try process.run()
        process.waitUntilExit()
        let result = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if process.terminationStatus == 0 {
            print("Mac default output volume: \(result)%")
        } else {
            print("Volume adjustment failed (osascript status \(process.terminationStatus)): \(result)")
        }
    } catch {
        print("Could not launch the system volume utility: \(error)")
    }
}
