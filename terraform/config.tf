locals {
  ssh_port = 22
  kube_apiserver_port = 6443

  cidr_block                 = "10.240.0.0/24"
  controller_private_base_ip = "10.240.0.1" # 10.240.0.?${index}
  worker_private_base_ip     = "10.240.0.2" # 10.240.0.?${index}
  pod_cidr_block             = "10.200.0.0/16"
  pod_cidr_prefix            = "10.200"

  tag = {
    key = "Name"
    value = "kubernetes-the-hard-way-aws"
  }
  region = "us-west-1"

  controller_instances_count = 1
  controller_instance_type = "t2.micro"

  worker_instances_count = 1
  worker_instance_type = "t2.micro"
}
