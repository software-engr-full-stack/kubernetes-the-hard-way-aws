#!/usr/bin/env bash

run() {
  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  . "$this_dir/../../lib/public-addresses.sh"

  local country='US'
  local city='Los Angeles'
  local state='California'
  local ou='Kubernetes The Hard Way - AWS'

  ################################
  ##### Certificate Authority ####
  ################################

  cat > ca-config.json <<EOF
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

  cat > ca-csr.json <<EOF
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

  cfssl gencert -initca ca-csr.json | cfssljson -bare ca
  # Results:
  # ca-key.pem
  # ca.pem

  ########################################
  #### Client and Server Certificates ####
  ########################################

  # **** The Admin Client Certificate **** #

  cat > admin-csr.json <<EOF
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
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes \
    admin-csr.json | cfssljson -bare admin
  # Results:
  # admin-key.pem
  # admin.pem

  # **** The Kubelet Client Certificates **** #

  # TODO: parameterize instead of hard-coding "0", "1", etc.
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
      -ca=ca.pem \
      -ca-key=ca-key.pem \
      -config=ca-config.json \
      -hostname=${INSTANCE_HOSTNAME},${EXTERNAL_IP},${INTERNAL_IP} \
      -profile=kubernetes \
      ${instance}-csr.json | cfssljson -bare ${instance}
  done
  # Results:
  # worker-0-key.pem
  # worker-0.pem

  # **** The Controller Manager Client Certificate **** #

  cat > kube-controller-manager-csr.json <<EOF
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
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes \
    kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager
  # Results:
  # kube-controller-manager-key.pem
  # kube-controller-manager.pem

  # **** The Kube Proxy Client Certificate **** #

  cat > kube-proxy-csr.json <<EOF
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
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes \
    kube-proxy-csr.json | cfssljson -bare kube-proxy
  # Results:
  # kube-proxy-key.pem
  # kube-proxy.pem

  # **** The Scheduler Client Certificate **** #

  cat > kube-scheduler-csr.json <<EOF
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
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes \
    kube-scheduler-csr.json | cfssljson -bare kube-scheduler
  # Results:
  # kube-scheduler-key.pem
  # kube-scheduler.pem

  # **** The Kubernetes API Server Certificate **** #

  local KUBERNETES_PUBLIC_ADDRESS=${PUBLIC_ADDRESS[kubernetes]}

  # TODO: parameterize instead of hard-coding "0", "1", etc.
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
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -hostname=10.32.0.1,10.240.0.10,${CONTROLLER_INSTANCE_HOSTNAMES},${KUBERNETES_PUBLIC_ADDRESS},127.0.0.1,${KUBERNETES_HOSTNAMES} \
    -profile=kubernetes \
    kubernetes-csr.json | cfssljson -bare kubernetes
  # Results:
  # kubernetes-key.pem
  # kubernetes.pem

  ######################################
  #### The Service Account Key Pair ####
  ######################################

  cat > service-account-csr.json <<EOF
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
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes \
    service-account-csr.json | cfssljson -bare service-account
  # Results:
  # service-account-key.pem
  # service-account.pem

  local id_file="$this_dir/../../secrets/kubernetes-the-hard-way-aws.ed25519"

  # TODO: parameterize instead of hard-coding "0", "1", etc.
  for instance in worker-0; do
    scp -i "$id_file" \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      ca.pem ${instance}-key.pem ${instance}.pem \
      ubuntu@${PUBLIC_ADDRESS[${instance}]}:~/
  done

  # TODO: parameterize instead of hard-coding "0", "1", etc.
  for instance in controller-0; do
    scp -i "$id_file" \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      ca.pem ca-key.pem kubernetes-key.pem kubernetes.pem \
      service-account-key.pem service-account.pem \
      ubuntu@${PUBLIC_ADDRESS[${instance}]}:~/
  done
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
