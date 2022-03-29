variable "name" {
  type = string
}

variable "base_tag" {
  type = object({
    Name = string
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
  # TODO: put more specific type
  type = any
}

resource "aws_lb" "kube" {
  name = var.name

  subnet_mapping {
    subnet_id     = var.subnet_id
    allocation_id = var.kubernetes_public_address_allocation_id
  }

  load_balancer_type = "network"

  tags = var.base_tag
}

resource "aws_lb_target_group" "kube" {
  name        = var.name
  protocol    = "TCP"
  port        = 6443
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    protocol = "HTTP"
    port     = 80
    path     = "/healthz"
  }

  tags = var.base_tag
}

resource "aws_lb_target_group_attachment" "kube" {
  target_group_arn = aws_lb_target_group.kube.arn

  for_each         = var.instance_controllers
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

  tags = var.base_tag
}
