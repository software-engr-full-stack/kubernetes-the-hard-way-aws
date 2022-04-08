#!/usr/bin/env bash

run() {
  if ! type aws >/dev/null; then
    echo 'ERROR: must install AWS CLI tool' >&2
    exit 1
  fi

  if ! AWS_PAGER='' aws sts get-caller-identity >/dev/null; then
    echo 'ERROR: must setup AWS credentials' >&2
    exit 1
  fi
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
