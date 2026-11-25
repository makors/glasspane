#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p iso
url='https://software-download.microsoft.com/download/db/444969d5-f34g-4e03-ac9d-1f9786c69161/19044.1288.211006-0501.21h2_release_svc_refresh_CLIENT_LTSC_EVAL_x86FRE_en-us.iso'
out='iso/windows10-ltsc-x86-eval.iso'
expected_size=3452129280
expected_sha256='aa72ffc89fa544f2f6f6771c85478eeb7b59bfe6cbdeaa05493042d4a0a856d6'
if [ "$(stat -c%s "$out" 2>/dev/null || echo 0)" != "$expected_size" ]; then
  curl -fL --retry 3 -C - -o "$out" "$url"
fi
actual_size=$(stat -c%s "$out")
[ "$actual_size" = "$expected_size" ] || { echo "Unexpected ISO size: $actual_size" >&2; exit 1; }
actual_sha256=$(sha256sum "$out" | awk '{print $1}')
if [ "$actual_sha256" != "$expected_sha256" ]; then
  echo "Unexpected ISO SHA256: $actual_sha256" >&2
  exit 1
fi
echo "Verified ISO SHA256: $actual_sha256"
