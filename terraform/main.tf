terraform {
  required_version = ">= 1.1.5"

  # backend "local" {
  #   path = "./terraform.tfstate"
  # }

  cloud {
    organization = "software-engr-full-stack"
    workspaces {
      name = "kubernetes-the-hard-way-aws"
    }
  }
}

provider "aws" {
  region = local.region
}

module "kube" {
  source = "./modules"

  tag = local.tag
  cidr_block = local.cidr_block
  region = local.region

  ssh_port = local.ssh_port
  kube_apiserver_port = local.kube_apiserver_port
  pod_cidr_block = local.pod_cidr_block
}
