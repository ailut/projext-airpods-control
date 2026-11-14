#!/bin/bash
# macOS-only, read-only bluetoothd log comparison.
# No sudo, device reconnect, PSM opens, or security setting changes.
set -u

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This diagnostic requires macOS."
  exit 1
fi
if ! command -v log >/dev/null 2>&1; then
  echo "macOS unified logging utility not found."
  exit 1
fi

umask 077
tmp="$(mktemp -d "${TMPDIR:-/tmp/}projext-bluetooth-log.XXXXXXXX")" || exit 1
logfile="$tmp/bluetoothd.log"
pid=""
cleanup() {
  if [[ -n "$pid" ]]; then
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  fi
  rm -rf "$tmp"
}
trap cleanup EXIT INT TERM

echo "projext macOS Bluetooth live-log probe"
echo "Only anonymous counts are displayed; raw logs stay in a temporary private folder"
echo "and are deleted on exit. No Bluetooth connection changes will be made."
echo "This test may produce no records: unified logging can redact or suppress messages."
echo
echo "Connect AirPods, start music, and press Return to begin."
read -r _

/usr/bin/log stream --style compact --level debug --predicate 'process == "bluetoothd"' >"$logfile" 2>/dev/null &
pid=$!
sleep 2
if ! kill -0 "$pid" 2>/dev/null; then
  echo "Unable to start the unified-log stream. Check macOS logging access."
  exit 1
fi

snapshot() {
  wc -l < "$logfile" | tr -d '[:space:]'
}
summarize() {
  local phase="$1" start="$2" stop="$3"
  # log may contain Bluetooth device information. Never output matching raw lines.
  local total relevant
  total=$((stop - start))
  if [[ "$total" -lt 0 ]]; then total=0; fi
  if [[ "$total" -eq 0 ]]; then
    relevant=0
  else
    relevant="$(sed -n "$((start + 1)),$((stop))p" "$logfile" | grep -Eic 'aap|stem|press|gesture|button|avrcp|l2cap|hid|airpods' || true)"
  fi
  echo "RESULT phase=$phase total_bluetoothd_lines=$total keyword_lines=$relevant"
}
run_phase() {
  local name="$1" instructions="$2" start stop
  echo
  echo "$name: $instructions"
  echo "Press Return to start a 6-second measurement."
  read -r _
  start="$(snapshot)"
  echo "Measuring $name now..."
  sleep 6
  stop="$(snapshot)"
  summarize "$name" "$start" "$stop"
}
echo "The next four windows each last six seconds."
run_phase baseline "Do not touch the earbuds or keyboard; leave music playing."
run_phase left "Press LEFT AirPod stem twice (two separated single presses)."
run_phase right "Press RIGHT AirPod stem twice (two separated single presses)."
run_phase keyboard "Press the Mac's physical Play/Pause key twice."
echo
echo "Probe complete. Compare counts, not packet content."
echo "A count difference is NOT proof of a stem event; no difference does NOT rule one out."
echo "No raw log files have been preserved."
