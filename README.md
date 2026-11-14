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


## Phase 3 prototype — Swift diagnostic utility

The repository now contains a Swift Package with a small transport-independent gesture engine, unit tests, and a **macOS media-event monitor**. This is a feasibility prototype, **not** an AirPods Bluetooth parser or finished volume-control app.

### Setup and test on a Mac

```bash
git clone https://github.com/ailut/projext-airpods-control.git
cd projext-airpods-control
swift test
swift run projext-diagnostic simulate left 2
swift run projext-diagnostic simulate right 2
```

The two simulation commands print signed volume steps only; **they do not change the Mac's volume**.

To look for macOS-delivered media-key events:

```bash
swift run projext-diagnostic monitor
```

With both AirPods connected, try one single press, one double press and a hold. Then use the keyboard play/pause and next-track buttons as controls. Stop with **Ctrl+C**. The output intentionally reports `side=UNKNOWN` because macOS media-key events do not guarantee an earbud source.

If no events appear, check whether macOS requests Input Monitoring or Accessibility permission for the Terminal application, and retry after granting only what is necessary. **An empty log does not rule out proprietary Bluetooth events**; PacketLogger can receive traffic that an ordinary Swift program cannot.

### Quartz event-tap experiment

The AppKit `monitor` command produced no media-key logs in either VS Code's terminal or Terminal.app, despite working AirPods playback controls. A second, **read-only** Quartz/Core Graphics event-tap diagnostic is now included:

```bash
cd ~/Developer/projext-airpods-control
git pull
swift build
swift run projext-diagnostic monitor-cg
```

If this is blocked, verify Input Monitoring and Accessibility permissions for the actual host app and relaunch it. While running, test a physical Mac media key, then AirPods single- and double-presses; press Ctrl+C to stop. Report whether the tap starts, whether the Mac key logs, and whether AirPods actions log. **This code has not been compiled on the user's Mac yet**; any compiler errors should be shared for correction.

The tap deliberately returns the original event unchanged. Even successful events will report `side=UNKNOWN` because system-defined media-key events are not established as containing AirPods left/right origin. A silent monitor is not proof of absent Bluetooth data.

### Build verification

The Swift Package and the three gesture-state unit tests were built/tested in a Linux Swift environment. **Native macOS AppKit monitor compilation and real AirPods integration remain unverified until run on a Mac.**

### Immediate evidence gate

Compare whether `monitor` prints media-key events for the keyboard versus the AirPods stems. If both are absent or the stems alone are absent, stop and investigate permissible macOS interfaces; do not assume PacketLogger packets can be consumed directly by this program.

No raw Bluetooth files or personal device identifiers are needed in the repository.

## Offline PacketLogger analyzer (Phase 3)

The Swift diagnostic utility now has a **saved-capture** parser. It reads PacketLogger `.pklg` record headers and reports an *empirically observed* 184-byte incoming ACL candidate structure. This does **not** provide live AirPods event access or officially decoded Apple protocol fields.

```bash
cd ~/Developer/projext-airpods-control
git pull
swift test
swift run projext-diagnostic analyze ~/path/to/left_hold_5sec.pklg
swift run projext-diagnostic analyze ~/path/to/right_hold_5sec.pklg
```

Replace the paths with the actual local paths to your captures. Existing captures stay local, never in this repository. Analysis prints candidate timestamp relative to the first record, a **tentative** side, and two unassigned fields; it intentionally does not dump raw Bluetooth payloads or device addresses. The header parser and candidate matching include synthetic unit tests; Mac compilation should be verified with `swift test`.

### Evidence snapshot (not raw captures)

Across 20 physical single-, double-, and hold-press recordings supplied during the investigation, the selected 184-byte candidate pattern appeared once per capture, with the byte at candidate payload offset 26 equal to `02` for left and `01` for right. Three no-stem controls (baseline, keyboard track skip, Mac-triggered Siri) had no matches under the same signature. This is a **dataset correlation** only. It does not establish whether the bytes encode the actual pressing earbud, a downstream state change, a hold-start event or a release event.

The next gates are to correlate the candidate timestamp with instrumented press/release times and to determine whether a permitted **live event source** is available to a normal macOS or iOS application. We must not equate visibility in a diagnostic .pklg file with accessibility through a public app API.

### PacketLogger elapsed-time correction

Some exported captures prepend old diagnostic metadata (record type `0xFC`) before current Bluetooth traffic. The analyzer now measures relative time from the first HCI record of types `0`–`3`, rather than the first saved record. Earlier anomalous `+970000s` offsets were a **timestamp baseline bug**, not extended stem holds. The correction does not alter packet classification and still does not provide live access or validated gesture semantics.

## Research references

- [AirPods BLE battery research](https://github.com/stuffz/airpods/blob/main/docs/ble-research.md)
- [airpods-ctl / AAP investigation](https://github.com/BorgoGustavo/airpods-ctl)
- [MousePods / AirPods 3 RemoteHID investigation](https://github.com/starman-tech/mousepods)

## Privacy and safety

Do not commit raw `.pklg`, `.pcap`, HCI captures, Bluetooth identifiers, serial numbers, or pairing data. Keep hardware firmware unchanged. No jailbreak or private iOS APIs in the initial scope.
