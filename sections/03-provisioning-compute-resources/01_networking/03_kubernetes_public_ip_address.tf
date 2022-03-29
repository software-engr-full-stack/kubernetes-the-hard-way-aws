resource "aws_eip" "kube" {
  tags = var.base_tag
  vpc = true
}

output "eip" {
  value = aws_eip.kube
}
