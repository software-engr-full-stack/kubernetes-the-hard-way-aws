variable "instance_workers" {
  # TODO: put more specific type
  type = any
}

variable "route_table" {
  # TODO: put more specific type
  type = any
}

variable "destination_cidr_block" {
  type = string
}

resource "aws_route" "kube" {
  route_table_id         = var.route_table.id
  destination_cidr_block = var.destination_cidr_block

  depends_on             = [var.route_table]

  for_each               = var.instance_workers
  network_interface_id   = each.value.primary_network_interface_id
}

output "DEBUG" {
  value = var.instance_workers
}
