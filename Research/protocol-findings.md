# AirPods 3 Gesture Protocol Research

## Goal

Determine whether AirPods (3rd generation) transmit independently identifiable LEFT and RIGHT stem long-press start and release signals that third-party software can observe.

**Target experience:** While AirPods 3 are connected to an iPhone, hold the left stem to decrease volume, hold the right stem to increase volume, and release to stop. This should eventually work with audio playing in Brave and other apps.

**Status:** Hypothesis only. Left/right battery status is documented in reverse-engineered Bluetooth packets, but does not establish left/right gesture events.

## Known constraints

- AirPods 3 force-sensor press-and-hold normally invokes Siri.
- Separate left and right battery fields do **not** prove that the earbuds broadcast separate radio messages, nor that battery packets encode gesture state.
- A device or case may relay battery information about both earbuds.
- Standard macOS media commands might omit which AirPod initiated an action.
- Public iOS APIs do not document arbitrary interception of AirPods 3 stem events; installing via Xcode does not override those API limits.
- Even if gesture detection works on macOS, iOS background operation and system volume control while Brave plays audio require independent validation.

## Questions to answer

1. Does either stem produce a host-visible event on long-press **start**?
2. Is **release** observable, or only a completed long-press command?
3. Can events distinguish LEFT and RIGHT?
4. Can Siri activation be disabled or avoided without private APIs or AirPods firmware changes?
5. If macOS can observe the data, can a non-jailbroken iPhone app access the same data while Brave is foregrounded?
6. Can that iPhone app legitimately change output volume automatically in that state?

## Experiment plan (when AirPods and a Mac are available)

Record device model, firmware, macOS version, transport, and active audio route.

| Trial | Action | Duration | Repetitions |
|---|---|---:|---:|
| A | No touching either stem (baseline) | 30 seconds | 1 |
| B | Left stem press-and-hold, then release | 3 seconds | 5 |
| C | Right stem press-and-hold, then release | 3 seconds | 5 |
| D | Left stem double-press | short | 5 |
| E | Right stem double-press | short | 5 |
| F | Left stem triple-press | short | 5 |
| G | Right stem triple-press | short | 5 |

Log host-side timestamps for start/release as observed by the operator, media commands, accessible Bluetooth events, and whether Siri activates.

### Analysis

- First compare OS-exposed media/HID events; do **not** assume raw sensor data is accessible.
- If insufficient, inspect published AAP/L2CAP and BLE research, distinguishing AirPods 3 evidence from AirPods Pro findings.
- Compare repeatable message changes between baseline, left press, right press, and release.
- Ignore unrelated battery drift, periodic advertisements, and rotating Bluetooth addresses.
- Do not interpret a battery-field difference as a gesture event without replicated evidence.

## Success gates

- **Gate 1:** Some reproducible, host-visible signal correlates with a long press.
- **Gate 2:** Distinct left/right origin is reliably identified.
- **Gate 3:** Hold start and release are detectable with latency suitable for continuous volume adjustment.
- **Gate 4:** Events are accessible through an acceptable iOS mechanism when another app is active.
- **Gate 5:** System audio volume can be changed under those conditions without a jailbreak or firmware modification.

Failure of Gate 2 or Gate 4 blocks the exact requested experience; a macOS-only or manual control alternative can still be developed.

## Safety and logging

Do not flash or modify AirPods firmware. Avoid pairing secrets, device identifiers, personal Bluetooth captures, and packet dumps containing private data in commits. Keep captures local and redact addresses before sharing.

## External research starting points

