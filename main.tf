terraform {
  required_version = ">= 1.1.5"

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
  source              = "./sections/03-provisioning-compute-resources/01_networking"

  # tag                 = local.tag
  name                = local.name
  base_tag            = local.base_tag
  cidr_block          = local.cidr_block
  region              = local.region

  ssh_port            = local.ssh_port
  kube_apiserver_port = local.kube_apiserver_port
  pod_cidr_block      = local.pod_cidr_block
}

module "compute_instances" {
  source                     = "./sections/03-provisioning-compute-resources/02_compute_instances"

  security_groups            = [module.network.firewall.id]
  subnet_id                  = module.network.virtual_private_cloud_network.subnet.id

  key_name                   = local.name
  controllers                = local.controllers
  workers                    = local.workers
}

module "load_balancer" {
  source                                  = "./sections/08-bootstrapping-the-kubernetes-control-plane"

  name                                    = local.name
  base_tag                                = local.base_tag
  subnet_id                               = module.network.virtual_private_cloud_network.subnet.id
  kubernetes_public_address_allocation_id = module.network.eip.allocation_id
  vpc_id                                  = module.network.virtual_private_cloud_network.vpc.id
  instance_controllers                    = module.compute_instances.instance_controllers
}

module "pod_network_routes" {
  source                 = "./sections/11-provisioning-pod-network-routes"

  route_table            = module.network.virtual_private_cloud_network.route_table
  destination_cidr_block = local.pod_cidr_block
  instance_workers       = module.compute_instances.instance_workers
}

module "nginx_kubernetes_node_port" {
  count                      = var.nginx_kubernetes_node_port != "" ? 1 : 0
  source                     = "./sections/13-smoke-test"

  nginx_kubernetes_node_port = var.nginx_kubernetes_node_port
  security_group_id          = module.network.firewall.id
}
