#!/usr/bin/env bash

run() {
  local target_upload_file_dest='12-deploying-the-dns-cluster-add-on.sh'

  # TODO: parameterize tag
  local tag='worker-0'

  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"
  local id_file="$this_dir/../../secrets/kubernetes-the-hard-way-aws.ed25519"

  local external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$tag" "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  local run_inside_remote="$this_dir/run-inside-worker.sh"
  scp -i "$id_file" \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "$run_inside_remote" \
    ubuntu@"$external_ip":~/"$target_upload_file_dest"

  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -i "$id_file" ubuntu@${external_ip} 'bash -s' < "$run_inside_remote"
}

set -o errexit
set -o pipefail
set -o nounset
run
