#!/usr/bin/env bash

run() {
  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  local caller="$(basename --suffix .sh "$BASH_SOURCE" | cut -f 4 -d '-')"

  CALLER="$caller" "$this_dir/../../lib/ssh.sh" kubectl get nodes --kubeconfig admin.kubeconfig

  echo
  echo '... expected output (depending on number of workers)...'
  cat <<EOF
NAME             STATUS   ROLES    AGE     VERSION
ip-10-240-0-20   Ready    <none>   5m49s   v1.21.0
EOF
}

set -o errexit
set -o pipefail
set -o nounset
run
