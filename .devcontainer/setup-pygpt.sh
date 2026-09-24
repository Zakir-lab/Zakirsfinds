#!/usr/bin/env bash
set -euo pipefail

version='2.8.30'
sha256='ba645a13aae90ddf606a7c95f6f0d0dd3c6a3f17950c5aca9b8b9a5bf443b981'
app_root="${HOME}/.local/share/pygpt-cloud"
image="${app_root}/PyGPT-${version}-x86_64.AppImage"
app_dir="${app_root}/PyGPT-${version}"
release_url="https://github.com/szczyglis-dev/py-gpt/releases/download/v${version}/PyGPT-${version}-x86_64.AppImage"

if [[ "$(uname -m)" != 'x86_64' ]]; then
  printf 'This setup requires a GitHub Codespace with an x86_64 processor.\n' >&2
  exit 1
fi

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  xvfb x11vnc fluxbox novnc websockify dbus-x11 xterm \
  libgl1 libegl1 libxkbcommon-x11-0 libxcb-cursor0 libnss3 \
  libasound2 libatk-bridge2.0-0 libgbm1 libgtk-3-0 \
  fonts-dejavu-core

mkdir -p "$app_root"
if [[ ! -f "$image" ]] || ! printf '%s  %s\n' "$sha256" "$image" | sha256sum --check --status; then
  printf 'Downloading official PyGPT %s (about 800 MB)...\n' "$version"
  partial="${image}.part"
  curl --fail --location --retry 3 --continue-at - --output "$partial" "$release_url"
  printf '%s  %s\n' "$sha256" "$partial" | sha256sum --check
  mv "$partial" "$image"
fi
chmod +x "$image"

if [[ ! -x "${app_dir}/AppRun" ]]; then
  temp_dir="$(mktemp -d "${app_root}/.extract.XXXXXX")"
  (cd "$temp_dir" && "$image" --appimage-extract >/dev/null)
  test -x "${temp_dir}/squashfs-root/AppRun"
  if [[ -e "$app_dir" ]]; then
    rm -rf -- "$app_dir"
  fi
  mv "${temp_dir}/squashfs-root" "$app_dir"
  rmdir "$temp_dir" || true
fi

# Make the forwarded port land on the actual desktop without extra clicks.
printf '<!doctype html><meta http-equiv="refresh" content="0;url=/vnc.html?autoconnect=1&amp;resize=scale">\n' \
  | sudo tee /usr/share/novnc/index.html >/dev/null

printf '\nPyGPT is ready. The private forwarded port 6080 opens its desktop.\n'
