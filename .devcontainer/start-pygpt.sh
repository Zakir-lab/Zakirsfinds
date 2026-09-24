#!/usr/bin/env bash
set -euo pipefail

app_root="${HOME}/.local/share/pygpt-cloud"
app_run="${app_root}/PyGPT-2.8.30/AppRun"
log_dir="${app_root}/logs"
mkdir -p "$log_dir"

# Home-directory files can outlive a container restart, while installed
# packages may not. Repair a missing app or Qt dependency before launching.
needs_setup=false
if [[ ! -x "$app_run" ]]; then
  needs_setup=true
fi
for package in libxcb-cursor0 libxcb-icccm4 libxcb-keysyms1 libxcb-shape0; do
  if ! dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -qx 'install ok installed'; then
    needs_setup=true
    break
  fi
done
if [[ "$needs_setup" == true ]]; then
  bash .devcontainer/setup-pygpt.sh
fi

start_once() {
  local name="$1"
  shift
  local pid_file="${log_dir}/${name}.pid"
  local marker=''
  case "$name" in
    display) marker='Xvfb :99' ;;
    desktop) marker='fluxbox' ;;
    vnc) marker='x11vnc -display :99' ;;
    web) marker='websockify --web=/usr/share/novnc' ;;
    app) marker="$app_run --disable-gpu=1" ;;
  esac
  # A saved PID may belong to another process after the Codespace restarts.
  if [[ -f "$pid_file" ]]; then
    local saved_pid
    saved_pid="$(cat "$pid_file")"
    if [[ "$saved_pid" =~ ^[0-9]+$ ]] &&
       kill -0 "$saved_pid" 2>/dev/null &&
       [[ "$(ps -p "$saved_pid" -o stat= 2>/dev/null)" != *Z* ]] &&
       ps -p "$saved_pid" -o args= 2>/dev/null | grep -Fq -- "$marker"; then
      return 0
    fi
  fi
  nohup "$@" >"${log_dir}/${name}.log" 2>&1 </dev/null &
  printf '%s\n' "$!" >"$pid_file"
}

export DISPLAY=:99
export QT_QPA_PLATFORM=xcb
export QT_SCALE_FACTOR=1.15
export QTWEBENGINE_CHROMIUM_FLAGS='--disable-gpu --disable-dev-shm-usage'
export QT_QUICK_BACKEND=software
export LIBGL_ALWAYS_SOFTWARE=1

start_once display Xvfb :99 -screen 0 1280x800x24 -nolisten tcp
sleep 2
start_once desktop fluxbox
start_once vnc x11vnc -display :99 -localhost -rfbport 5900 -nopw -forever -shared
start_once web websockify --web=/usr/share/novnc 0.0.0.0:6080 127.0.0.1:5900
# PyGPT's own --disable-gpu option disables its OpenGL renderer. If an older
# instance is still running, stop just that instance before starting it with
# the new setting. Keep the virtual desktop and browser connection running.
app_pid_file="${log_dir}/app.pid"
if [[ -f "$app_pid_file" ]]; then
  saved_app_pid="$(cat "$app_pid_file")"
  if [[ "$saved_app_pid" =~ ^[0-9]+$ ]] &&
     ps -p "$saved_app_pid" -o args= 2>/dev/null | grep -Fq -- "$app_run" &&
     ! ps -p "$saved_app_pid" -o args= 2>/dev/null | grep -Fq -- '--disable-gpu=1'; then
    pkill -TERM -P "$saved_app_pid" 2>/dev/null || true
    kill "$saved_app_pid" 2>/dev/null || true
    for ((attempt=0; attempt<5; attempt++)); do
      if ! kill -0 "$saved_app_pid" 2>/dev/null; then
        break
      fi
      sleep 1
    done
  fi
fi
start_once app dbus-run-session "$app_run" --disable-gpu=1

printf 'PyGPT desktop started on port 6080. Keep this port private.\n'
