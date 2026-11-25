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

qemu-system-x86_64 \
  -machine pc,accel=kvm \
  -cpu max \
  -smp 4 \
  -m 2048 \
  -rtc base=localtime \
  -drive file=build/win10.raw,format=raw,if=ide,index=0,media=disk \
  -drive file=build/unattend.img,format=raw,if=floppy \
  -boot c \
  -netdev user,id=n0 \
  -device e1000,netdev=n0 \
  -vga std \
  -display none \
  -serial file:state/serial.log \
  -monitor unix:state/qemu-monitor.sock,server,nowait \
  -pidfile state/qemu.pid \
  -daemonize

echo "Windows booted in QEMU pid $(cat state/qemu.pid)"
