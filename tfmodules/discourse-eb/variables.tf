variable "name_prefix" {}

variable "app_name" {}

variable "env_name" {}

variable "tags" {
  type = "map"

  default = {
    Terraform = "true"
  }
}

variable "vpc_id" {}

variable "subnet_id" {}

variable "deployment_policy" {
  default = "Immmutable"
}

variable "hostname" {}

variable "cname_prefix" {}

variable "cert_email" {}

variable "cert_s3_bucket" {}

variable "certbot_extra_args" {
  default = ""
}

variable "developer_emails" {}

variable "iam_role_policy_arns" {
  type    = "list"
  default = []
}

variable "iam_role_policy_arn_count" {
  default = "0"
}

variable "security_group_ids" {
  type = "list"
}

variable "db_host" {}

variable "smtp_address" {}

variable "service_role" {
  default = "aws-elasticbeanstalk-service-role"
}
