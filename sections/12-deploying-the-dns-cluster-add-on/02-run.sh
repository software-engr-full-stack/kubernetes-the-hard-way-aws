#!/usr/bin/env bash

run() {
  kubectl apply -f https://storage.googleapis.com/kubernetes-the-hard-way/coredns-1.8.yaml

  echo
  echo '... expected output...'
  cat <<EOF
serviceaccount/coredns created
clusterrole.rbac.authorization.k8s.io/system:coredns created
clusterrolebinding.rbac.authorization.k8s.io/system:coredns created
configmap/coredns created
deployment.apps/coredns created
service/kube-dns created
EOF
  echo

  kubectl get pods -l k8s-app=kube-dns -n kube-system
  echo
  echo '... expected output...'
  cat <<EOF
NAME                       READY   STATUS    RESTARTS   AGE
coredns-8494f9c688-hh7r2   1/1     Running   0          10s
coredns-8494f9c688-zqrj2   1/1     Running   0          10s
EOF

  echo
  echo '######################'
  echo '#### Verification ####'
  echo '######################'

  if ! kubectl get pods \
    --selector run=busybox \
    --output jsonpath='{.items[0].metadata.name}' >/dev/null; then
    kubectl run busybox --image=busybox:1.28 --command -- sleep 3600

    # Because "error: unable to upgrade connection: container not found ("busybox")"
    local delay=15
    echo "... sleeping for '$delay' seconds"
    sleep "$delay"
  fi
  kubectl get pods -l run=busybox

  echo
  echo '... expected output...'
  cat <<EOF
NAME      READY   STATUS    RESTARTS   AGE
busybox   1/1     Running   0          3s
EOF
  echo

  local POD_NAME=$(kubectl get pods -l run=busybox -o jsonpath="{.items[0].metadata.name}")
  kubectl exec -ti $POD_NAME -- nslookup kubernetes

  echo
  echo '... expected output...'
  cat <<EOF
Server:    10.32.0.10
Address 1: 10.32.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes
Address 1: 10.32.0.1 kubernetes.default.svc.cluster.local
EOF
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
