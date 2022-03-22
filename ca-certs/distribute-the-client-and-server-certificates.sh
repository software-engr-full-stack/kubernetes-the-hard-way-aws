#!/usr/bin/env bash

run() {
  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  . "$this_dir/public-addresses.sh"

  local id_file="$this_dir/../secrets/kubernetes-the-hard-way-aws.ed25519"

  # TODO: generate automatically using instance count
  for instance in worker-0; do
    scp -i "$id_file" \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      ca.pem ${instance}-key.pem ${instance}.pem \
      ubuntu@${PUBLIC_ADDRESS[${instance}]}:~/
  done

  # TODO: generate automatically using instance count
  for instance in controller-0; do
    scp -i "$id_file" \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
      service-account-key.pem service-account.pem \
      ubuntu@${PUBLIC_ADDRESS[${instance}]}:~/
  done
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
