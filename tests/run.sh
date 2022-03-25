#!/usr/bin/env bash

run() {
  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"
  local sections_dir="$this_dir/sections"

  local test_data_file="$this_dir/expected.yml"

  local test_file=
  local bname=
  for test_file in $(find "$sections_dir" -type f -name '*.py' | sort); do
    bname="$(basename "$test_file")"
    if grep -q -v '^[0-9][0-9].*\.py' <<<"$bname"; then
      continue
    fi
    printf "$(cut -d '/' -f 9- <<< "$test_file"): "
    python "$test_file" "$test_data_file" && echo 'ok'
  done
}

set -o errexit
set -o pipefail
set -o nounset
run
