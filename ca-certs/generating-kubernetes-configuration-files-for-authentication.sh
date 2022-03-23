#!/usr/bin/env bash

run() {
  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  . "$this_dir/public-addresses.sh"

  local KUBERNETES_PUBLIC_ADDRESS=${PUBLIC_ADDRESS[kubernetes]}

  # The kubelet Kubernetes Configuration File
  # TODO: inject host count instead of hard-coding "0"
  for i in 0; do
    instance="worker-${i}"
    INSTANCE_HOSTNAME="ip-10-240-0-2${i}"

    kubectl config set-cluster kubernetes-the-hard-aws \
      --certificate-authority=ca.pem \
      --embed-certs=true \
      --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
      --kubeconfig=${instance}.kubeconfig

    kubectl config set-credentials system:node:${INSTANCE_HOSTNAME} \
      --client-certificate=${instance}.pem \
      --client-key=${instance}-key.pem \
      --embed-certs=true \
      --kubeconfig=${instance}.kubeconfig

    kubectl config set-context default \
      --cluster=kubernetes-the-hard-way-aws \
      --user=system:node:${INSTANCE_HOSTNAME} \
      --kubeconfig=${instance}.kubeconfig

    kubectl config use-context default --kubeconfig=${instance}.kubeconfig
  done
  # Results:
  # worker-0.kubeconfig
  # worker-1.kubeconfig
  # worker-2.kubeconfig

  # The kube-proxy Kubernetes Configuration File
  kubectl config set-cluster kubernetes-the-hard-way-aws \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-credentials system:kube-proxy \
    --client-certificate=kube-proxy.pem \
    --client-key=kube-proxy-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way-aws \
    --user=system:kube-proxy \
    --kubeconfig=kube-proxy.kubeconfig

  kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig
  # Results:
  # kube-proxy.kubeconfig

  # The kube-controller-manager Kubernetes Configuration File
  kubectl config set-cluster kubernetes-the-hard-way-aws \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-credentials system:kube-controller-manager \
    --client-certificate=kube-controller-manager.pem \
    --client-key=kube-controller-manager-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way-aws \
    --user=system:kube-controller-manager \
    --kubeconfig=kube-controller-manager.kubeconfig

  kubectl config use-context default --kubeconfig=kube-controller-manager.kubeconfig
  # Results:
  # kube-controller-manager.kubeconfig


  # The kube-scheduler Kubernetes Configuration File
  kubectl config set-cluster kubernetes-the-hard-way-aws \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-credentials system:kube-scheduler \
    --client-certificate=kube-scheduler.pem \
    --client-key=kube-scheduler-key.pem \
    --embed-certs=true \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way-aws \
    --user=system:kube-scheduler \
    --kubeconfig=kube-scheduler.kubeconfig

  kubectl config use-context default --kubeconfig=kube-scheduler.kubeconfig
  # Results:
  # kube-scheduler.kubeconfig

  # The admin Kubernetes Configuration File
  kubectl config set-cluster kubernetes-the-hard-way-aws \
    --certificate-authority=ca.pem \
    --embed-certs=true \
    --server=https://127.0.0.1:6443 \
    --kubeconfig=admin.kubeconfig

  kubectl config set-credentials admin \
    --client-certificate=admin.pem \
    --client-key=admin-key.pem \
    --embed-certs=true \
    --kubeconfig=admin.kubeconfig

  kubectl config set-context default \
    --cluster=kubernetes-the-hard-way-aws \
    --user=admin \
    --kubeconfig=admin.kubeconfig

  kubectl config use-context default --kubeconfig=admin.kubeconfig
  # Results:
  # admin.kubeconfig

  # Distribute the Kubernetes Configuration Files
  local id_file="$this_dir/../secrets/kubernetes-the-hard-way-aws.ed25519"
  # TODO: inject host count instead of hard-coding "...0"
  for instance in worker-0; do
    scp -i "$id_file" \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      ${instance}.kubeconfig kube-proxy.kubeconfig \
      ubuntu@${PUBLIC_ADDRESS[${instance}]}:~/
  done

  # TODO: inject host count instead of hard-coding "...0"
  for instance in controller-0; do
    scp -i "$id_file" \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      admin.kubeconfig kube-controller-manager.kubeconfig kube-scheduler.kubeconfig \
      ubuntu@${PUBLIC_ADDRESS[${instance}]}:~/
  done
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
