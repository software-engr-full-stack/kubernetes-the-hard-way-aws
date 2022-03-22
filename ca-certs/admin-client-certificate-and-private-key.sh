#!/usr/bin/env bash

run() {
  # Generate the admin client certificate and private key:
  cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes \
    admin-csr.json | cfssljson -bare admin
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
