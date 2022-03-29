#!/usr/bin/env bash

run() {
  local name="${1:?ERROR => must pass name}"
  local op_arg="${2:?ERROR => must pass Terraform operation (plan, apply, or destroy)}"
  local this_dir="$(dirname "$(readlink -f "$BASH_SOURCE")")"

  local app_dir="$this_dir/../.."

  cd "$app_dir"

  local config_cmd="$app_dir/lib/config.py"
  local config_file="$app_dir/config.yml"

  declare -a vars=(
    -var=name="$name"
    -var=controllers="$(
      "$config_cmd" --config-file "$config_file" --key 'controllers' --shape 'dict'
    )"
    -var=workers="$(
      "$config_cmd" --config-file "$config_file" --key 'workers' --shape 'dict'
    )"
    -var=network="$(
      "$config_cmd" --config-file "$config_file" --key 'network'
    )"
    -var=aws="$(
      "$config_cmd" --config-file "$config_file" --key 'aws'
    )"
  )

  if ! terraform plan -out "/tmp/$name.tf.out" "${vars[@]}"; then
    terraform init
  fi

  declare -A op_table=(
    [plan]="plan -out /tmp/$name.tf.out"
    [apply]='apply -auto-approve'
    [destroy]='destroy -auto-approve'
  )

  local op="${op_table[$op_arg]-}"
  if [ -z "$op" ]; then
    printf "... ERROR: invalid Terraform op '$op_arg', valid ops...\n$(declare -p op_table)\n" >&2
    exit 1
  fi

  terraform $op "${vars[@]}"
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
