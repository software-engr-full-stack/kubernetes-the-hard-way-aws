#!/usr/bin/env bash

run() {
  declare -a required_tools=(
    aws
    kubectl
    terraform
    pip
    cfssl
    cfssljson
  )
  local cmd=
  for cmd in "${required_tools[@]}"; do
    if ! type "$cmd" >/dev/null; then
      echo "ERROR: must install '$cmd'" >&2
      exit 1
    fi
  done

  declare -a required_python_packages=(
    ansible
    pyyaml:yaml
    cryptography
  )

  local pkg_import=
  local pkg=
  local import=
  for pkg_import in "${required_python_packages[@]}"; do
    pkg="$(cut --delimiter ':' --field 1 <<<"$pkg_import")"
    import="$(cut --delimiter ':' --only-delimited --field 2 <<<"$pkg_import")"
    [ -n "$import" ] || import="$pkg"
    python -c "import $import"
  done

  if ! AWS_PAGER='' aws sts get-caller-identity >/dev/null; then
    echo 'ERROR: must setup AWS credentials' >&2
    exit 1
  fi
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
