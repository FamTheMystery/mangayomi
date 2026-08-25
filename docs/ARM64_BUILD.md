# Linux ARM64 build

## Native target

The supported target is `aarch64-unknown-linux-gnu` on Ubuntu/Armbian. The build must run on a machine reporting `aarch64` from `uname -m`; the script intentionally rejects x86_64 because it is a native-build path.

## Packages

```sh
sudo apt update
sudo apt install -y webkit2gtk-4.1 clang cmake ninja-build pkg-config \
  libgtk-3-dev mpv libmpv-dev dpkg-dev libblkid-dev liblzma-dev \
  libjpeg-dev libpng-dev libavif-dev libsecret-1-dev
```

Install Flutter stable, Rust/Cargo, and `flutter_rust_bridge_codegen` as required by the repository.

## Build

```sh
uname -m
bash scripts/build-linux-arm64.sh
```

Outputs are placed under `build/linux/arm64/release/`:

- `Mangayomi-linux-arm64.tar.gz`
- `mangayomi-linux-arm64.deb`

The Debian package uses system GTK/WebKitGTK/mpv libraries and does not bundle an emulated or foreign-architecture runtime.
