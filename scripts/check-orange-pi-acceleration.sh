#!/usr/bin/env bash
set -u

section() { printf '\n=== %s ===\n' "$1"; }
run() { printf '$ %s\n' "$*"; "$@" 2>&1 || true; }

section 'CPU'
run uname -m

section 'DRM devices'
run ls -l /dev/dri

section 'Kernel graphics modules'
run sh -c "lsmod | grep -E 'panfrost|gpu_sched|drm' || true"

section 'Session'
run sh -c 'printf "XDG_SESSION_TYPE=%s\nWAYLAND_DISPLAY=%s\nDISPLAY=%s\n" "${XDG_SESSION_TYPE:-}" "${WAYLAND_DISPLAY:-}" "${DISPLAY:-}"'

section 'OpenGL'
if command -v glxinfo >/dev/null; then
  run glxinfo -B
else
  printf 'glxinfo is not installed\n'
fi

section 'EGL'
if command -v eglinfo >/dev/null; then
  run eglinfo -B
else
  printf 'eglinfo is not installed\n'
fi

section 'Video devices'
run sh -c 'ls -l /dev/video* 2>/dev/null || true'
if command -v v4l2-ctl >/dev/null; then
  run v4l2-ctl --list-devices
else
  printf 'v4l2-ctl is not installed\n'
fi

section 'FFmpeg hardware acceleration'
if command -v ffmpeg >/dev/null; then
  run ffmpeg -hide_banner -hwaccels
else
  printf 'ffmpeg is not installed\n'
fi

section 'mpv hardware decoding'
if command -v mpv >/dev/null; then
  run mpv --hwdec=help
else
  printf 'mpv is not installed\n'
fi

section 'Summary'
if command -v glxinfo >/dev/null; then
  renderer="$(glxinfo -B 2>/dev/null | sed -n 's/^OpenGL renderer string: //p')"
  printf 'OpenGL renderer: %s\n' "${renderer:-unknown}"
  case "$renderer" in
    *llvmpipe*|*softpipe*|*Software*)
      printf 'WARNING: software OpenGL renderer detected.\n'
      ;;
    *Mali*|*Panfrost*)
      printf 'GPU renderer detected.\n'
      ;;
    *)
      printf 'GPU renderer could not be confirmed from the renderer string.\n'
      ;;
  esac
fi
