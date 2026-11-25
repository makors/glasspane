#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
scripts/download-iso.sh
scripts/install-windows.sh
cat <<'MSG'

Windows installation is now running in a headless KVM VM.
Watch it with:
  scripts/qemu-screenshot.py

When QEMU exits after the automatic postinstall shutdown, run:
  scripts/package-image.sh
MSG
