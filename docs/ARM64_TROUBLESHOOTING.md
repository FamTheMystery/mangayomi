# Linux ARM64 troubleshooting

## Wrong architecture

`bash scripts/build-linux-arm64.sh` requires `uname -m` to be `aarch64` or `arm64`. Do not solve this with QEMU, Box64, Waydroid, or another compatibility layer.

## Verify native libraries

```sh
bash scripts/check-arm64.sh build/linux/arm64/release/bundle/mangayomi
find build/linux/arm64/release/bundle -name '*.so*' -exec file {} \;
ldd build/linux/arm64/release/bundle/mangayomi
```

Every bundled ELF library must report AArch64. Missing `libmpv`, WebKitGTK, GTK, or codec libraries are system-package issues and should be fixed with the distro packages, not by copying x86 binaries.

## Display backend

Test Wayland and X11 independently. If WebView crashes only under one backend, record the backend, WebKitGTK version, and reproduction steps before changing plugin code.

## Low memory

Start with software video decoding and reduce application workload before attempting hardware acceleration. H618 hardware decoding depends on the kernel, FFmpeg/mpv build, and available V4L2/Cedrus support; the Mali GPU alone does not prove decoder support.
