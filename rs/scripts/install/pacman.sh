#!/usr/bin/env bash

set -euo pipefail

help() {
  :
}

description() {
  echo "Install a previously built pacman package"
}

run() {
  sudo pacman -U "$(find build/pacman/ -name '*.pkg.tar.xz')"
}