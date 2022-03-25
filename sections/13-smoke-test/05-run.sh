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

  echo '**** Logs ****'
  kubectl exec -ti $POD_NAME -- nginx -v
  echo

  cat <<EOF
nginx version: nginx/1.19.10
EOF
  echo

  echo '**** Services ****'
  if ! kubectl get deployments.apps \
    --selector app=nginx \
    --output jsonpath='{.items[0].metadata.name}' >/dev/null; then
    kubectl expose deployment nginx --port 80 --type NodePort
  fi

  local NODE_PORT=$(kubectl get svc nginx \
    --output=jsonpath='{range .spec.ports[0]}{.nodePort}')

  local EXTERNAL_IP=${PUBLIC_ADDRESS[worker-0]}

  curl -I http://${EXTERNAL_IP}:${NODE_PORT}
  echo

    cat <<EOF
HTTP/1.1 200 OK
Server: nginx/1.19.10
Date: Sun, 02 May 2021 05:31:52 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 13 Apr 2021 15:13:59 GMT
Connection: keep-alive
ETag: "6075b537-264"
Accept-Ranges: bytes
EOF
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
