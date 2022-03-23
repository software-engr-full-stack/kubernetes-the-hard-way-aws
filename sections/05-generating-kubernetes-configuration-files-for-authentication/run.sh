#!/usr/bin/env bash

run() {
  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  . "$this_dir/../../lib/public-addresses.sh"

  #######################################
  #### Client Authentication Configs ####
  #######################################

  # **** Kubernetes Public IP Address **** #

  local KUBERNETES_PUBLIC_ADDRESS=${PUBLIC_ADDRESS[kubernetes]}
  echo $KUBERNETES_PUBLIC_ADDRESS
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
