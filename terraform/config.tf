locals {
  ssh_port = 22
  kube_apiserver_port = 6443

  cidr_block = "10.240.0.0/24"
  pod_cidr_block = "10.200.0.0/16"
  tag = {
    key = "Name"
    value = "kubernetes-the-hard-way-aws"
  }
  region = "us-west-1"
}
