#!/bin/bash
# projext repeatability probe: passive macOS bluetoothd log counts only.
# No root privileges, Bluetooth channel access, or raw-log exports.
set -u
if [[ "$(uname -s)" != "Darwin" ]]; then echo "macOS only"; exit 1; fi
umask 077
tmp="$(mktemp -d "${TMPDIR:-/tmp/}projext-repeat.XXXXXXXX")" || exit 1
logfile="$tmp/bluetoothd.log"
pid=""
cleanup() {
  if [[ -n "$pid" ]]; then
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  fi
  rm -rf "$tmp"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

echo "Projext Bluetooth repeatability probe — macOS"
echo "Raw log messages are never displayed or exported; temporary logs are removed on exit."
echo "Keep music playing with AirPods connected. Each window lasts 6 seconds."
echo "Perform TWO separated single presses during each stem window."
echo "Keep all other Bluetooth devices and activity as consistent as practical."
echo "Press Return to start logging."
read -r _
/usr/bin/log stream --style compact --level debug --predicate 'process == "bluetoothd"' > "$logfile" 2>/dev/null &
pid=$!
sleep 2
if ! kill -0 "$pid" 2>/dev/null; then
  echo "Unable to begin bluetoothd log stream"
  exit 1
fi
count() {
  wc -l < "$logfile" | tr -d '[:space:]'
}
measure() {
  local round="$1" phase="$2" text="$3" before after lines matching
  echo
  echo "Trial $round / $phase — $text"
  echo "Press Return, then perform the instructed action during the 6-second window."
  read -r _
  before="$(count)"
  echo "Measuring..."
  sleep 6
  after="$(count)"
  lines=$((after - before))
  if (( lines <= 0 )); then
    matching=0
    lines=0
  else
    matching="$(sed -n "$((before + 1)),$((after))p" "$logfile" | grep -Eic 'aap|stem|press|gesture|button|avrcp|l2cap|hid|airpods' || true)"
  fi
  printf 'RESULT round=%s phase=%s total=%s keyword=%s\n' "$round" "$phase" "$lines" "$matching"
}
# Counterbalanced ordering helps reduce order and time-trend effects.
measure 1 baseline "No presses"
measure 1 left "Two separate LEFT stem single presses"
measure 1 right "Two separate RIGHT stem single presses"
measure 1 baseline "No presses"
measure 2 baseline "No presses"
measure 2 right "Two separate RIGHT stem single presses"
measure 2 left "Two separate LEFT stem single presses"
measure 2 baseline "No presses"
measure 3 baseline "No presses"
measure 3 left "Two separate LEFT stem single presses"
measure 3 right "Two separate RIGHT stem single presses"
measure 3 baseline "No presses"
echo
echo "Complete. Compare repeated trials and adjacent no-press controls."
echo "Counts alone cannot identify a packet, a pressing earbud, or hold-start/release."
