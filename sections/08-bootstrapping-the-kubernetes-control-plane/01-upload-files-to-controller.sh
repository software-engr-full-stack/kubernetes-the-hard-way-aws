#!/usr/bin/env bash

run() {
  local caller="$(basename --suffix .sh "$BASH_SOURCE" | cut -f 5 -d '-')"

  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  . "$this_dir/../../lib/public-addresses.sh"

  local KUBERNETES_PUBLIC_ADDRESS=${PUBLIC_ADDRESS[kubernetes]}

  local kfilename='KUBERNETES_PUBLIC_ADDRESS'

  local upload_cmd="$this_dir/../../lib/upload.sh"

  # TODO: parameterize instead of hard-coding "0", "1", etc.
  for instance in controller-0; do
    echo "${KUBERNETES_PUBLIC_ADDRESS}" > "$kfilename"
    sync
    sleep 1
    CALLER="$caller" "$upload_cmd" "$kfilename"
  done
  rm -v "$kfilename"

  CALLER="$caller" HOST_NUM="${HOST_NUM-}" "$upload_cmd" \
    "$this_dir/02-run-inside-controller_provision-the-kubernetes-control-plane.sh" \
    "$this_dir/03-run-inside-controller_rbac-for-kubelet-authorization.sh"
}

set -o errexit
set -o pipefail
set -o nounset
run
