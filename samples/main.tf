# Terraform config example that puts all ./tfmodules together.
#

module "constants" {
  source = "../../constants"
}

variable "name_prefix" {
  default = "discourse_dev"
}

variable "cname_prefix" {
  default = "discourse-dev"
}

variable "env_name" {
  default     = "discourse-dev"
  description = "Elastic Beanstalk environment name. Must be one of $dev_env_name or $prod_env_name defined in common-variables.sh."
}

variable "discourse_hostname" {
  default = "sandbox.discourse.example.com"
}

variable "cert_s3_bucket" {}

variable "credstash_reader_policy_arn" {}

variable "smtp_address" {}

variable "smtp_user_name" {}

variable "ses_active_receipt_rule_set_name" {}

variable "ses_receipt_rule_set_offset" {
  default = "0"
}

module "vpc" {
  source = "../discourse_eb/tfmodules/discourse-vpc/"

  name_prefix = "${var.name_prefix}"
}

module "db" {
  source = "../discourse_eb/tfmodules/discourse-db/"

  name_prefix            = "${var.name_prefix}"
  subnet_ids             = "${module.vpc.private_subnets}"
  vpc_security_group_ids = "${module.vpc.db_security_group_id}"
}

module "eb" {
  source = "../discourse_eb/tfmodules/discourse-eb/"

  name_prefix               = "${var.name_prefix}"
  app_name                  = "${var.app_name}"
  env_name                  = "${var.env_name}"
  cname_prefix              = "${var.cname_prefix}"
  vpc_id                    = "${module.vpc.vpc_id}"
  subnet_id                 = "${module.vpc.public_subnet}"
  hostname                  = "${var.discourse_hostname}"
  deployment_policy         = "AllAtOnce"
  cert_email                = "admin@${var.discourse_hostname}"
  cert_s3_bucket            = "${var.cert_s3_bucket}"
  certbot_extra_args        = "--staging"
  developer_emails          = "please-set-developer-emails"
  iam_role_policy_arns      = ["${var.credstash_reader_policy_arn}"]
  iam_role_policy_arn_count = "1"
  security_group_ids        = ["${module.vpc.web_security_group_id}"]
  db_host                   = "${module.db.db_host}"
  smtp_address              = "${var.smtp_address}"
  smtp_user_name            = "${var.smtp_user_name}"
}

module "ses" {
  source = "../discourse_eb/tfmodules/discourse-mail-receiver/"

  name_prefix             = "${var.name_prefix}"
  cname_prefix            = "${var.cname_prefix}"
  discourse_hostname      = "${var.discourse_hostname}"
  discourse_mail_endpoint = "https://${var.discourse_hostname}/admin/email/handle_mail"
  ses_rule_set_name       = "${var.ses_active_receipt_rule_set_name}"
  ses_rule_start_position = "${var.ses_receipt_rule_set_offset}"
}
