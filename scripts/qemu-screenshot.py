#!/usr/bin/env python3
"""Capture the headless QEMU VM display as a PNG (or raw PPM fallback)."""
import os, socket, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sock_path = os.path.join(ROOT, 'state', 'qemu-monitor.sock')
ppm = os.path.join(ROOT, 'state', 'screen.ppm')
out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'state', 'screen.png')
if not out.endswith('.ppm'):
    out_ppm = ppm
else:
    out_ppm = out

try:
    os.unlink(ppm)
except FileNotFoundError:
    pass

s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.settimeout(5)
s.connect(sock_path)
s.sendall(f'screendump {ppm}\n'.encode())
s.close()

if out != out_ppm:
    if subprocess.run(['bash','-lc','command -v magick >/dev/null']).returncode == 0:
        subprocess.run(['magick', out_ppm, out], check=True)
    else:
        print(out_ppm)
        sys.exit(0)
print(out)
