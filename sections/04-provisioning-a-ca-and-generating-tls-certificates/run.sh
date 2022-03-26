#!/usr/bin/env bash

run() {
  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  . "$this_dir/../../lib/public-addresses.sh"

  local certs_dir="$this_dir/../../secrets/certs"
  mkdir -p "$certs_dir"

  local country='US'
  local city='Los Angeles'
  local state='California'
  local ou='Kubernetes The Hard Way - AWS'

  ################################
  ##### Certificate Authority ####
  ################################

  cat > "$certs_dir"/ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

  cat > "$certs_dir"/ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "$country",
      "L": "$city",
      "O": "Kubernetes",
      "OU": "CA",
      "ST": "$state"
    }
  ]
}
EOF

  cfssl gencert -initca "$certs_dir"/ca-csr.json | cfssljson -bare ca
  # Results:
  # ca-key.pem
  # ca.pem
  mv ca-key.pem "$certs_dir"
  mv ca.pem "$certs_dir"
  mv *.csr "$certs_dir"

  ########################################
  #### Client and Server Certificates ####
  ########################################

  # **** The Admin Client Certificate **** #

  cat > "$certs_dir"/admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "$country",
      "L": "$city",
      "O": "system:masters",
      "OU": "$ou",
      "ST": "$state"
    }
  ]
}
EOF

  cfssl gencert \
    -ca="$certs_dir"/ca.pem \
    -ca-key="$certs_dir"/ca-key.pem \
    -config="$certs_dir"/ca-config.json \
    -profile=kubernetes \
    "$certs_dir"/admin-csr.json | cfssljson -bare admin
  # Results:
  # admin-key.pem
  # admin.pem
  mv admin-key.pem "$certs_dir"
  mv admin.pem "$certs_dir"/
  mv *.csr "$certs_dir"

  # **** The Kubelet Client Certificates **** #

  # TODO: parameterize instead of hard-coding "0", "1", etc.
  for i in 0; do
    local instance="worker-${i}"
    local INSTANCE_HOSTNAME="ip-10-240-0-2${i}"
    cat > "$certs_dir"/${instance}-csr.json <<EOF
{
  "CN": "system:node:${INSTANCE_HOSTNAME}",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "$country",
      "L": "$city",
      "O": "system:nodes",
      "OU": "$ou",
      "ST": "$state"
    }
  ]
}
EOF
    local EXTERNAL_IP=${PUBLIC_ADDRESS[${instance}]}

    local INTERNAL_IP="10.240.0.2${i}"

    cfssl gencert \
      -ca="$certs_dir"/ca.pem \
      -ca-key="$certs_dir"/ca-key.pem \
      -config="$certs_dir"/ca-config.json \
      -hostname=${INSTANCE_HOSTNAME},${EXTERNAL_IP},${INTERNAL_IP} \
      -profile=kubernetes \
      "$certs_dir"/${instance}-csr.json | cfssljson -bare ${instance}
  done
  # Results:
  # worker-0-key.pem
  # worker-0.pem
  mv worker-0-key.pem "$certs_dir"
  mv worker-0.pem "$certs_dir"/
  mv *.csr "$certs_dir"

  # **** The Controller Manager Client Certificate **** #

  cat > "$certs_dir"/kube-controller-manager-csr.json <<EOF
{
  "CN": "system:kube-controller-manager",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "$country",
      "L": "$city",
      "O": "system:kube-controller-manager",
      "OU": "$ou",
      "ST": "$state"
    }
  ]
}
EOF

  cfssl gencert \
    -ca="$certs_dir"/ca.pem \
    -ca-key="$certs_dir"/ca-key.pem \
    -config="$certs_dir"/ca-config.json \
    -profile=kubernetes \
    "$certs_dir"/kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager
  # Results:
  # kube-controller-manager-key.pem
  # kube-controller-manager.pem
  mv kube-controller-manager-key.pem "$certs_dir"
  mv kube-controller-manager.pem "$certs_dir"
  mv *.csr "$certs_dir"

  # **** The Kube Proxy Client Certificate **** #

  cat > "$certs_dir"/kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "$country",
      "L": "$city",
      "O": "system:node-proxier",
      "OU": "$ou",
      "ST": "$state"
    }
  ]
}
EOF

  cfssl gencert \
    -ca="$certs_dir"/ca.pem \
    -ca-key="$certs_dir"/ca-key.pem \
    -config="$certs_dir"/ca-config.json \
    -profile=kubernetes \
    "$certs_dir"/kube-proxy-csr.json | cfssljson -bare kube-proxy
  # Results:
  # kube-proxy-key.pem
  # kube-proxy.pem
  mv kube-proxy-key.pem "$certs_dir"
  mv kube-proxy.pem "$certs_dir"
  mv *.csr "$certs_dir"

  # **** The Scheduler Client Certificate **** #

  cat > "$certs_dir"/kube-scheduler-csr.json <<EOF
{
  "CN": "system:kube-scheduler",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "$country",
      "L": "$city",
      "O": "system:kube-scheduler",
      "OU": "$ou",
      "ST": "$state"
    }
  ]
}
EOF
  cfssl gencert \
    -ca="$certs_dir"/ca.pem \
    -ca-key="$certs_dir"/ca-key.pem \
    -config="$certs_dir"/ca-config.json \
    -profile=kubernetes \
    "$certs_dir"/kube-scheduler-csr.json | cfssljson -bare kube-scheduler
  # Results:
  # kube-scheduler-key.pem
  # kube-scheduler.pem
  mv kube-scheduler-key.pem "$certs_dir"
  mv kube-scheduler.pem "$certs_dir"
  mv *.csr "$certs_dir"

  # **** The Kubernetes API Server Certificate **** #

  local KUBERNETES_PUBLIC_ADDRESS=${PUBLIC_ADDRESS[kubernetes]}

  # TODO: parameterize instead of hard-coding "0", "1", etc.
  local CONTROLLER_INSTANCE_HOSTNAMES=ip-10-240-0-10

  local KUBERNETES_HOSTNAMES=kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.svc.cluster.local

  cat > "$certs_dir"/kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "$country",
      "L": "$city",
      "O": "Kubernetes",
      "OU": "$ou",
      "ST": "$state"
    }
  ]
}
EOF

  # TODO: parameterize instead of hard-coding "0", "1", etc.
  cfssl gencert \
    -ca="$certs_dir"/ca.pem \
    -ca-key="$certs_dir"/ca-key.pem \
    -config="$certs_dir"/ca-config.json \
    -hostname=10.32.0.1,10.240.0.10,${CONTROLLER_INSTANCE_HOSTNAMES},${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,${KUBERNETES_HOSTNAMES} \
    -profile=kubernetes \
    "$certs_dir"/kubernetes-csr.json | cfssljson -bare kubernetes
  # Results:
  # kubernetes-key.pem
  # kubernetes.pem
  mv kubernetes-key.pem "$certs_dir"
  mv kubernetes.pem "$certs_dir"
  mv *.csr "$certs_dir"

  ######################################
  #### The Service Account Key Pair ####
  ######################################

  cat > "$certs_dir"/service-account-csr.json <<EOF
{
  "CN": "service-accounts",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "$country",
      "L": "$city",
      "O": "Kubernetes",
      "OU": "$ou",
      "ST": "$state"
    }
  ]
}
EOF

  cfssl gencert \
    -ca="$certs_dir"/ca.pem \
    -ca-key="$certs_dir"/ca-key.pem \
    -config="$certs_dir"/ca-config.json \
    -profile=kubernetes \
    "$certs_dir"/service-account-csr.json | cfssljson -bare service-account
  # Results:
  # service-account-key.pem
  # service-account.pem
  mv service-account-key.pem "$certs_dir"
  mv service-account.pem "$certs_dir"
  mv *.csr "$certs_dir"

  local id_file="$this_dir/../../secrets/kubernetes-the-hard-way-aws.ed25519"

  # TODO: parameterize instead of hard-coding "0", "1", etc.
  for instance in worker-0; do
    scp -i "$id_file" \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      "$certs_dir"/ca.pem \
      "$certs_dir"/${instance}-key.pem \
      "$certs_dir"/${instance}.pem \
      ubuntu@${PUBLIC_ADDRESS[${instance}]}:~/
  done

  # TODO: parameterize instead of hard-coding "0", "1", etc.
  for instance in controller-0; do
    scp -i "$id_file" \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      "$certs_dir"/ca.pem "$certs_dir"/ca-key.pem "$certs_dir"/kubernetes-key.pem "$certs_dir"/kubernetes.pem \
      "$certs_dir"/service-account-key.pem "$certs_dir"/service-account.pem \
      ubuntu@${PUBLIC_ADDRESS[${instance}]}:~/
  done
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
