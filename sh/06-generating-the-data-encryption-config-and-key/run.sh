#!/usr/bin/env bash

run() {
  local cluster_name='kubernetes-the-hard-way-aws'
  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  . "$this_dir/../../lib/public-addresses.sh"

  local output_dir="$this_dir/../../secrets/config-auto-gen"
  mkdir -p "$output_dir"

  ############################
  #### The Encryption Key ####
  ############################

  local ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

  ############################
  #### The Encryption Key ####
  ############################

  cat > "$output_dir"/encryption-config.yaml <<EOF
kind: EncryptionConfig
apiVersion: v1
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: ${ENCRYPTION_KEY}
      - identity: {}
EOF

  ####################################
  #### The Encryption Config File ####
  ####################################

  local id_file="$this_dir/../../secrets/kubernetes-the-hard-way-aws.ed25519"

  # TODO: parameterize instead of hard-coding "0", "1", etc.
  for instance in controller-0; do
    scp -i "$id_file" \
      -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
      "$output_dir"/encryption-config.yaml \
      ubuntu@${PUBLIC_ADDRESS[${instance}]}:~/
  done
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
