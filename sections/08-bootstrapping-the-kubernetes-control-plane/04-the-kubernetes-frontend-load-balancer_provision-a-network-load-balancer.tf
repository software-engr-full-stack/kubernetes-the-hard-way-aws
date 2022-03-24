variable "tag" {
  type = object({
      value = string
    })
}

variable "subnet_id" {
  type = string
}

variable "kubernetes_public_address_allocation_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "instance_controllers" {
  type = list(object({
    private_ip = string
  }))
}

resource "aws_lb" "kube" {
  name = var.tag.value

  subnet_mapping {
    subnet_id     = var.subnet_id
    allocation_id = var.kubernetes_public_address_allocation_id
  }

  load_balancer_type = "network"

  tags = {
    Name = var.tag.value
  }
}

resource "aws_lb_target_group" "kube" {
  name        = var.tag.value
  protocol    = "TCP"
  port        = 6443
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    protocol = "HTTP"
    port     = 80
    path     = "/healthz"
  }

  tags = {
    Name = var.tag.value
  }
}

locals {
  controllers_map = {
    for item in var.instance_controllers: item.private_ip => item
  }
}

resource "aws_lb_target_group_attachment" "kube" {
  target_group_arn = aws_lb_target_group.kube.arn

  for_each         = local.controllers_map
  target_id        = each.key
}

resource "aws_lb_listener" "kube" {
  load_balancer_arn = aws_lb.kube.arn
  protocol          = "TCP"
  port              = "6443"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kube.arn
  }

  tags = {
    Name = var.tag.value
  }
}

output "DEBUG" {
  value = {
    aws_lb = aws_lb.kube
    aws_lb_target_group = aws_lb_target_group.kube
    aws_lb_target_group_attachment = aws_lb_target_group_attachment.kube
    aws_lb_listener = aws_lb_listener.kube
  }
}
