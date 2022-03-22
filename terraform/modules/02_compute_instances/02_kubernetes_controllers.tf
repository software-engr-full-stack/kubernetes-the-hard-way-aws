variable "controller_instances_count" {
  type = number
}

variable "controller_instance_type" {
  type = string
}

variable "controller_private_base_ip" {
  type = string
}

resource "aws_instance" "controllers" {
  associate_public_ip_address = true
  ami                         = data.aws_ami.kube.id
  count                       = var.controller_instances_count
  key_name                    = var.key_name

  # Original AWS CLI code uses security_groups parameter but using this
  # parameter keeps on destroying the instance.
  # See security_groups entry on
  #   https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
  vpc_security_group_ids      = var.security_groups

  instance_type               = var.controller_instance_type
  private_ip                  = format("%s%d", var.controller_private_base_ip, count.index)
  user_data                   = format("name=controller-%d", count.index)
  subnet_id                   = var.subnet_id
  source_dest_check           = false

  tags = {
    ResourceType = "instance"
    Name = format("controller-%d", count.index)
  }
}
