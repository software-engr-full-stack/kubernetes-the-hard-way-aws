variable "region" {
  type = string
}

resource "aws_vpc" "kube" {
  cidr_block = var.cidr_block

  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = var.tag.value
  }
}

resource "aws_subnet" "kube" {
  vpc_id = aws_vpc.kube.id
  cidr_block = var.cidr_block
  availability_zone = format("%s%s", var.region, "a")
  tags = {
    Name = var.tag.value
  }
}

resource "aws_internet_gateway" "kube" {
  vpc_id = aws_vpc.kube.id

  tags = {
    Name = var.tag.value
  }
}

resource "aws_route_table" "kube" {
  vpc_id = aws_vpc.kube.id

  tags = {
    Name = var.tag.value
  }
}

resource "aws_route_table_association" "kube" {
  route_table_id = aws_route_table.kube.id

  subnet_id = aws_subnet.kube.id
}

resource "aws_route" "kube" {
  route_table_id         = aws_route_table.kube.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.kube.id
}

output "virtual_private_cloud_network" {
  value = {
    subnet = aws_subnet.kube
    vpc    = aws_vpc.kube
    route_table = aws_route_table.kube
  }
}
