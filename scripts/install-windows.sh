#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

ISO=${ISO:-iso/Win10_22H2_English_x32v1.iso}
DISK=${DISK:-build/win10.raw}
SIZE=${SIZE:-12G}
MONITOR=state/qemu-monitor.sock
PIDFILE=state/qemu.pid

mkdir -p state
exec 9>state/install.lock
if ! flock -n 9; then
  echo "Another install operation is running" >&2
  exit 1
fi

if [ ! -s "$ISO" ]; then
  echo "Missing $ISO — run scripts/download-iso.sh first" >&2
  exit 1
fi

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  echo "QEMU is already running (pid $(cat "$PIDFILE")); stop it before reinstalling" >&2
  exit 1
fi

scripts/make-unattend.sh >/dev/null
scripts/prepare-payload-iso.sh >/dev/null

if [ ! -f "$DISK" ]; then
  nix shell nixpkgs#qemu -c qemu-img create -f raw "$DISK" "$SIZE"
fi

rm -f "$MONITOR" state/qemu-qmp.sock "$PIDFILE" state/qemu.log

# Use legacy PC hardware close to v86: IDE disk, SeaBIOS-style boot, VGA.
# The installation itself is accelerated by KVM; the resulting raw disk is
# exported and run completely inside the browser.
nix shell nixpkgs#qemu -c qemu-system-i386 \
  -machine pc,accel=kvm \
  -cpu coreduo \
  -smp 1 \
  -m 1024 \
  -rtc base=localtime \
  -nic none \
  -drive file="$DISK",format=raw,if=ide,index=0,media=disk \
  -drive file="$ISO",format=raw,media=cdrom,if=ide,index=2,readonly=on \
  -drive file=build/glasspane-payload.iso,format=raw,media=cdrom,if=ide,index=3,readonly=on \
  -boot once=d \
  -vga std \
  -display none \
  -serial file:state/serial.log \
  -D state/qemu.log \
  -monitor unix:"$MONITOR",server,nowait \
  -qmp unix:state/qemu-qmp.sock,server,nowait \
  -pidfile "$PIDFILE" \
  -daemonize

echo "Windows installation started. QEMU pid: $(cat "$PIDFILE")"
echo "Screenshots: scripts/qemu-screenshot.py"
echo "The VM should power off automatically when postinstall completes."
