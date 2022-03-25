#!/usr/bin/env bash

run() {
  local POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")
  kubectl port-forward $POD_NAME 8080:80
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
