#!/usr/bin/env python3
"""Compress a saved v86 state and reference it from images/manifest.json."""
import json
import os
import shutil
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATE_RAW = os.path.join(ROOT, 'state', 'glasspane-state.bin')
STATE_ZST = STATE_RAW + '.zst'
OUTDIR = os.path.join(ROOT, 'images', 'win10')
OUT = os.path.join(OUTDIR, 'state.bin.zst')
MANIFEST = os.path.join(ROOT, 'images', 'manifest.json')


def main():
    if not os.path.exists(MANIFEST):
        raise SystemExit('missing images/manifest.json; run scripts/package-image.sh first')
    os.makedirs(OUTDIR, exist_ok=True)

    if os.path.exists(STATE_ZST):
        shutil.copyfile(STATE_ZST, OUT)
    elif os.path.exists(STATE_RAW):
        with open(STATE_RAW, 'rb') as inp, open(OUT + '.tmp', 'wb') as out:
            subprocess.run(['zstd', '-q', '-f', '-19', '-T0', '-c'], stdin=inp, stdout=out, check=True)
        os.replace(OUT + '.tmp', OUT)
    else:
        raise SystemExit('missing state/glasspane-state.bin; use Save state in the browser first')

    with open(MANIFEST) as f:
        manifest = json.load(f)
    manifest['state_url'] = 'images/win10/state.bin.zst'
    manifest['state_compressed_bytes'] = os.path.getsize(OUT)
    with open(MANIFEST, 'w') as f:
        json.dump(manifest, f, indent=2)
        f.write('\n')

    print(f'[glasspane] installed {OUT} ({os.path.getsize(OUT) / 1024**2:.1f} MiB compressed)')


if __name__ == '__main__':
    main()
