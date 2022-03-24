#!/usr/bin/env bash

run() {
  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  . "$this_dir/../../lib/public-addresses.sh"

  local KUBERNETES_PUBLIC_ADDRESS=${PUBLIC_ADDRESS[kubernetes]}

  curl --cacert "$this_dir/../../secrets/certs/ca.pem" \
    https://${KUBERNETES_PUBLIC_ADDRESS}:6443/version
  echo '.. expected output...'
  cat <<EOF
{
  "major": "1",
  "minor": "21",
  "gitVersion": "v1.21.0",
  "gitCommit": "cb303e613a121a29364f75cc67d3d580833a7479",
  "gitTreeState": "clean",
  "buildDate": "2021-04-08T16:25:06Z",
  "goVersion": "go1.16.1",
  "compiler": "gc",
  "platform": "linux/amd64"
}
EOF
}

set -o errexit
set -o pipefail
set -o nounset
run
