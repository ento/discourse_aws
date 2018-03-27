variable "name_prefix" {
  default = "discourse"
}

variable "tags" {
  type = "map"

  default = {
    Terraform = "true"
  }
}