- [AirPods BLE research](https://github.com/stuffz/airpods/blob/main/docs/ble-research.md) — left/right battery fields; not proof of gesture identifiers.
- [airpods-ctl](https://github.com/BorgoGustavo/airpods-ctl) — AAP/L2CAP investigation; model-specific findings require verification.
- [MousePods](https://github.com/starman-tech/mousepods) — AirPods 3 RemoteHID research for motion data; not a confirmed stem event solution.
- [Apple AirPods controls](https://support.apple.com/guide/airpods/) — documented supported controls.

## Next implementation task

Create a macOS event logger that timestamps observable media events while the operator executes the trial matrix. Do not begin a full iPhone volume controller until the event-identity feasibility gate is met.

---

## Experiment log — 2026-11-13

### Equipment and setup

- AirPods (3rd generation) connected wirelessly to MacBook Air M4; charging case was initially connected via Lightning.
- AirPods firmware shown by macOS: `6F21` (as observed in Terminal screenshot).
- `system_profiler SPBluetoothDataType` confirmed Bluetooth connectivity and independent left/right battery readings.
- `ioreg -r -c IOHIDDevice -l | grep -i -C 5 "AirPods"` produced no matches; this does **not** rule out connected AAP or other events.
- PacketLogger initially showed zero records, then live logging became operational. For captures, the requested settings were **All Devices**, **All Handles**, **All Packet Types**, with no search restriction. PacketLogger has an **AAP Receive** view, but the full captures were requested unfiltered.

### Files recorded locally (not committed)

- Exploratory: `left_stem_hold_1.pklg`, `right_stem_hold_1.pklg`.
- Controlled: `baseline.pklg`, `left_stem_hold_2.pklg`, `right_stem_hold_2.pklg`.

The controlled trials used a planned timeline: 0–2 s untouched, 2–5 s stem held, 5–7 s untouched; baseline approximately 10 s. Human-operated timing is approximate, not instrumented ground truth.

### Preliminary analysis reported during the session

| Capture | Reported packet records | Reported incoming ACL packets |
|---|---:|---:|
| Baseline | 958 | 0 |
| Left hold (controlled) | 1,209 | 253 |
| Right hold (controlled) | 965 | 189 |

Preliminary examination reported a shared incoming sequence in *both* controlled hold recordings:

```text
1B 10 00 01 00 01 01 02
```

Reported first occurrence relative to recording start: left ~4.48 seconds; right ~3.55 seconds; not observed in the baseline.

**Critical caveat:** These are exploratory observations from the session, not a decoded AAP gesture specification or replicated proof of event identity. Packet offsets, channel framing, and payload interpretation remain unverified. Differences in total traffic may be caused by connection state, sampling conditions, or Siri's microphone/audio stream.

**User-confirmed observation:** Siri activated when *either* stem was held. Therefore a stronger competing hypothesis is that the shared sequence and incoming traffic are Siri/audio-session related, **not** left/right stem identifiers.

### Next experiment: Siri-only control (priority 1)

1. Keep both AirPods connected as Mac audio output/input.
2. Set PacketLogger to All Devices / All Handles / All Packet Types; start a fresh capture.
3. Leave stems untouched for about 2 seconds.
4. Activate Siri through a Mac UI/keyboard shortcut — **do not touch the AirPods**.
5. Let Siri stay open silently for ~3 seconds; dismiss it and capture ~2 seconds more.
6. Stop and save privately as `siri_mac_control.pklg`.
7. Log how Siri was invoked, approximate timestamps, whether the microphone was engaged, and any audible/UI behavior.

**Analysis:** Compare the candidate sequence and subsequent incoming burst to stem-triggered Siri traces. Matching traffic supports the Siri/session hypothesis; mismatching traffic merely identifies another candidate requiring replication, not proof of a stem identifier.

### Next experiment: double-press controls (priority 2)

Capture baseline + left/right double-press trials separately, ideally five repetitions, while a local audio player is able to accept track commands. Note whether the track changes. Compare decoded host events and connected AAP messages for a differentiable earbud-source field. Track navigation may map to the same host command regardless of side.

### Evidence needed to advance

1. A repeatable event tightly correlated with stem press rather than Siri activation.
2. A stable and independently validated left/right distinction (not inferred from battery fields).
3. Separate press-start and release indicators with appropriate timing.
4. A supported route to receive these events on a non-jailbroken iPhone while Brave runs.
5. A supported method to adjust iPhone output volume while another app has foreground audio.

No iOS app integration should be presented as viable until gates 4 and 5 are tested. `MPVolumeView` is a user-facing volume interface; it is not evidence of a general public API to automatically set system volume in the background.

### Capture security

Keep raw packet captures out of the public repository: they may include Bluetooth addresses, traffic metadata, or pairing-related information. Commit only sanitized summaries and non-sensitive pseudocode or test fixtures.
