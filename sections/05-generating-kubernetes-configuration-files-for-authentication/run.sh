#!/usr/bin/env bash

run() {
  local cluster_name='kubernetes-the-hard-way-aws'
  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  . "$this_dir/../../lib/public-addresses.sh"

  local certs_dir="$this_dir/../../secrets/certs"

  local output_dir="$this_dir/../../secrets/config-auto-gen"
  mkdir -p "$output_dir"

  #######################################
  #### Client Authentication Configs ####
  #######################################

  # **** Kubernetes Public IP Address **** #

  local KUBERNETES_PUBLIC_ADDRESS=${PUBLIC_ADDRESS[kubernetes]}

  # **** The kubelet Kubernetes Configuration File **** #

  # TODO: parameterize instead of hard-coding "0", "1", etc.
  for i in 0; do
    instance="worker-${i}"
    INSTANCE_HOSTNAME="ip-10-240-0-2${i}"

    kubectl config set-cluster "$cluster_name" \
      --certificate-authority="$certs_dir"/ca.pem \
      --embed-certs=true \
      --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
      --kubeconfig="$output_dir"/${instance}.kubeconfig

    kubectl config set-credentials system:node:${INSTANCE_HOSTNAME} \
      --client-certificate="$certs_dir"/${instance}.pem \
      --client-key="$certs_dir"/${instance}-key.pem \
      --embed-certs=true \
      --kubeconfig="$output_dir"/${instance}.kubeconfig

    kubectl config set-context default \
      --cluster="$cluster_name" \
      --user=system:node:${INSTANCE_HOSTNAME} \
      --kubeconfig="$output_dir"/${instance}.kubeconfig

    kubectl config use-context default --kubeconfig="$output_dir"/${instance}.kubeconfig
  done
  # Results:
  # worker-0.kubeconfig

  # **** The kube-proxy Kubernetes Configuration File **** #

  kubectl config set-cluster "$cluster_name" \
    --certificate-authority="$certs_dir/"ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig="$output_dir"/kube-proxy.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate="$certs_dir/"kube-proxy.pem \
    --client-key="$certs_dir/"kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig="$output_dir"/kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster="$cluster_name" \
    --user=system:kube-proxy \
    --kubeconfig="$output_dir"/kube-proxy.kubeconfig

  kubectl config use-context default --kubeconfig="$output_dir"/kube-proxy.kubeconfig
  # Results:
  # kube-proxy.kubeconfig

  # **** The kube-controller-manager Kubernetes Configuration File **** #

  kubectl config set-cluster "$cluster_name" \
    --certificate-authority="$certs_dir/"ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig="$output_dir"/kube-controller-manager.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate="$certs_dir/"kube-controller-manager.pem \
    --client-key="$certs_dir/"kube-controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig="$output_dir"/kube-controller-manager.kubeconfig

  kubectl config set-context default \
    --cluster="$cluster_name" \
    --user=system:kube-controller-manager \
    --kubeconfig="$output_dir"/kube-controller-manager.kubeconfig

  kubectl config use-context default --kubeconfig="$output_dir"/kube-controller-manager.kubeconfig
  # Results:
  # kube-controller-manager.kubeconfig

  # **** The kube-scheduler Kubernetes Configuration File **** #
  kubectl config set-cluster "$cluster_name" \
    --certificate-authority="$certs_dir/"ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig="$output_dir"/kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate="$certs_dir/"kube-scheduler.pem \
    --client-key="$certs_dir/"kube-scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig="$output_dir"/kube-scheduler.kubeconfig

  kubectl config set-context default \
    --cluster="$cluster_name" \
    --user=system:kube-scheduler \
    --kubeconfig="$output_dir"/kube-scheduler.kubeconfig

  kubectl config use-context default --kubeconfig="$output_dir"/kube-scheduler.kubeconfig
  # Results:
  # kube-scheduler.kubeconfig

  # **** The admin Kubernetes Configuration File **** #

  kubectl config set-cluster "$cluster_name" \
    --certificate-authority="$certs_dir"/ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig="$output_dir"/admin.kubeconfig

  kubectl config set-credentials admin \
    --client-certificate="$certs_dir"/admin.pem \
    --client-key="$certs_dir"/admin-key.pem \
    --embed-certs=true \
    --kubeconfig="$output_dir"/admin.kubeconfig

  kubectl config set-context default \
    --cluster="$cluster_name" \
    --user=admin \
    --kubeconfig="$output_dir"/admin.kubeconfig

  kubectl config use-context default --kubeconfig="$output_dir"/admin.kubeconfig
  # Results:
  # admin.kubeconfig

  #######################################################
  #### Distribute the Kubernetes Configuration Files ####
  #######################################################

  local id_file="$this_dir/../../secrets/kubernetes-the-hard-way-aws.ed25519"

  # TODO: parameterize instead of hard-coding "0", "1", etc.
  for instance in worker-0; do
    scp -i "$id_file" \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      "$output_dir"/${instance}.kubeconfig \
      "$output_dir"/kube-proxy.kubeconfig \
      ubuntu@${PUBLIC_ADDRESS[${instance}]}:~/
  done

  # TODO: parameterize instead of hard-coding "0", "1", etc.
  for instance in controller-0; do
    scp -i "$id_file" \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      "$output_dir"/admin.kubeconfig \
      "$output_dir"/kube-controller-manager.kubeconfig \
      "$output_dir"/kube-scheduler.kubeconfig \
      ubuntu@${PUBLIC_ADDRESS[${instance}]}:~/
  done
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
