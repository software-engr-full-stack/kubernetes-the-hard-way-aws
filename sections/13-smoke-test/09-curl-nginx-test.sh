#!/usr/bin/env bash

run() {
  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  . "$this_dir/../../lib/public-addresses.sh"

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
