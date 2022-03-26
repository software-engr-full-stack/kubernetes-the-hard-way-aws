#!/usr/bin/env bash

run() {
  echo '**** Services ****'
  if ! kubectl get services \
      --selector app=nginx \
      --output jsonpath='{.items[0].spec.ports[0].port}' >/dev/null; then
    kubectl expose deployment nginx --port 80 --type NodePort
  fi
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
