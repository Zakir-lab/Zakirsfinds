#!/usr/bin/env bash
set -euo pipefail

app_root="${HOME}/.local/share/pygpt-cloud"
app_run="${app_root}/PyGPT-2.8.30/AppRun"
log_dir="${app_root}/logs"
mkdir -p "$log_dir"

if [[ ! -x "$app_run" ]]; then
  printf 'PyGPT setup has not completed. Run: bash .devcontainer/setup-pygpt.sh\n' >&2
  exit 1
fi

start_once() {
  local name="$1"
  shift
  local pid_file="${log_dir}/${name}.pid"
  if [[ -f "$pid_file" ]] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
    return 0
  fi
  nohup "$@" >"${log_dir}/${name}.log" 2>&1 </dev/null &
  printf '%s\n' "$!" >"$pid_file"
}

export DISPLAY=:99
export QT_QPA_PLATFORM=xcb
export QT_SCALE_FACTOR=1.15
export QTWEBENGINE_CHROMIUM_FLAGS='--disable-gpu --disable-dev-shm-usage'
export LIBGL_ALWAYS_SOFTWARE=1

start_once display Xvfb :99 -screen 0 1280x800x24 -nolisten tcp
sleep 2
start_once desktop fluxbox
start_once vnc x11vnc -display :99 -localhost -rfbport 5900 -nopw -forever -shared
start_once web websockify --web=/usr/share/novnc 0.0.0.0:6080 127.0.0.1:5900
start_once app dbus-run-session "$app_run"

printf 'PyGPT desktop started on port 6080. Keep this port private.\n'
