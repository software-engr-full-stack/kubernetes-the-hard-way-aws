#!/usr/bin/env bash

run() {
  # TODO: parameterize host
  local host='controller-0'

  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  . "$this_dir/../../lib/public-addresses.sh"

  local id_file="$this_dir/../../secrets/kubernetes-the-hard-way-aws.ed25519"

  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -i "$id_file" ubuntu@${PUBLIC_ADDRESS[$host]} \
    kubectl get nodes --kubeconfig admin.kubeconfig
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
