variable "name_prefix" {
}

variable "tags" {
  type = map(string)

  default = {
    Terraform = "true"
  }
}

variable "cname_prefix" {
}

variable "discourse_hostname" {
}

variable "discourse_mail_endpoint" {
}

variable "discourse_api_username" {
  default = "system"
}

variable "mailbox_bucket_logging_target_bucket" {
  default = ""
}

variable "mailbox_bucket_logging_target_prefix" {
  default = ""
}

variable "ses_rule_set_name" {
}

variable "ses_rule_start_position" {
}

