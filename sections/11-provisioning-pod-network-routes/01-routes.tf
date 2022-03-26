variable "instance_workers" {
  type = list(object({
    primary_network_interface_id = string
    private_ip = string
  }))
}

locals {
  workers_map = {
    for item in var.instance_workers: item.private_ip => item
  }
}

variable "route_table" {
  type = any
}

variable "destination_cidr_block" {
  type = string
}

resource "aws_route" "kube" {
  route_table_id         = var.route_table.id
  destination_cidr_block = var.destination_cidr_block

  depends_on             = [var.route_table]

  for_each               = local.workers_map
  network_interface_id   = each.value.primary_network_interface_id
}
