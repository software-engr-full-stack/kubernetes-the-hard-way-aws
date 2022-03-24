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

module "network" {
  source = "./03-provisioning-compute-resources/01_networking"

  tag = local.tag
  cidr_block = local.cidr_block
  region = local.region

  ssh_port = local.ssh_port
  kube_apiserver_port = local.kube_apiserver_port
  pod_cidr_block = local.pod_cidr_block
}

module "compute_instances" {
  source                     = "./03-provisioning-compute-resources/02_compute_instances"

  security_groups            = [module.network.firewall.id]
  subnet_id                  = module.network.virtual_private_cloud_network.subnet.id

  key_name                   = local.tag.value
  controller_instances_count = local.controller_instances_count
  controller_instance_type   = local.controller_instance_type
  controller_private_base_ip = local.controller_private_base_ip

  pod_cidr_prefix            = local.pod_cidr_prefix
  worker_instances_count     = local.worker_instances_count
  worker_instance_type       = local.worker_instance_type
  worker_private_base_ip     = local.worker_private_base_ip
}

module "load_balancer" {
  source                                  = "./08-bootstrapping-the-kubernetes-control-plane"

  tag                                     = local.tag
  subnet_id                               = module.network.virtual_private_cloud_network.subnet.id
  kubernetes_public_address_allocation_id = module.network.eip.allocation_id
  vpc_id                                  = module.network.virtual_private_cloud_network.vpc.id
  instance_controllers                    = module.compute_instances.instance_controllers
}

module "pod_network_routes" {
  source = "./11-provisioning-pod-network-routes"

  route_table            = module.network.virtual_private_cloud_network.route_table
  destination_cidr_block = local.pod_cidr_block
  instance_workers       = module.compute_instances.instance_workers
}
