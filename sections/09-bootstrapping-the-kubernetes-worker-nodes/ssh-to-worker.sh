#!/usr/bin/env bash

run() {
  # TODO: parameterize host
  local host='worker-0'

  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"
  local id_file="$this_dir/../../secrets/kubernetes-the-hard-way-aws.ed25519"

  local external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$host" "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -i "$id_file" ubuntu@${external_ip}
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
