variable "name" {
  type = string
}

variable "base_tag" {
  type = object({
    Name = string
  })
}

variable "cidr_block" {
  type = string
}
