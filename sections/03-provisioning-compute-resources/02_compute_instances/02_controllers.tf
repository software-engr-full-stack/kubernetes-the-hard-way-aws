variable "controllers" {
  # TODO: put more specific type
  type = any
}

resource "aws_instance" "controllers" {
  associate_public_ip_address = true
  ami                         = data.aws_ami.kube.id
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  source_dest_check           = false

  # Original AWS CLI code uses security_groups parameter but using this
  # parameter keeps on destroying the instance.
  # See security_groups entry on
  #   https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
  vpc_security_group_ids      = var.security_groups

  for_each                    = var.controllers
  instance_type               = each.value.instance_type
  private_ip                  = each.value.internal_ip
  user_data                   = each.value.hostname

  tags = {
    ResourceType = "instance"
    Name = each.value.hostname
  }
}

output "instance_controllers" {
  value = aws_instance.controllers
}
