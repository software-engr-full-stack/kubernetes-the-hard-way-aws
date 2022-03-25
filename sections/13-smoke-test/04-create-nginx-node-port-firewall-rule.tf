variable "nginx_kubernetes_node_port" {
  type = number
}

variable "security_group_id" {
  type = string
  description = "describe your variable"
  default = "default_value"
}

resource "aws_security_group_rule" "allow_all" {
  type              = "ingress"
  security_group_id = var.security_group_id
  protocol          = "tcp"
  to_port           = var.nginx_kubernetes_node_port
  from_port         = var.nginx_kubernetes_node_port
  cidr_blocks       = ["0.0.0.0/0"]
}
