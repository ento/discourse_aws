variable "name_prefix" {}

variable "cname_prefix" {}

variable "discourse_hostname" {}

variable "discourse_mail_endpoint" {}

variable "discourse_api_username" {
  default = "system"
}

variable "ses_rule_set_name" {}

variable "ses_rule_start_position" {}
