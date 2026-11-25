#!/usr/bin/env python3
"""Compress a saved v86 state and reference it from images/manifest.json."""
import json
import os
import shutil
import struct
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATE_RAW = os.path.join(ROOT, 'state', 'glasspane-state.bin')
STATE_ZST = STATE_RAW + '.zst'
STATE_META = STATE_RAW + '.meta.json'
OUTDIR = os.path.join(ROOT, 'images', 'win10')
OUT = os.path.join(OUTDIR, 'state.bin.zst')
MANIFEST = os.path.join(ROOT, 'images', 'manifest.json')


def state_memory_size(path):
    with open(path, 'rb') as f:
        header = f.read(16)
        if len(header) != 16:
            raise SystemExit('saved state is truncated')
        magic, version, total_length, info_length = struct.unpack('<IIII', header)
        if magic != 0x86768676 or version != 6 or total_length != os.path.getsize(path):
            raise SystemExit('saved state is not a valid v86 format-6 state')
        info = json.loads(f.read(info_length))
    return int(info['state'][0])


def atomic_json(path, value):
    tmp = path + '.tmp'
    with open(tmp, 'w') as f:
        json.dump(value, f, indent=2)
        f.write('\n')
    os.replace(tmp, path)


def main():
    if not os.path.exists(MANIFEST):
        raise SystemExit('missing images/manifest.json; run scripts/package-image.sh first')
    os.makedirs(OUTDIR, exist_ok=True)

    if not os.path.exists(STATE_RAW) and not os.path.exists(STATE_ZST):
        raise SystemExit('missing state/glasspane-state.bin; use Save state in the browser first')

    memory_size = state_memory_size(STATE_RAW) if os.path.exists(STATE_RAW) else 0
    if os.path.exists(STATE_META):
        with open(STATE_META) as f:
            meta = json.load(f)
        memory_size = int(meta.get('memory_size') or memory_size)
        with open(MANIFEST) as f:
            current = json.load(f)
        if meta.get('image_id') and current.get('image_id') and meta['image_id'] != current['image_id']:
            raise SystemExit('saved state was captured from a different disk image')

    tmp_out = OUT + '.tmp'
    if os.path.exists(STATE_ZST) and not os.path.exists(STATE_RAW):
        shutil.copyfile(STATE_ZST, tmp_out)
    else:
        with open(STATE_RAW, 'rb') as inp, open(tmp_out, 'wb') as out:
            subprocess.run(['zstd', '-q', '-f', '-19', '-T0', '-c'], stdin=inp, stdout=out, check=True)
    subprocess.run(['zstd', '-q', '-t', tmp_out], check=True)
    os.replace(tmp_out, OUT)

    with open(MANIFEST) as f:
        manifest = json.load(f)
    manifest['state_url'] = 'images/win10/state.bin.zst'
    manifest['state_compressed_bytes'] = os.path.getsize(OUT)
    if memory_size:
        manifest['memory_size'] = memory_size
    atomic_json(MANIFEST, manifest)

    print(f'[glasspane] installed {OUT} ({os.path.getsize(OUT) / 1024**2:.1f} MiB compressed)')


if __name__ == '__main__':
    main()
