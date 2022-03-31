#!/usr/bin/env bash

run() {
  local files="${1?:ERROR => must pass files to upload}"

  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  UPLOAD="$@" CALLER="$CALLER" HOST_NUM="${HOST_NUM-}" "$this_dir/ssh.sh"
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
