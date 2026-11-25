#!/usr/bin/env python3
"""Static file server for Glasspane with HTTP Range support."""
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
import os
import re
import sys
import threading
import json

ROOT = os.path.dirname(os.path.abspath(__file__))
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
BIND = sys.argv[2] if len(sys.argv) > 2 else '127.0.0.1'
UPLOAD_LOCK = threading.Lock()

PRIVATE_PATH_PARTS = {'.git', 'iso', 'build', 'state', '__pycache__'}

class Handler(SimpleHTTPRequestHandler):
    extensions_map = {
        **SimpleHTTPRequestHandler.extensions_map,
        '.js': 'text/javascript',
        '.mjs': 'text/javascript',
        '.wasm': 'application/wasm',
        '.zst': 'application/zstd',
        '.iso': 'application/octet-stream',
        '.img': 'application/octet-stream',
        '.json': 'application/json',
    }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def end_headers(self):
        self.send_header('Accept-Ranges', 'bytes')
        if self.path.startswith('/assets/'):
            self.send_header('Cache-Control', 'public, max-age=3600')
        else:
            self.send_header('Cache-Control', 'no-cache')
        super().end_headers()

    def range_unsatisfiable(self, size):
        self.send_response(416)
        self.send_header('Content-Range', f'bytes */{size}')
        self.send_header('Content-Length', '0')
        self.end_headers()
        return None

    def path_is_private(self, path):
        rel = os.path.relpath(path, ROOT)
        if rel == os.pardir or rel.startswith(os.pardir + os.sep):
            return True
        parts = [part for part in rel.split(os.sep) if part not in {'', '.'}]
        return bool(set(parts) & PRIVATE_PATH_PARTS) or any(part.startswith('.') for part in parts)

    def send_head(self):
        path = self.translate_path(self.path)
        if self.path_is_private(path):
            self.send_error(403)
            return None
        if os.path.isdir(path) or not os.path.exists(path):
            return super().send_head()

        range_header = self.headers.get('Range')
        if not range_header:
            return super().send_head()

        value = range_header.strip()
        if ',' in value:
            return super().send_head()

        explicit = re.fullmatch(r'bytes=(\d+)-(\d*)', value)
        suffix = re.fullmatch(r'bytes=-(\d+)', value)
        if not explicit and not suffix:
            return super().send_head()

        size = os.path.getsize(path)
        if suffix:
            suffix_length = int(suffix.group(1))
            if suffix_length == 0 or size == 0:
                return self.range_unsatisfiable(size)
            start = max(size - suffix_length, 0)
            end = size - 1
        else:
            start = int(explicit.group(1))
            end = int(explicit.group(2)) if explicit.group(2) else size - 1
            end = min(end, size - 1)

        if start >= size or start > end:
            return self.range_unsatisfiable(size)

        length = end - start + 1
        self.send_response(206)
        self.send_header('Content-Type', self.guess_type(path))
        self.send_header('Content-Range', f'bytes {start}-{end}/{size}')
        self.send_header('Content-Length', str(length))
        self.end_headers()

        f = open(path, 'rb')
        f.seek(start)
        return RangeFile(f, length)

    def do_POST(self):
        if self.client_address[0] not in {'127.0.0.1', '::1'}:
            self.send_error(403)
            return
        if self.path != '/upload-state':
            self.send_error(404)
            return
        try:
            length = int(self.headers.get('Content-Length', ''))
        except ValueError:
            self.send_error(411)
            return
        if length < 16:
            self.send_error(400)
            return

        os.makedirs(os.path.join(ROOT, 'state'), exist_ok=True)
        target = os.path.join(ROOT, 'state', 'glasspane-state.bin')
        tmp = target + f'.tmp.{os.getpid()}.{threading.get_ident()}'
        remaining = length
        try:
            with UPLOAD_LOCK, open(tmp, 'wb') as out:
                while remaining:
                    data = self.rfile.read(min(1024 * 1024, remaining))
                    if not data:
                        break
                    out.write(data)
                    remaining -= len(data)
                if remaining:
                    raise ValueError('truncated upload')
                out.flush()
                os.fsync(out.fileno())

            with open(tmp, 'rb') as uploaded:
                header = uploaded.read(16)
            magic, version, total_length, info_length = int.from_bytes(header[0:4], 'little'), int.from_bytes(header[4:8], 'little'), int.from_bytes(header[8:12], 'little'), int.from_bytes(header[12:16], 'little')
            if magic != 0x86768676 or version != 6 or total_length != length or info_length > length - 16:
                raise ValueError('invalid v86 state header')
            os.replace(tmp, target)
            image_id = self.headers.get('X-Glasspane-Image-Id', '')
            memory_size = self.headers.get('X-Glasspane-Memory-Size', '')
            if image_id or memory_size:
                meta = {
                    'image_id': image_id if all(c in '0123456789abcdef' for c in image_id.lower()) and len(image_id) <= 64 else '',
                    'memory_size': int(memory_size) if memory_size.isdigit() else 0,
                }
                meta_target = target + '.meta.json'
                meta_tmp = meta_target + f'.tmp.{os.getpid()}.{threading.get_ident()}'
                with open(meta_tmp, 'w') as meta_file:
                    json.dump(meta, meta_file, indent=2)
                    meta_file.write('\n')
                os.replace(meta_tmp, meta_target)
        except (OSError, ValueError):
            try:
                os.unlink(tmp)
            except FileNotFoundError:
                pass
            self.send_error(400)
            return

        self.send_response(200)
        self.send_header('Content-Length', '2')
        self.end_headers()
        self.wfile.write(b'ok')

    def copyfile(self, source, outputfile):
        while True:
            chunk = source.read(256 * 1024)
            if not chunk:
                break
            outputfile.write(chunk)

class RangeFile:
    def __init__(self, file, remaining):
        self.file = file
        self.remaining = remaining
    def read(self, size=-1):
        if self.remaining <= 0:
            return b''
        if size < 0 or size > self.remaining:
            size = self.remaining
        data = self.file.read(size)
        self.remaining -= len(data)
        if self.remaining <= 0:
            self.file.close()
        return data
    def close(self):
        self.file.close()

if __name__ == '__main__':
    os.chdir(ROOT)
    print(f'Glasspane listening on http://{BIND}:{PORT}/')
    ThreadingHTTPServer((BIND, PORT), Handler).serve_forever()
