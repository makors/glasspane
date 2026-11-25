#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p iso

out='iso/Win10_22H2_English_x32v1.iso'
expected_size=4308279296
expected_sha256='ac0b7045b6c3a72a4d46daab0944e109a55d9ede3a11b775fdb57c2dd3fca2ef'

if [ "$(stat -c%s "$out" 2>/dev/null || echo 0)" != "$expected_size" ]; then
  url=${WIN10_ISO_URL:-}
  if [ -z "$url" ]; then
    cat >&2 <<'MSG'
Missing the official Windows 10 22H2 x86 consumer ISO.

Open https://www.microsoft.com/en-us/software-download/windows10ISO from a
non-Windows browser/user agent, choose "Windows 10 (multi-edition ISO)" →
"English" → "32-bit Download", then either save it as:

  iso/Win10_22H2_English_x32v1.iso

or rerun this script with the temporary signed Microsoft URL:

  WIN10_ISO_URL='https://software.download.prss.microsoft.com/...' scripts/download-iso.sh

Microsoft expires generated URLs after 24 hours, so one is not hard-coded.
MSG
    exit 1
  fi
  case "$url" in
    https://software.download.prss.microsoft.com/*Win10_22H2_English_x32v1.iso*) ;;
    *) echo "WIN10_ISO_URL is not a Microsoft x32 ISO URL" >&2; exit 1 ;;
  esac
  curl -fL --retry 8 --retry-all-errors -C - -o "$out" "$url"
fi

actual_size=$(stat -c%s "$out")
[ "$actual_size" = "$expected_size" ] || { echo "Unexpected ISO size: $actual_size" >&2; exit 1; }
actual_sha256=$(sha256sum "$out" | awk '{print $1}')
if [ "$actual_sha256" != "$expected_sha256" ]; then
  echo "Unexpected ISO SHA256: $actual_sha256" >&2
  exit 1
fi
echo "Verified ISO SHA256: $actual_sha256"
