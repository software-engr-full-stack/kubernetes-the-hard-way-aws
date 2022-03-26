variable "tag" {
  type = object({
      value = string
    })
}

variable "cidr_block" {
  type = string
}
