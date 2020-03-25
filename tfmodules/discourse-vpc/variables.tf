variable "name_prefix" {
  default = "discourse"
}

variable "tags" {
  type = map(string)

  default = {
    Terraform = "true"
  }
}
