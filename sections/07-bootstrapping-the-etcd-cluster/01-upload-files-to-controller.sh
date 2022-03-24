#!/usr/bin/env bash

run() {
  local caller="$(basename --suffix .sh "$BASH_SOURCE" | cut -f 5 -d '-')"

  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  CALLER="$caller" HOST_NUM="${HOST_NUM-}" "$this_dir/../../lib/upload.sh" \
    "$this_dir/02-run-inside-controller.sh"
}

set -o errexit
set -o pipefail
set -o nounset
run
