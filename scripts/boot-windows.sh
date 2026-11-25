#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f build/win10.raw ]; then
  echo 'build/win10.raw does not exist; run scripts/install-windows.sh first' >&2
  exit 1
fi
if [ -f state/qemu.pid ] && kill -0 "$(cat state/qemu.pid)" 2>/dev/null; then
  echo "QEMU is already running (pid $(cat state/qemu.pid))" >&2
  exit 1
fi

nix shell nixpkgs#qemu -c qemu-system-i386 \
  -machine pc,accel=kvm \
  -cpu coreduo \
  -smp 1 \
  -m 1024 \
  -rtc base=localtime \
  -nic none \
  -drive file=build/win10.raw,format=raw,if=ide,index=0,media=disk \
  -boot c \
  -vga std \
  -display none \
  -serial file:state/serial.log \
  -monitor unix:state/qemu-monitor.sock,server,nowait \
  -qmp unix:state/qemu-qmp.sock,server,nowait \
  -pidfile state/qemu.pid \
  -daemonize

echo "Windows booted in QEMU pid $(cat state/qemu.pid)"
