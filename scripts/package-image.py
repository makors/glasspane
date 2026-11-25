#!/usr/bin/env python3
"""Split a raw disk into zstd-compressed fixed-size chunks for v86."""
import concurrent.futures
import json
import os
import shutil
import subprocess
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
INFILE = os.environ.get('INFILE', os.path.join(ROOT, 'build', 'win10.raw'))
OUTDIR = os.environ.get('OUTDIR', os.path.join(ROOT, 'images', 'win10'))
MANIFEST = os.environ.get('MANIFEST', os.path.join(ROOT, 'images', 'manifest.json'))
CHUNK = int(os.environ.get('CHUNK_SIZE', str(1024 * 1024)))
LEVEL = os.environ.get('ZSTD_LEVEL', '19')
JOBS = int(os.environ.get('ZSTD_JOBS', str(max(2, min(8, os.cpu_count() or 2)))))

def compress_one(item):
    index, data = item
    offset = index * CHUNK
    end = offset + CHUNK
    dst = os.path.join(OUTDIR, f'chunk-{offset}-{end}.zst')
    tmp = dst + '.tmp'
    with open(tmp, 'wb') as out:
        subprocess.run(['zstd', '-q', '-f', '-' + LEVEL, '-c'], input=data, stdout=out, check=True)
    os.replace(tmp, dst)
    return index

def chunks():
    count = 0
    with open(INFILE, 'rb', buffering=16 * 1024 * 1024) as f:
        while True:
            data = f.read(CHUNK)
            if not data:
                break
            if len(data) < CHUNK:
                data += bytes(CHUNK - len(data))
            yield count, data
            count += 1

def main():
    if not os.path.exists(INFILE):
        raise SystemExit(f'missing {INFILE}; run scripts/install-windows.sh first')
    if not shutil.which('zstd'):
        raise SystemExit('zstd is required')

    size = os.path.getsize(INFILE)
    if size % 512:
        raise SystemExit('raw disk size is not a multiple of 512 bytes')
    if CHUNK <= 0 or CHUNK & (CHUNK - 1):
        raise SystemExit('CHUNK_SIZE must be a power of two')

    os.makedirs(OUTDIR, exist_ok=True)
    for name in os.listdir(OUTDIR):
        if name.startswith('chunk-') and name.endswith('.zst'):
            os.unlink(os.path.join(OUTDIR, name))

    expected = (size + CHUNK - 1) // CHUNK
    print(f'[glasspane] compressing {size / 1024**3:.2f} GiB into {expected} chunks using {JOBS} workers')
    started = time.time()
    source = iter(chunks())
    done = 0

    with concurrent.futures.ThreadPoolExecutor(max_workers=JOBS) as pool:
        pending = set()
        exhausted = False
        while pending or not exhausted:
            while not exhausted and len(pending) < JOBS * 2:
                try:
                    pending.add(pool.submit(compress_one, next(source)))
                except StopIteration:
                    exhausted = True
            if not pending:
                break
            finished, pending = concurrent.futures.wait(pending, return_when=concurrent.futures.FIRST_COMPLETED)
            for future in finished:
                future.result()
                done += 1
                if done % 250 == 0 or done == expected:
                    print(f'[glasspane] {done}/{expected} chunks in {time.time() - started:.1f}s')

    if done != expected:
        raise SystemExit(f'packaged {done} chunks, expected {expected}')

    total_compressed = sum(
        os.path.getsize(os.path.join(OUTDIR, n))
        for n in os.listdir(OUTDIR)
        if n.startswith('chunk-') and n.endswith('.zst')
    )
    manifest = {
        'name': 'Windows 10 Enterprise LTSC 2021 Evaluation (32-bit)',
        'url': 'images/win10/chunk.zst',
        'size': size,
        'fixed_chunk_size': CHUNK,
        'chunks': expected,
        'compressed_bytes': total_compressed,
        'created': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
    }

    state_raw = os.path.join(ROOT, 'state', 'glasspane-state.bin')
    state_compressed = state_raw + '.zst'
    state_out = os.path.join(OUTDIR, 'state.bin.zst')
    if os.path.exists(state_compressed):
        shutil.copyfile(state_compressed, state_out)
    elif os.path.exists(state_raw):
        with open(state_raw, 'rb') as inp, open(state_out, 'wb') as out:
            subprocess.run(['zstd', '-q', '-f', '-19', '-T0', '-c'], stdin=inp, stdout=out, check=True)
    if os.path.exists(state_out):
        manifest['state_url'] = 'images/win10/state.bin.zst'
        manifest['state_compressed_bytes'] = os.path.getsize(state_out)

    os.makedirs(os.path.dirname(MANIFEST), exist_ok=True)
    with open(MANIFEST, 'w') as f:
        json.dump(manifest, f, indent=2)
        f.write('\n')

    print(f'[glasspane] wrote {expected} chunks, {total_compressed / 1024**2:.1f} MiB compressed')
    print(f'[glasspane] manifest: {MANIFEST}')

if __name__ == '__main__':
    main()
