#!/usr/bin/env bash

set -euo pipefail

run() {
  docker run \
    -v `pwd`:/home/app/workspace -w /home/app/workspace \
    --user `id -u`:`id -g` \
    local/packer:latest \
    $@
}
