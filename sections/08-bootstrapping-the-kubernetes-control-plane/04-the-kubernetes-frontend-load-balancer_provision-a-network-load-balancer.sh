#!/usr/bin/env bash

run() {
  echo '... load balancer should already have been provisioned during the Terraform run...'
}

set -o errexit
set -o pipefail
set -o nounset
run
