#!/usr/bin/env bash

run() {
  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  . "$this_dir/public-addresses.sh"

  local KUBERNETES_PUBLIC_ADDRESS=${PUBLIC_ADDRESS[kubernetes]}

  # TODO: generate automatically using instance count
  local CONTROLLER_INSTANCE_HOSTNAMES=ip-10-240-0-10

  local KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local

  cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "US",
      "L": "Portland",
      "O": "Kubernetes",
      "OU": "Kubernetes The Hard Way",
      "ST": "Oregon"
    }
  ]
}
EOF

  # TODO: generate automatically using instance count
  cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -hostname=10.32.0.1,10.240.0.10,${CONTROLLER_INSTANCE_HOSTNAMES},${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,${KUBERNETES_HOSTNAMES} \
    -profile=kubernetes \
    kubernetes-csr.json | cfssljson -bare kubernetes
  # The Kubernetes API server is automatically assigned the kubernetes internal dns name,
  # which will be linked to the first IP address (10.32.0.1) from the address range (10.32.0.0/24)
  # reserved for internal cluster services during the control plane bootstrapping lab.
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
