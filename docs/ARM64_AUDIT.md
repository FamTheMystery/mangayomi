# Linux ARM64 audit

## Scope

This audit covers the repository state used for the ARM64 work. The target is native Ubuntu/Armbian AArch64 on the H618, with system GTK, WebKitGTK, and mpv libraries.

## Baseline

The development host for this change is Windows, so `flutter doctor -v`, `flutter pub get`, and `flutter build linux` could not be run here: Flutter/Dart are not installed and Windows cannot produce a native Linux build. Rust and Cargo are installed. The first real build must therefore run on an AArch64 Linux host or the ARM64 CI runner.

## Findings

| Area | Finding | Impact | Status |
|---|---|---|---|
| Flutter Linux | Cargokit already maps `linux-arm64` to `aarch64-unknown-linux-gnu`. | No Flutter rewrite indicated. | Code verified; build pending |
| Rust bridge | `rust/Cargo.toml` is a normal `cdylib`/`staticlib`; no x86-only crate is declared. | Rust should compile natively. | Build pending |
| Cargokit host selection | Linux previously used `arch` and treated every non-`aarch64` host as x86_64. | Could select the wrong target silently. | Fixed to use `uname -m` and fail closed |
| GTK/WebKit | Linux CMake uses system GTK and plugins; WebKitGTK is a package dependency. | Requires ARM64 distro development/runtime packages. | Pending on target |
| Media | The custom `media_kit_libs_video` package and system `libmpv` are architecture-sensitive. | Must inspect built bundle and `ldd` on ARM64. | Pending on target |
| Isar | `isar_community_flutter_libs` 3.3.2 downloads an x86-64 `libisar.so`; its Dart loader also rejects `Abi.linuxArm64`. | Build Isar Core from source, replace the library, and patch the loader's local-name mapping during the ARM build. | Fixed in ARM64 build script |
| Go torrent library | `go/build_go.sh` uses native `go build` for Linux, but the repository bundle can contain a stale x86-64 `.so`. | Must rebuild before Flutter packaging. | Fixed in ARM64 build script |
| Packaging | Existing release workflow and Arch package are x86_64-specific. | Existing release artifacts are not ARM64 packages. | ARM64 scripts added; release publication pending |

## Architecture-sensitive search results

- Linux CMake installs `libmtorrentserver.so` from `linux/bundle/lib`; the ARM64 script overwrites that location with a native Go build before Flutter packaging.
- Release workflow uses `build/linux/x64`, an x86_64 linuxdeploy AppImage, and RPM `BuildArch: x86_64`.
- Arch packaging declares `arch=('x86_64')`.
- Extension download selection currently returns `linux-x64-bundle.zip` only. The latest upstream release checked on 2026-08-25 has no Linux ARM64 asset, so this remains an upstream blocker; never substitute the x64 archive.
- Rust Cargokit already contains both Linux triples and `linux-arm64` Flutter mapping.

## Required evidence on AArch64

Run the ARM64 build script, then inspect the executable and all `.so` files with `file`, `readelf -h`, and `ldd`. A successful compile alone is not enough: system libraries, mpv, Isar, WebKit, and the Go library must all resolve to AArch64.
