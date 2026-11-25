#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

url1='https://packages.vmware.com/tools/releases/12.4.5/windows/x86/VMware-tools-12.4.5-23787635-i386.exe'
url2='https://packages-prod.broadcom.com/tools/releases/12.4.5/windows/x86/VMware-tools-12.4.5-23787635-i386.exe'
sha256='5229bbf3d3c8bf4a84e04eb8a2cfc675d48257034e17346e21af218fb7285c19'
out='build/drivers/vmware-tools-x86.exe'
tmp='build/drivers/mouse-tmp'
dst='build/drivers/vmmouse-x86'

mkdir -p build/drivers
if [ ! -s "$out" ]; then
  curl -fL --retry 3 -o "$out.tmp" "$url1" || curl -fL --retry 3 -o "$out.tmp" "$url2"
  printf '%s  %s\n' "$sha256" "$out.tmp" | sha256sum -c -
  mv "$out.tmp" "$out"
fi
printf '%s  %s\n' "$sha256" "$out" | sha256sum -c - >/dev/null

rm -rf "$tmp" "$dst"
mkdir -p "$tmp" "$dst"
7z x -y "$out" Mouse.cab -o"$tmp" >/dev/null
7z x -y "$tmp/Mouse.cab" -o"$tmp/mouse" >/dev/null
cp "$tmp"/mouse/vmmouse.inf_Win8.* "$dst/vmmouse.inf"
cp "$tmp"/mouse/vmmouse.cat_Win8.* "$dst/vmmouse.cat"
cp "$tmp"/mouse/vmmouse.sys_Win8.* "$dst/vmmouse.sys"
rm -rf "$tmp"
echo "Extracted VMware vmmouse driver to $dst"
