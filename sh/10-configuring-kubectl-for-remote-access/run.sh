#!/usr/bin/env bash

run() {
  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"
  local certs_dir="$this_dir/../../secrets/certs"

  . "$this_dir/../../lib/public-addresses.sh"
  local KUBERNETES_PUBLIC_ADDRESS=${PUBLIC_ADDRESS[kubernetes]}

  local cluster_name='kubernetes-the-hard-way-aws'

  # The Admin Kubernetes Configuration File
  kubectl config set-cluster "$cluster_name" \
    --certificate-authority="$certs_dir"/ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443

  kubectl config set-credentials admin \
    --client-certificate="$certs_dir"/admin.pem \
    --client-key="$certs_dir"/admin-key.pem

  kubectl config set-context "$cluster_name" \
    --cluster="$cluster_name" \
    --user=admin

  kubectl config use-context "$cluster_name"

  echo
  echo '######################'
  echo '#### Verification ####'
  echo '######################'
  kubectl version
  echo
  echo '... expected output...'
  cat <<EOF
Client Version: version.Info{Major:"1", Minor:"21", GitVersion:"v1.21.0", GitCommit:"cb303e613a121a29364f75cc67d3d580833a7479", GitTreeState:"clean", BuildDate:"2021-04-08T16:31:21Z", GoVersion:"go1.16.1", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"21", GitVersion:"v1.21.0", GitCommit:"cb303e613a121a29364f75cc67d3d580833a7479", GitTreeState:"clean", BuildDate:"2021-04-08T16:25:06Z", GoVersion:"go1.16.1", Compiler:"gc", Platform:"linux/amd64"}

EOF
  echo

  kubectl get nodes
  echo
  cat <<EOF
ip-10-240-0-20   Ready    <none>   91s   v1.21.0
EOF
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
