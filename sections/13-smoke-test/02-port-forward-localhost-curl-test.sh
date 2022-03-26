#!/usr/bin/env bash

run() {
  local POD_NAME=$(kubectl get pods -l app=nginx -o jsonpath="{.items[0].metadata.name}")
  kubectl port-forward $POD_NAME 8080:80 &
  sleep 3

  curl --head http://127.0.0.1:8080
  echo
  echo '... expected output...'
  cat <<EOF
HTTP/1.1 200 OK
Server: nginx/1.19.10
Date: Sun, 02 May 2021 05:29:25 GMT
Content-Type: text/html
Content-Length: 612
Last-Modified: Tue, 13 Apr 2021 15:13:59 GMT
Connection: keep-alive
ETag: "6075b537-264"
Accept-Ranges: bytes
EOF
  local port_forward_pid="$(
    ps aux | grep -v grep | grep -e 'kubectl[ ][ ]*port-forward' | awk {'print $2'}
  )"

  if [ -z "$port_forward_pid" ]; then
    echo '... ERROR: unable to find port forward PID' >&2
    exit 1
  fi

  kill "$port_forward_pid"
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
