#!/usr/bin/env bash

set -euo pipefail


vars() {
  IMAGE_NAME="${IMAGE_NAME:-local/packer}"
}

description() {
  echo "Builds docker image"
}

run() {
  echo "$IMAGE_NAME"
  # docker build -t local/packer .
}


