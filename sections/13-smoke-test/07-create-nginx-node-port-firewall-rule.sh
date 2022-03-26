#!/usr/bin/env bash

run() {
  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  local NODE_PORT=$(kubectl get svc nginx \
    --output=jsonpath='{range .spec.ports[0]}{.nodePort}')

  [ -n "$NODE_PORT" ] || exit 1

  cd "$this_dir"/..

  terraform apply -auto-approve -var=nginx_kubernetes_node_port="$NODE_PORT"
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
