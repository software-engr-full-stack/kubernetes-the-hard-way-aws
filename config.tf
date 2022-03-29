variable "name" {
  type = string
}

variable "controllers" {
  type = string
  description = "list of specifications of controller instances to be created"
}

variable "workers" {
  type = string
  description = "list of specifications of worker instances to be created"
}

variable "network" {
  type = string
}

variable "aws" {
  type = string
}

variable "nginx_kubernetes_node_port" {
  type = string
  default = ""
}

locals {
  network = jsondecode(var.network)
}

locals {
  aws = jsondecode(var.aws)
}

locals {
  name = var.name
  ssh_port = 22
  kube_apiserver_port = 6443

  cidr_block = local.network["cidr_block"]
  pod_cidr_block = local.network["pod_cidr_block"]

  controllers = jsondecode(var.controllers)
  workers = jsondecode(var.workers)

  base_tag = {
    Name = var.name
  }

  region = local.aws.region
}
