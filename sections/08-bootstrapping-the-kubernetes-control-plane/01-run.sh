#!/usr/bin/env bash

run() {
  local target_upload_file_dest_1='08-bootstrapping-the-kubernetes-control-plane-01.sh'
  local target_upload_file_dest_2='08-bootstrapping-the-kubernetes-control-plane-02.sh'

  # TODO: parameterize tag
  local tag='controller-0'

  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"
  . "$this_dir/../../lib/public-addresses.sh"

  local KUBERNETES_PUBLIC_ADDRESS=${PUBLIC_ADDRESS[kubernetes]}

  local kfilename='KUBERNETES_PUBLIC_ADDRESS'

  local upload_cmd="$this_dir/../../lib/upload.sh"

  for instance in "$tag"; do
    echo "${KUBERNETES_PUBLIC_ADDRESS}" > "$kfilename"
    sync
    sleep 1
    CALLER='controller' "$upload_cmd" "$kfilename"
  done
  rm -v "$kfilename"

  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"
  local id_file="$this_dir/../../secrets/kubernetes-the-hard-way-aws.ed25519"

  local external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$tag" "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  local run_inside_remote_1="$this_dir/run-inside-controller-1.sh"
  local run_inside_remote_2="$this_dir/run-inside-controller-2.sh"

  scp -i "$id_file" \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "$run_inside_remote_1" \
    ubuntu@"$external_ip":~/"$target_upload_file_dest_1"

  scp -i "$id_file" \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    "$run_inside_remote_2" \
    ubuntu@"$external_ip":~/"$target_upload_file_dest_2"

  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -i "$id_file" ubuntu@${external_ip} 'bash -s' < "$run_inside_remote_1"

  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    -i "$id_file" ubuntu@${external_ip} 'bash -s' < "$run_inside_remote_2"
}

set -o errexit
set -o pipefail
set -o nounset
run
