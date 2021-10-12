#!/usr/bin/env bash

set -euo pipefail

help() {
  :
}

description() {
  echo "Build a pacman package"
}

run() {
  TMP="$(mktemp -d)"
  rs_debug "building in: $TMP"
  tar -cvzf "$TMP/app.tar.gz" app
  cp build/pacman/PKGBUILD "$TMP"
  cd "$TMP"
  makepkg -g >> "$TMP/PKGBUILD"
  makepkg -s

  rs_success 'done'
}
