variable "pod_cidr_block" {
  type = string
}

variable "ssh_port" {
  type = number
}

variable "kube_apiserver_port" {
  type = number
}

resource "aws_security_group" "kube" {
  vpc_id = aws_vpc.kube.id
  name = var.name
  description = "Kubernetes The Hard Way - AWS: security group"

  tags = var.base_tag

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = [var.cidr_block]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = [var.pod_cidr_block]
  }

  ingress {
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.kube_apiserver_port
    to_port     = var.kube_apiserver_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "firewall" {
  value = aws_security_group.kube
}
