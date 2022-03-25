#!/usr/bin/env bash

run() {
  local cluster_name='kubernetes-the-hard-way-aws'
  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  # . "$this_dir/../../lib/public-addresses.sh"

  echo '####################'
  echo '#### Smoke Test ####'
  echo '####################'
  echo

  echo '**** Data Encryption ****'

  # Create a generic secret:
  # Before running, the output of the following hexdump command should be blank.
  kubectl create secret generic kubernetes-the-hard-way \
    --from-literal="mykey=mydata"

  local ssh="$this_dir/../../lib/ssh.sh"
  CALLER='controller' "$ssh" \
  "sudo ETCDCTL_API=3 etcdctl get \
     --endpoints=https://127.0.0.1:2379 \
     --cacert=/etc/etcd/ca.pem \
     --cert=/etc/etcd/kubernetes.pem \
     --key=/etc/etcd/kubernetes-key.pem\
     /registry/secrets/default/$cluster_name | hexdump -C"

  echo
  echo '... expected output...'
  cat <<EOF
00000000  2f 72 65 67 69 73 74 72  79 2f 73 65 63 72 65 74  |/registry/secret|
00000010  73 2f 64 65 66 61 75 6c  74 2f 6b 75 62 65 72 6e  |s/default/kubern|
00000020  65 74 65 73 2d 74 68 65  2d 68 61 72 64 2d 77 61  |etes-the-hard-wa|
00000030  79 0a 6b 38 73 3a 65 6e  63 3a 61 65 73 63 62 63  |y.k8s:enc:aescbc|
00000040  3a 76 31 3a 6b 65 79 31  3a 97 d1 2c cd 89 0d 08  |:v1:key1:..,....|
00000050  29 3c 7d 19 41 cb ea d7  3d 50 45 88 82 a3 1f 11  |)<}.A...=PE.....|
00000060  26 cb 43 2e c8 cf 73 7d  34 7e b1 7f 9f 71 d2 51  |&.C...s}4~...q.Q|
00000070  45 05 16 e9 07 d4 62 af  f8 2e 6d 4a cf c8 e8 75  |E.....b...mJ...u|
00000080  6b 75 1e b7 64 db 7d 7f  fd f3 96 62 e2 a7 ce 22  |ku..d.}....b..."|
00000090  2b 2a 82 01 c3 f5 83 ae  12 8b d5 1d 2e e6 a9 90  |+*..............|
000000a0  bd f0 23 6c 0c 55 e2 52  18 78 fe bf 6d 76 ea 98  |..#l.U.R.x..mv..|
000000b0  fc 2c 17 36 e3 40 87 15  25 13 be d6 04 88 68 5b  |.,.6.@..%.....h[|
000000c0  a4 16 81 f6 8e 3b 10 46  cb 2c ba 21 35 0c 5b 49  |.....;.F.,.!5.[
EOF

  echo '**** Deployments ****'
  kubectl create deployment nginx --image=nginx
  kubectl get pods -l app=nginx

  echo
  echo '... expected output...'
  cat <<EOF
NAME                    READY   STATUS    RESTARTS   AGE
nginx-f89759699-kpn5m   1/1     Running   0          10s
EOF
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
