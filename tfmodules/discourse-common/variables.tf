variable "app_name" {
  default = "discourse"
}

variable "tags" {
  type = map(string)

  default = {
    Terraform = "true"
  }
}
