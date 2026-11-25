# glasspane

Windows 10 running entirely in a browser tab. The x86 CPU, PC hardware, graphics, disk, keyboard, and mouse are emulated client-side by [v86](https://github.com/copy/v86); no VM is streamed from a server.

## Run

```sh
python3 serve.py 8000
```

Open <http://127.0.0.1:8000/>.

The generated Windows disk image is intentionally not committed. It is loaded lazily in compressed chunks over ordinary static HTTP, so the same directory can be deployed to any static file host that supports byte-range or normal file responses.

## Build the Windows image locally

Requirements: Linux with KVM, QEMU, mtools, zstd, curl, 7z, and about 20 GB of free disk space.

```sh
scripts/build-image.sh
```

This expects the official 32-bit Windows 10 22H2 consumer ISO (`Win10_22H2_English_x32v1.iso`) and performs an unattended BIOS/IDE install of Windows 10 Pro in headless QEMU. Microsoft’s generated ISO URLs expire after 24 hours, so `scripts/download-iso.sh` explains how to supply the current signed URL and verifies the fixed Microsoft-published SHA256. After QEMU powers off automatically, package the raw disk:

```sh
scripts/package-image.sh
python3 serve.py 8000
```

For a fast startup, let Windows reach the desktop in the browser, open the page with `?dev=1`, use **Save state**, then run `scripts/install-state.sh`. The saved v86 state is compressed and referenced as `initial_state`, causing later visits to restore directly to the desktop instead of booting from scratch.

Useful development modes:

- `?iso=1` boots the installer ISO directly as a compatibility test.
- `?ram=1024` changes guest RAM in MiB.
- `?dev=1` exposes the save-state control.
- `?autostart=1` starts the VM immediately without waiting for the Start button.

## Notes

- Windows 10 is 32-bit because v86 emulates a 32-bit x86 CPU.
- The installer media is ordinary Windows 10 Pro consumer media rather than evaluation media. The ISO does not include a license or activation entitlement; use it only with a valid Windows license. Redistribution of a preinstalled activated Windows image is not addressed by this project.
- Windows 10 is out of mainstream support. Treat networking as untrusted and prefer leaving network emulation disabled.
- Browser emulation is single-threaded and much slower than KVM. Responsiveness comes primarily from a small installation, lazy compressed disk loading, and restoring a saved state.
- Bundled v86 build: copy/v86 commit `9457e7a` or later, which includes NX-bit support required by Windows 10.
