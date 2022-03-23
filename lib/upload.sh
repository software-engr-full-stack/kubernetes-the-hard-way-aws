#!/usr/bin/env bash

run() {
  local files="${1?:ERROR => must pass files to upload}"
  local host_num="${HOST_NUM-}"

  local caller="$(basename "$BASH_SOURCE" | cut -f 5 -d '-')"

  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  UPLOAD="$@" CALLER="$caller" "$this_dir/ssh.sh" "$host_num"
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
