# Checkpoint — 2026-11-13 (macOS-first AirPods 3 volume remapping)

## Goal
Explore undocumented hardware/protocol capabilities to remap AirPods 3 stem holds on macOS: left hold = lower volume, right hold = raise volume, release = stop. An Apple public-API limitation is an engineering constraint to investigate, not automatic proof of impossibility. Keep experiments controlled and reversible. iOS is deferred.

## Verified working
- Mac Swift package builds; 6/6 unit tests pass (3 GestureCore, 3 PacketLogger parser).
- Explicit `swift run projext-diagnostic volume-step down 1` and `up 1` change actual macOS default output volume by 5 percentage points.
- `bluetooth-inspect` finds paired and connected AirPods.
- Offline PacketLogger `.pklg` analyzer parses 25 recordings: 21/21 physical press recordings had a tentative side-associated candidate, with 0/4 no-stem controls. No confirmed press/release semantics.
- Corrected timestamp baseline ignores old PacketLogger metadata. 1s left/right candidates +3.406/+3.772s; 3s +7.276/+7.112s; 5s +8.652/+9.149s relative to first HCI record, **not** gesture onset.
- AppKit monitor sees no AirPods events. Quartz event tap receives keyboard media-key presses but no AirPods presses.
- `bluetoothd` unified logs can be read live but aggregate line and keyword counts overlap between controls and stem conditions; the repeatability trial falsified use of these counts as a gesture sensor.

## Main blocker
No verified low-latency live event stream on stock macOS that identifies left/right AirPods 3 stem **hold-start and release** while the earphones are connected and playing audio. PacketLogger capture does not prove a normal app can receive those messages live. Do **not** wire aggregate `bluetoothd` counts to volume output.

## Next technical session
1. Inspect concrete open-source macOS AirPods/AAP/Bluetooth research, including implementations, not only README claims. Distinguish AirPods Pro 2 observations from AirPods 3 hardware.
2. Enumerate possible event-level sources: PacketLogger's acquisition path, diagnostic HCI interfaces, private macOS frameworks/IPC, and any viable read-only capture route. Record permission and reliability requirements.
3. Choose a minimal read-only event-level experiment first; preserve audio connection and system recovery path. If any approach requires intrusive system-level changes, document risks and rollback **before** execution.
4. Obtain timestamps of real **live individual packets**, compare to the offline candidate signature and controls, then determine whether press-onset and release are observable.
5. Only after validated live events, integrate with the already-working volume actuator and GestureCore.

## Local project
`~/Developer/projext-airpods-control`. Private raw recordings are at `~/Documents/*.pklg`; keep them out of GitHub. Repo: `ailut/projext-airpods-control`. To resume: `cd ~/Developer/projext-airpods-control && git pull && swift test`.

## Research standard
Proactively investigate feasible workarounds beyond Apple's public APIs, but distinguish tested facts, experimental hypotheses, and unsupported claims. Do not ask the user to rerun broad `bluetoothd` count probes.
