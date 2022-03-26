#!/usr/bin/env bash

run() {
  sudo modprobe br_netfilter
  sudo sysctl net.bridge.bridge-nf-call-iptables=1

  cat <<EOF | sudo tee /etc/sysctl.d/90-kubernetes-the-hard-way-aws.conf
# https://github.com/kelseyhightower/kubernetes-the-hard-way/issues/662#issuecomment-989898160
# In case your kube-proxy configuration is okay, you might notice by tracing with IPTables that masquerading is ok on receving the packet, but see no trace of the return packet. After testing, it appears to be a generic problem on compute disks imaged with : ubuntu-2004-focal-v20211202 (not tested with other versions).

# Referring to Kubernetes issue #21613, and when your DNS and busybox pods on on the same node, you might need an additional kernel module to reverse dNAT the returning packet.

# Installation steps, think of replicating it to all workers:
net.bridge.bridge-nf-call-iptables = 1
EOF
}

set -o errexit
set -o pipefail
set -o nounset
run
