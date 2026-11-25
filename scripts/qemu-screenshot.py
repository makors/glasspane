#!/usr/bin/env python3
"""Capture the headless QEMU VM display as a PNG."""
import os, socket, sys, time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sock_path = os.path.join(ROOT, 'state', 'qemu-monitor.sock')
out = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'state', 'screen.png'))
tmp = out + '.tmp.png'

try:
    os.unlink(tmp)
except FileNotFoundError:
    pass

s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.settimeout(5)
s.connect(sock_path)
s.sendall(f'screendump "{tmp}" -f png\n'.encode())
s.close()

deadline = time.time() + 5
while time.time() < deadline:
    if os.path.getsize(tmp) if os.path.exists(tmp) else 0:
        os.replace(tmp, out)
        print(out)
        break
    time.sleep(0.05)
else:
    raise SystemExit('timed out waiting for QEMU screendump')
