resource "aws_eip" "kube" {
  tags = {
    Name = var.tag.value
  }
  vpc = true
}
