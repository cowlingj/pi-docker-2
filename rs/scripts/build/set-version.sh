#!/usr/bin/env bash

set -euo pipefail

help() {
  echo 'rs build set-version <version>'
}

description() {
  echo "Set version to supplied argument"
}

run() {
  if [ -z "${1:-}" ]; then
    rs_error "No version supplied"
    exit 1
  fi
  echo "$1" > './VERSION'
}