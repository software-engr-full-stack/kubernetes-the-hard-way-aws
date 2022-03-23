#!/usr/bin/env bash

run() {
  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  . "$this_dir/../../lib/public-addresses.sh"

  local KUBERNETES_PUBLIC_ADDRESS=${PUBLIC_ADDRESS[kubernetes]}

  curl --cacert "$this_dir/../../ca-certs/ca.pem" https://${KUBERNETES_PUBLIC_ADDRESS}:6443/version
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
