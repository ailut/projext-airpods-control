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
