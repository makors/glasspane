#!/usr/bin/env python3
"""Send one command to the headless QEMU human monitor."""
import os, socket, sys

if len(sys.argv) < 2:
    raise SystemExit('usage: qemu-monitor.py COMMAND...')
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sock_path = os.path.join(root, 'state', 'qemu-monitor.sock')
cmd = ' '.join(sys.argv[1:])
s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
s.settimeout(5)
s.connect(sock_path)
s.sendall((cmd + '\n').encode())
s.close()
