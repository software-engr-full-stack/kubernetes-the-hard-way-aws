#!/usr/bin/env bash

run() {
  local host_num="${HOST_NUM-}"

  local caller="$(basename --suffix .sh "$BASH_SOURCE" | cut -f 5 -d '-')"

  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  local upload_cmd="$this_dir/../../lib/upload.sh"

  CALLER="$caller" HOST_NUM="${HOST_NUM-}" "$upload_cmd" \
    "$this_dir/02-run-inside-worker.sh"
}

set -o errexit
set -o pipefail
set -o nounset
run
