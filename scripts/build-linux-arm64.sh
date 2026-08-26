#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

fail() {
  printf 'ERROR: %s\n' "$1" >&2
  exit 1
}

command -v flutter >/dev/null || fail 'Flutter is required.'
command -v cargo >/dev/null || fail 'Rust/Cargo is required.'
command -v go >/dev/null || fail 'Go 1.25 or newer is required.'
command -v git >/dev/null || fail 'Git is required to build Isar Core.'
command -v perl >/dev/null || fail 'Perl is required to patch Isar ARM64 loading.'
command -v dpkg-deb >/dev/null || fail 'dpkg-deb is required for Debian packaging.'
command -v patch >/dev/null || fail 'patch is required to patch media_kit_video.'

host_arch="$(uname -m)"
[[ "$host_arch" == "aarch64" || "$host_arch" == "arm64" ]] || \
  fail "This native build must run on AArch64; detected $host_arch."

flutter_linux="$(flutter config 2>/dev/null | grep -E 'enable-linux-desktop:|enable-linux-desktop' || true)"
printf 'Building Mangayomi for native Linux ARM64 (%s)\n' "$host_arch"
printf '%s\n' "$flutter_linux"

printf 'Building native torrent server (%s)\n' "$(go version)"
go build -C go -buildmode=c-shared -ldflags='-s -w' -trimpath \
  -o ../linux/bundle/lib/libmtorrentserver.so ./binding/desktop

flutter pub get

media_kit_video_source="$(find "$HOME/.pub-cache/git" \
  -path '*media_kit_video/linux/video_output.cc' \
  -print -quit)"
[[ -n "$media_kit_video_source" ]] || fail 'Could not locate media_kit_video Linux sources.'
media_kit_root="${media_kit_video_source%/media_kit_video/linux/video_output.cc}"
git -C "$media_kit_root" apply --check \
  "$project_root/scripts/media-kit-linux-egl.patch" || \
  fail 'Linux media-kit EGL patch does not match the resolved source.'
git -C "$media_kit_root" apply \
  "$project_root/scripts/media-kit-linux-egl.patch" || \
  fail 'Could not apply the Linux media-kit EGL patch.'

cargo build --manifest-path rust/Cargo.toml --target aarch64-unknown-linux-gnu --release

printf 'Building Isar Core 3.3.2 for native ARM64\n'
isar_source="${TMPDIR:-/tmp}/isar-community-3.3.2"
rm -rf "$isar_source"
git clone --depth 1 --branch 3.3.2 \
  https://github.com/isar-community/isar-community.git "$isar_source"
cargo build --manifest-path "$isar_source/packages/isar_core_ffi/Cargo.toml" \
  --target aarch64-unknown-linux-gnu --release
isar_package="$(find "$HOME/.pub-cache" \
  -path '*isar_community_flutter_libs-3.3.2/linux/libisar.so' \
  -print -quit)"
[[ -n "$isar_package" ]] || fail 'Could not locate the downloaded Isar Linux library.'
cp "$isar_source/target/aarch64-unknown-linux-gnu/release/libisar.so" "$isar_package"

isar_loader="$(find "$HOME/.pub-cache" \
  -path '*isar_community-3.3.2/lib/src/native/isar_core.dart' \
  -print -quit)"
[[ -n "$isar_loader" ]] || fail 'Could not locate the Isar Dart loader.'
perl -0pi -e 's/case Abi\.linuxX64:\n\s*return '\''libisar\.so'\'';/case Abi.linuxX64:\n      case Abi.linuxArm64:\n        return '\''libisar.so'\'';/' "$isar_loader"
grep -q 'case Abi.linuxArm64:' "$isar_loader" || \
  fail 'Could not enable Linux ARM64 in the Isar Dart loader.'

flutter build linux --release

bundle="build/linux/arm64/release/bundle"
[[ -d "$bundle" ]] || fail "Flutter did not create $bundle."
bash "$project_root/scripts/check-arm64.sh" "$bundle/mangayomi"

version="$(sed -n 's/^version: \([^+ ]*\).*/\1/p' pubspec.yaml | head -n 1)"
[[ -n "$version" ]] || fail 'Could not determine the application version from pubspec.yaml.'
archive="build/linux/arm64/release/Mangayomi-linux-arm64.tar.gz"
tar -C "$bundle" -czf "$archive" .
printf 'Created %s\n' "$archive"

if command -v dpkg-deb >/dev/null; then
  deb_root="build/linux/arm64/release/deb"
  rm -rf "$deb_root"
  mkdir -p "$deb_root/DEBIAN" "$deb_root/opt/mangayomi"
  cp -a "$bundle/." "$deb_root/opt/mangayomi/"
  cat > "$deb_root/DEBIAN/control" <<EOF
Package: mangayomi
Version: ${version}
Section: video
Priority: optional
Architecture: arm64
Maintainer: Mangayomi contributors
Depends: default-jre-headless, libgtk-3-0, libwebkit2gtk-4.1-0, libmpv2
Description: Manga reader and anime streaming application
EOF
  mkdir -p "$deb_root/usr/bin"
  ln -s /opt/mangayomi/mangayomi "$deb_root/usr/bin/mangayomi"
  dpkg-deb --build --root-owner-group "$deb_root" \
    "build/linux/arm64/release/mangayomi-linux-arm64.deb"
fi