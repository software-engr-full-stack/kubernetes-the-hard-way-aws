#!/usr/bin/env bash

run() {
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
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
