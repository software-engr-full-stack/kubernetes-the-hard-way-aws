declare -A "PUBLIC_ADDRESS=( $(aws ec2 describe-instances \
  --filter "Name=tag:Name,Values=controller-0,controller-1,controller-2,worker-0,worker-1,worker-2" "Name=instance-state-name,Values=running" \
  --output text --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value | [0],PublicIpAddress]' \
  | xargs -n2 printf "[%s]=%s ") )"

PUBLIC_ADDRESS[kubernetes]=$(aws ec2 describe-addresses \
  --filters Name=tag:Name,Values=kubernetes-the-hard-way-aws \
  --output text --query 'Addresses[0].PublicIp')
