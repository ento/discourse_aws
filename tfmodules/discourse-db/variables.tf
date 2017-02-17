variable "name_prefix" {
  default = "discourse"
}

variable "allocated_storage" {
  default = "5"
}

variable "engine_version" {
  default = "9.5.4"
}

variable "instance_class" {
  default = "db.t2.micro"
}

variable "storage_type" {
  default = "standard"
}

variable "backup_retention_period" {
  default = "1"
}

variable "multi_az" {
  default = "false"
}

variable "vpc_security_group_ids" {
}

variable "subnet_ids" {
  type = "list"
}

variable "parameter_group_family" {
  default = "postgres9.5"
}
