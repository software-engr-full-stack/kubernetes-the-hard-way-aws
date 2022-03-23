#!/usr/bin/env bash

run() {
  local num="${1:-0}"
  local upload_files="${UPLOAD-}"

  local caller=
  if [ -n "$upload_files" ]; then
    caller="$CALLER"
  else
    caller="$(basename "$BASH_SOURCE" | cut -f 3 -d '-')"
  fi

  declare -A valid_callers_table=(
    ['controller']=true
    ['worker']=true
  )

  if [ -z "${valid_callers_table[$caller]-}" ]; then
    printf "... ERROR: caller '$caller' not valid, valid callers...\n  $(declare -p valid_callers_table)\n" >&2
    exit 1
  fi

  local host="$caller-$num"

  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"
  local id_file="$this_dir/../secrets/kubernetes-the-hard-way-aws.ed25519"

  local external_ip=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$host" "Name=instance-state-name,Values=running" \
    --output text --query 'Reservations[].Instances[].PublicIpAddress')

  if [ -n "$upload_files" ]; then
    echo "... uploading files [$upload_files] to '$host'..."
    scp -i "$id_file" \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      $upload_files \
      ubuntu@"$external_ip":~/
  else
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      -i "$id_file" ubuntu@${external_ip}
  fi
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
