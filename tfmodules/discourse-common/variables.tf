variable "app_name" {
  default = "discourse"
}

variable "tags" {
  type = "map"

  default = {
    Terraform = "true"
  }
}
