data "aws_caller_identity" "current" {}

resource "aws_elastic_beanstalk_application" "main" {
  name = "${var.app_name}"
}

resource "aws_s3_bucket" "main" {
  bucket = "discourse-sourcebundles-${data.aws_caller_identity.current.account_id}"

  tags = "${var.tags}"
}
