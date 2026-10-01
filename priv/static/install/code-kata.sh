#!/bin/bash

set -euo pipefail

readonly RELEASE_API="https://api.github.com/repos/tacit7/code-kata/releases/latest"
readonly RELEASE_PREFIX="https://github.com/tacit7/code-kata/releases/download/"

fail() {
  printf 'Code Kata installer: %s\n' "$1" >&2
  exit 1
}

if [[ "$(uname -s)" != "Darwin" ]]; then
  fail "this installer only supports macOS."
fi

command -v curl >/dev/null 2>&1 || fail "curl is required."
command -v hdiutil >/dev/null 2>&1 || fail "hdiutil is required."

work_dir="$(mktemp -d "${TMPDIR:-/tmp}/code-kata.XXXXXX")"
mount_dir="$work_dir/mount"
dmg_path="$work_dir/code-kata.dmg"
mounted=false

cleanup() {
  if [[ "$mounted" == true ]]; then
    hdiutil detach "$mount_dir" -quiet >/dev/null 2>&1 || true
  fi
  rm -rf "$work_dir"
}
trap cleanup EXIT INT TERM

printf 'Finding the latest Code Kata release...\n'
release_json="$(curl --fail --silent --show-error --location \
  --header 'Accept: application/vnd.github+json' \
  --header 'X-GitHub-Api-Version: 2022-11-28' \
  "$RELEASE_API")"

dmg_url="$(printf '%s\n' "$release_json" | awk -F'"' \
  '/"browser_download_url"/ && /\.dmg"/ { print $4; exit }')"

[[ -n "$dmg_url" ]] || fail "the latest release does not include a macOS .dmg yet."
[[ "$dmg_url" == "$RELEASE_PREFIX"* ]] || fail "GitHub returned an unexpected download URL."

printf 'Downloading Code Kata...\n'
curl --fail --show-error --location --progress-bar "$dmg_url" --output "$dmg_path"
[[ -s "$dmg_path" ]] || fail "the downloaded disk image is empty."

mkdir -p "$mount_dir"
printf 'Opening the disk image...\n'
hdiutil attach "$dmg_path" -nobrowse -readonly -mountpoint "$mount_dir" -quiet
mounted=true

app_path="$(find "$mount_dir" -maxdepth 2 -type d -name '*.app' -print -quit)"
[[ -n "$app_path" ]] || fail "the disk image does not contain an app."

if [[ -w "/Applications" ]]; then
  install_dir="/Applications"
else
  install_dir="$HOME/Applications"
  mkdir -p "$install_dir"
fi

app_name="$(basename "$app_path")"
destination="$install_dir/$app_name"

if [[ -e "$destination" ]]; then
  backup="$work_dir/$app_name.previous"
  printf 'Replacing the existing installation...\n'
  mv "$destination" "$backup"
fi

if ! ditto "$app_path" "$destination"; then
  rm -rf "$destination"
  if [[ -n "${backup:-}" && -e "$backup" ]]; then
    mv "$backup" "$destination"
  fi
  fail "the app could not be copied to $install_dir."
fi

# Code Kata is currently distributed without Apple notarization. Removing this
# attribute prevents Gatekeeper from treating this specific downloaded bundle
# as quarantined; it does not disable Gatekeeper system-wide.
if xattr -p com.apple.quarantine "$destination" >/dev/null 2>&1; then
  xattr -dr com.apple.quarantine "$destination" ||
    fail "the app was installed, but its quarantine attribute could not be removed."
fi

printf '\nCode Kata was installed at:\n  %s\n\n' "$destination"
printf 'Open it with:\n  open %q\n' "$destination"
