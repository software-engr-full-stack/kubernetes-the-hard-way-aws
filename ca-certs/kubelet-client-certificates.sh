#!/usr/bin/env bash

run() {
  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  . "$this_dir/public-addresses.sh"

  # TODO: inject instance count
  for i in 0; do
    local instance="worker-${i}"
    local INSTANCE_HOSTNAME="ip-10-240-0-2${i}"
    cat > ${instance}-csr.json <<EOF
{
  "CN": "system:node:${INSTANCE_HOSTNAME}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Los Angeles",
      "O": "system:nodes",
      "OU": "Kubernetes The Hard Way - AWS",
      "ST": "California"
    }
  ]
}
EOF
    local EXTERNAL_IP=${PUBLIC_ADDRESS[${instance}]}

    local INTERNAL_IP="10.240.0.2${i}"

    cfssl gencert \
      -ca=ca.pem \
      -ca-key=ca-key.pem \
      -config=ca-config.json \
      -hostname=${INSTANCE_HOSTNAME},${EXTERNAL_IP},${INTERNAL_IP} \
      -profile=kubernetes \
      ${instance}-csr.json | cfssljson -bare ${instance}
  done
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
