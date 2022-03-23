#!/usr/bin/env bash

run() {
  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"
  local id_file="$this_dir/../../secrets/kubernetes-the-hard-way-aws.ed25519"

  . "$this_dir/../../lib/public-addresses.sh"

  local KUBERNETES_PUBLIC_ADDRESS=${PUBLIC_ADDRESS[kubernetes]}

  # TODO: parameterize host
  local host='controller-0'
  for instance in "$host"; do
    ssh -i "$id_file" \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      ubuntu@${PUBLIC_ADDRESS[${instance}]} "echo "${KUBERNETES_PUBLIC_ADDRESS}" > KUBERNETES_PUBLIC_ADDRESS"
  done
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
