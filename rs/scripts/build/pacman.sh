#!/usr/bin/env bash

set -euo pipefail

help() {
  echo "$0 $@ - Build a pacman package"
}

description() {
  echo "$0 $@ - Build a pacman package"
}

run() {
  local BUILD_DIR='build/pacman'
  rm -rf "$BUILD_DIR"
  mkdir -p "$BUILD_DIR"

  tar -czf "$BUILD_DIR/app.tar.gz" app
  cp LICENSE VERSION "$BUILD_DIR"
  sed "s/__VERSION__/$(cat "$BUILD_DIR/VERSION")/g" package/pacman/PKGBUILD > "$BUILD_DIR/PKGBUILD"

  cd "$BUILD_DIR"
  
  makepkg -g >> "./PKGBUILD"
  makepkg -s

  rs_success 'built package, looking for common errors'

  (
    source "./PKGBUILD"
    for arcitecture in "${arch[@]}"; do
      FILE="$pkgname-$pkgver-$pkgrel-$arcitecture.pkg.tar.xz"
      RESULT="$(namcap "$FILE")"
      if [ -n "$RESULT" ]; then
        rs_error "Error in file: $FILE"
        echo "$RESULT"
      fi
    done
  )

  rs_success 'done'
}
