#!/usr/bin/env bash

run() {
  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"
  local modules_dir="$this_dir/modules"

  local test_data_file="$this_dir/expected.yml"

  local test_file=
  for test_file in $(find "$modules_dir" -type f -iname '0*' | sort); do
    printf "$(cut -d '/' -f 9- <<< "$test_file"): "
    python "$test_file" "$test_data_file" && ok
  done
}

ok() {
  echo 'ok'
}

set -o errexit
set -o pipefail
set -o nounset
run
