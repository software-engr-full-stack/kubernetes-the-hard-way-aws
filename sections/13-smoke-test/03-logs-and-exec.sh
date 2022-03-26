#!/usr/bin/env bash

run() {
  local cluster_name='kubernetes-the-hard-way-aws'

  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  . "$this_dir/../../lib/public-addresses.sh"

  echo '**** Logs ****'
  local POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")
  kubectl logs $POD_NAME
  echo

  echo '... expected output...'
  cat <<EOF
...
127.0.0.1 - - [02/May/2021:05:29:25 +0000] "HEAD / HTTP/1.1" 200 0 "-" "curl/7.64.0" "-"
EOF
  echo

  echo '**** Exec ****'
  kubectl exec -ti $POD_NAME -- nginx -v
  echo

  echo '... expected output...'
  cat <<EOF
nginx version: nginx/1.19.10
EOF
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
