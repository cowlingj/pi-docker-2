#!/usr/bin/env bash

set -euo pipefail

help() {
  :
}

description() {
  echo "Install a previously built pacman package"
}

run() {
  PACKAGE="$(source './package/pacman/PKGBUILD'; echo "build/pacman/rs-$(cat ./VERSION)-${pkgrel}-${arch}.pkg.tar.xz")"

  if [ ! -f "$PACKAGE" ]; then
    rs_error "Package \"$PACKAGE\" not found"
    exit 1
  fi

  rs_info "Installing package \"$PACKAGE\""
  
  sudo pacman -U "$PACKAGE"
  
  rs_success "done"
}