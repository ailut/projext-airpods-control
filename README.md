# projext-airpods-control

Experimental research and development project for custom AirPods (3rd generation) stem gesture controls on macOS and iOS.

## Objective

- Hold the **left** AirPod stem to decrease volume.
- Hold the **right** AirPod stem to increase volume.
- Release to stop changing volume.
- Ultimately operate while music is playing from Brave on an iPhone.

**Feasibility has not been established.** AirPods left/right battery identity does not prove that left/right long-press events are available to third-party apps.

## Current status

Phase 1 — Document protocol assumptions and design a repeatable diagnostic experiment.

Read [Research/protocol-findings.md](Research/protocol-findings.md) for the test matrix, technical constraints, evidence, and success gates.

## Roadmap

1. Observe host-visible stem press and release events on macOS.
2. Determine whether left and right stem events are distinguishable.
3. Validate iOS background access and system-volume restrictions.
4. Prototype volume-control logic using simulated events.
5. Integrate live gestures only if the feasibility gates pass.

## Development principles

No jailbreak, firmware flashing, or private iOS APIs in the first phase. Do not commit raw Bluetooth captures containing private identifiers.
