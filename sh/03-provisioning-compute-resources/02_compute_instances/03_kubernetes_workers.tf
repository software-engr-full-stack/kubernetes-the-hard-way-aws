variable "worker_instances_count" {
  type = number
}

variable "worker_instance_type" {
  type = string
}

variable "worker_private_base_ip" {
  type = string
}

variable "pod_cidr_prefix" {
  type = string
}

resource "aws_instance" "workers" {
  associate_public_ip_address = true
  ami                         = data.aws_ami.kube.id
  count                       = var.worker_instances_count
  key_name                    = var.key_name

  # Original AWS CLI code uses security_groups parameter but using this
  # parameter keeps on destroying the instance.
  # See security_groups entry on
  #   https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
  vpc_security_group_ids      = var.security_groups

  instance_type               = var.worker_instance_type
  private_ip                  = format("%s%d", var.worker_private_base_ip, count.index)
  user_data                   = format(
    "name=worker-%d|pod-cidr=%s.%d.0/24",
    count.index,
    var.pod_cidr_prefix,
    count.index
  )
  subnet_id                   = var.subnet_id
  source_dest_check           = false

  tags = {
    ResourceType = "instance"
    Name = format("worker-%d", count.index)
  }
}

output "instance_workers" {
  value = aws_instance.workers
}
