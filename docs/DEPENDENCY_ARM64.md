# Dependency ARM64 matrix

Status is intentionally conservative until the native CI job or Orange Pi validates the runtime.

| Package/component | Native code | ARM64 status | Action |
|---|---:|---|---|
| Flutter Linux engine | Yes | Supported by the configured Flutter target | Build on AArch64 |
| `flutter_rust_bridge` / `rust_lib_mangayomi` | Yes | Rust target is present; runtime unverified | Build and inspect `.so` |
| `isar_community_flutter_libs` | Yes | Unknown for this lockfile | Confirm generated native asset on ARM64 |
| `media_kit` / `media_kit_video` | Yes | Unknown for custom Git revision | Build and inspect backend |
| `media_kit_libs_video` | Yes | Unknown for custom Git revision | Confirm mpv/FFmpeg ARM64 path |
| `flutter_inappwebview` | Yes | System WebKitGTK path is expected | Install WebKitGTK and exercise lifecycle |
| `desktop_webview_window` | Yes | Unknown on target compositor | Test Wayland and X11 separately |
| `flutter_qjs` | Yes | Unknown native asset coverage | Load a JavaScript extension |
| `ffi` / image decoder | Yes | Source is compiled by Linux CMake | Verify JPEG/PNG/AVIF dynamic loading |
| Go `libmtorrentserver.so` | Yes | Host-native Go build | Run `go build` on AArch64 and verify |
| `window_manager` | Yes | Linux plugin | Exercise resize/fullscreen |
| `flutter_discord_rpc_fork` | Yes | Optional until ARM64 support is proven | Must not block startup |
| `flutter_tts` | Yes | Unknown Linux ARM64 backend | Verify or keep optional |
| `local_auth` | Yes | Linux capability is environment-dependent | Graceful feature fallback |
| GTK/WebKit/mpv/codec libraries | Yes | Distribution-provided ARM64 packages | Install documented packages |

No dependency should be replaced until the ARM64 build identifies a concrete failure.
