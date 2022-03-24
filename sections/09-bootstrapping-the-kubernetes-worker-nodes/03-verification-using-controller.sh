#!/usr/bin/env bash

run() {
  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  local caller="$(basename --suffix .sh "$BASH_SOURCE" | cut -f 4 -d '-')"

  CALLER="$caller" "$this_dir/../../lib/ssh.sh" kubectl get nodes --kubeconfig admin.kubeconfig
}

set -o errexit
set -o pipefail
set -o nounset
run
