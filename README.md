# projext-airpods-control

Research and development project exploring custom stem gestures for Apple AirPods (3rd generation) on macOS and iOS.

## Target behavior

- **Hold left stem:** continuously decrease volume.
- **Hold right stem:** continuously increase volume.
- **Release:** stop adjusting volume.
- **Final target:** AirPods 3 connected directly to a non-jailbroken iPhone, with audio playing in Brave or another app.

This functionality is **not implemented or proven feasible**. In particular, macOS/iOS may not expose earbud identity, hold-start/release messages, or the iOS background volume control we need.

## Status — 13 November 2026

**Phase: Bluetooth capture and hypothesis testing**

Completed:
- [x] Created this GitHub repository and documented protocol hypotheses.
- [x] Paired and connected AirPods 3 to a MacBook Air M4 through Bluetooth (Lightning connects the charging case for power, not stem data).
- [x] Queried `system_profiler SPBluetoothDataType`; macOS reported separate left/right battery information.
- [x] Queried `ioreg -r -c IOHIDDevice -l | grep -i -C 5 "AirPods"`; no matching output from that query.
- [x] Installed/launched Apple's PacketLogger and enabled working local Bluetooth HCI logging.
- [x] Collected exploratory left and right long-press traces, then a no-press baseline and controlled left/right traces.
- [x] Observed Siri activate from either stem during long presses.
- [x] Identified a **candidate shared packet sequence** in preliminary analysis; its meaning and origin are unverified.

Not yet established:
- [ ] A reproducible *stem-specific* packet distinct from Siri/audio activity.
- [ ] Independent identification of left vs right stem.
- [ ] Observable hold **start and release** events.
- [ ] Non-jailbroken iOS access while Brave is in the foreground.
- [ ] Programmatic background system-volume changes on iPhone.

## Immediate next experiment

**Siri-only control:** capture a Mac-triggered Siri invocation without touching either AirPod. Compare with both stem-triggered Siri recordings to determine whether the shared packet sequence is just Siri/microphone setup.

Then perform left/right **double-press** captures to isolate track-control events without the long-press/Siri audio pathway.

Detailed procedures, preliminary findings, uncertainties and milestone gates: [Research/protocol-findings.md](Research/protocol-findings.md).

## Roadmap

1. **Signal attribution:** differentiate Siri/audio-session traffic from actual stem commands.
2. **Earbud identity:** determine if left/right origin survives to a host-visible message.
3. **Press lifecycle:** detect hold start and release with usable latency.
4. **Mac proof of concept:** safely simulate and, if possible, map confirmed gestures to volume.
5. **iOS feasibility gate:** validate documented APIs and background behavior on a physical, non-jailbroken iPhone while Brave plays music.
6. **Product integration:** build a SwiftUI app only if the iOS gates can be met, or narrow scope to a Mac utility.

## Research references

- [AirPods BLE battery research](https://github.com/stuffz/airpods/blob/main/docs/ble-research.md)
- [airpods-ctl / AAP investigation](https://github.com/BorgoGustavo/airpods-ctl)
- [MousePods / AirPods 3 RemoteHID investigation](https://github.com/starman-tech/mousepods)

## Privacy and safety

Do not commit raw `.pklg`, `.pcap`, HCI captures, Bluetooth identifiers, serial numbers, or pairing data. Keep hardware firmware unchanged. No jailbreak or private iOS APIs in the initial scope.
