variable "key_name" {
  type = string
}

variable "security_groups" {
  type = list(string)
}

variable "subnet_id" {
  type = string
}
