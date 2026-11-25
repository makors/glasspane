#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

ISO=${ISO:-iso/windows10-ltsc-x86-eval.iso}
DISK=${DISK:-build/win10.raw}
SIZE=${SIZE:-12G}
MONITOR=state/qemu-monitor.sock
PIDFILE=state/qemu.pid

if [ ! -s "$ISO" ]; then
  echo "Missing $ISO — run scripts/download-iso.sh first" >&2
  exit 1
fi

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  echo "QEMU is already running (pid $(cat "$PIDFILE")); stop it before reinstalling" >&2
  exit 1
fi

scripts/make-unattend.sh >/dev/null

if [ ! -f "$DISK" ]; then
  nix shell nixpkgs#qemu -c qemu-img create -f raw "$DISK" "$SIZE"
fi

rm -f "$MONITOR" "$PIDFILE" state/qemu.log

# Use legacy PC hardware close to v86: IDE disk, SeaBIOS-style boot, VGA.
# The installation itself is accelerated by KVM; the resulting raw disk is
# exported and run completely inside the browser.
nix shell nixpkgs#qemu -c qemu-system-x86_64 \
  -machine pc,accel=kvm \
  -cpu max \
  -smp 4 \
  -m 2048 \
  -rtc base=localtime \
  -drive file="$DISK",format=raw,if=ide,index=0,media=disk \
  -drive file="$ISO",format=raw,media=cdrom,if=ide,index=2,readonly=on \
  -drive file=build/unattend.img,format=raw,if=floppy \
  -boot once=d \
  -netdev user,id=n0 -device e1000,netdev=n0 \
  -vga std \
  -display none \
  -serial file:state/serial.log \
  -D state/qemu.log \
  -monitor unix:"$MONITOR",server,nowait \
  -pidfile "$PIDFILE" \
  -daemonize

echo "Windows installation started. QEMU pid: $(cat "$PIDFILE")"
echo "Screenshots: scripts/qemu-screenshot.py"
echo "The VM should power off automatically when postinstall completes."
