#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

payload='build/payload-root/$OEM$/$1/glasspane'
out=build/glasspane-payload.iso
driver=build/drivers/vmmouse-x86

if [ ! -f "$payload/install-payload.cmd" ]; then
  echo "Missing payload files — run scripts/make-unattend.sh first" >&2
  exit 1
fi
for file in vmmouse.inf vmmouse.cat vmmouse.sys; do
  if [ ! -f "$driver/$file" ]; then
    echo "Missing $driver/$file — run scripts/download-vmmouse.sh first" >&2
    exit 1
  fi
  cp -f "$driver/$file" "$payload/$file"
done

rm -f "$out"
nix shell nixpkgs#xorriso -c xorrisofs \
  -o "$out" \
  -V GLASSPANE \
  -J -R \
  build/payload-root >/dev/null

printf 'Created %s\n' "$out"
ls -lh "$out"
