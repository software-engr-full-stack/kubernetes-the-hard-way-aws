#!/usr/bin/env bash

run() {
  local tag='kubernetes-the-hard-way-aws'

  echo
  echo '######################'
  echo '#### Verification ####'
  echo '######################'
  aws ec2 describe-route-tables \
    --filters Name=tag:Name,Values="$tag" \
    --query 'sort_by(RouteTables[0].Routes[],&DestinationCidrBlock)[].{Destination:DestinationCidrBlock,InstanceId:InstanceId,GatewayId:GatewayId}' \
    --output table | cat

  echo
  echo '... expected output (depending on number of instances)...'
  cat <<EOF
-------------------------------------------------------------------
|                       DescribeRouteTables                       |
+---------------+-------------------------+-----------------------+
|  Destination  |        GatewayId        |      InstanceId       |
+---------------+-------------------------+-----------------------+
|  0.0.0.0/0    |  igw-0acc027e68bb7af40  |  None                 |
|  10.200.0.0/24|  None                   |  i-088499c5e8f5a054e  |
|  10.240.0.0/24|  local                  |  None                 |
+---------------+-------------------------+-----------------------+
EOF
}

set -o errexit
set -o pipefail
set -o nounset
run "$@"
