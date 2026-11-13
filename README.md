# projext-airpods-control

Research and development project exploring custom stem gestures for Apple AirPods (3rd generation) on macOS and iOS.

## Target behavior

- **Hold left stem:** continuously decrease volume.
- **Hold right stem:** continuously increase volume.
- **Release:** stop adjusting volume.
- **Final target:** AirPods 3 connected directly to a non-jailbroken iPhone, with audio playing in Brave or another app.

This functionality is **not implemented or proven feasible**. In particular, macOS/iOS may not expose earbud identity, hold-start/release messages, or the iOS background volume control we need.

## Development Phases

### Phase 1 — Bluetooth capture and initial diagnostics (completed)

Completed:
- [x] Created this GitHub repository and documented protocol hypotheses.
- [x] Paired and connected AirPods 3 to a MacBook Air M4 through Bluetooth (Lightning connects the charging case for power, not stem data).
- [x] Queried `system_profiler SPBluetoothDataType`; macOS reported separate left/right battery information.
- [x] Queried `ioreg -r -c IOHIDDevice -l | grep -i -C 5 "AirPods"`; no matching output from that query.
- [x] Installed/launched Apple's PacketLogger and enabled working local Bluetooth HCI logging.
- [x] Collected exploratory left and right long-press traces, then a no-press baseline and controlled left/right traces.
- [x] Observed Siri activate from either stem during long presses.
- [x] Identified a **candidate shared packet sequence** in preliminary analysis; its meaning and origin are unverified.

### Phase 2 — Isolate and identify stem events (in progress)

Not yet established:
- [ ] A reproducible *stem-specific* packet distinct from Siri/audio activity.
- [ ] Independent identification of left vs right stem.
- [ ] Observable hold **start and release** events.
- [ ] Non-jailbroken iOS access while Brave is in the foreground.
- [ ] Programmatic background system-volume changes on iPhone.

### Next experiment for Phase 2

**Siri-only control:** capture a Mac-triggered Siri invocation without touching either AirPod. Compare with both stem-triggered Siri recordings to determine whether the shared packet sequence is just Siri/microphone setup.

Then perform left/right **double-press** captures to isolate track-control events without the long-press/Siri audio pathway.

Detailed procedures, preliminary findings, uncertainties and milestone gates: [Research/protocol-findings.md](Research/protocol-findings.md).

### Phase 3 — Gesture lifecycle and Mac prototype (pending)

- Establish reliable left/right identification and hold-start/hold-release detection.
- Build a safe simulated Swift volume controller and integrate real events only if available.

### Phase 4 — iPhone feasibility (pending)

- Test supported iOS API access, background behavior, and system-volume restrictions while Brave plays audio.
- Do not assume a Mac-based gesture detector will work on iOS.

### Phase 5 — App integration and validation (pending)

- Build the SwiftUI experience only after the iPhone feasibility gates pass, or document a Mac-only fallback.

## Research references

- [AirPods BLE battery research](https://github.com/stuffz/airpods/blob/main/docs/ble-research.md)
- [airpods-ctl / AAP investigation](https://github.com/BorgoGustavo/airpods-ctl)
- [MousePods / AirPods 3 RemoteHID investigation](https://github.com/starman-tech/mousepods)

## Privacy and safety

Do not commit raw `.pklg`, `.pcap`, HCI captures, Bluetooth identifiers, serial numbers, or pairing data. Keep hardware firmware unchanged. No jailbreak or private iOS APIs in the initial scope.
