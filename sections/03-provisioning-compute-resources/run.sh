#!/usr/bin/env bash

run() {
  local name="${1:?ERROR => must pass name}"
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

  terraform plan -out "/tmp/$name.tf.out" "${vars[@]}"

  terraform apply "${vars[@]}"
  # terraform apply -auto-approve "${vars[@]}"
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
