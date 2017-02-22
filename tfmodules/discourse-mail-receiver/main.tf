data "aws_caller_identity" "current" { }
data "aws_region" "current" {
  current = true
}


#
# S3
#

resource "aws_s3_bucket" "mailbox" {
  bucket = "discourse-mailbox-${var.cname_prefix}-${data.aws_caller_identity.current.account_id}"

  tags {
    Terraform = "true"
  }
}

resource "aws_s3_bucket_policy" "ses_mailbox_access" {
  bucket = "${aws_s3_bucket.mailbox.id}"
  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "GiveSESPermissionToWriteEmail",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "ses.amazonaws.com"
        ]
      },
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::${aws_s3_bucket.mailbox.id}/*",
      "Condition": {
        "StringEquals": {
          "aws:Referer": "${data.aws_caller_identity.current.account_id}"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "discourse_s3_mailbox_access" {
  name = "${var.name_prefix}_s3_mailbox_access"
  role = "${aws_iam_role.lambda_function.name}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.mailbox.id}",
        "arn:aws:s3:::${aws_s3_bucket.mailbox.id}/*"
      ]
    }
  ]
}
EOF
}

#
# Lambda
#

data "archive_file" "lambda_function" {
  type = "zip"
  source_file = "${path.module}/handler.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_iam_role" "lambda_function" {
  name = "${var.name_prefix}_lambda_function"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "${var.name_prefix}_cloudwatch_access"
  role = "${aws_iam_role.lambda_function.name}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
       "Effect":"Allow",
       "Action":"logs:CreateLogGroup",
       "Resource":"arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
    },
    {
     "Effect":"Allow",
     "Action":[
      "logs:CreateLogStream",
      "logs:PutLogEvents"
     ],
     "Resource":[
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.mail_receiver.function_name}:*"
     ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "kms" {
  name = "${var.name_prefix}_kms_access"
  role = "${aws_iam_role.lambda_function.name}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}


resource "aws_lambda_function" "mail_receiver" {
  runtime = "python2.7"
  filename = "${data.archive_file.lambda_function.output_path}"
  function_name = "discourse-mail-receiver-${var.name_prefix}"
  role = "${aws_iam_role.lambda_function.arn}"
  handler = "handler.handler"
  source_code_hash = "${data.archive_file.lambda_function.output_base64sha256}"

  environment {
    variables = {
      S3_BUCKET_NAME = "${aws_s3_bucket.mailbox.id}"
      DISCOURSE_MAIL_ENDPOINT = "${var.discourse_mail_endpoint}"
      DISCOURSE_API_USERNAME = "${var.discourse_api_username}"
    }
  }

  lifecycle {
    ignore_changes = ["environment.0.variables.%", "environment.0.variables.DISCOURSE_API_KEY"]
  }
}

resource "aws_lambda_permission" "from_ses" {
  statement_id = "GiveSESPermissionToInvokeFunction"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.mail_receiver.arn}"
  principal = "ses.amazonaws.com"
  source_account = "${data.aws_caller_identity.current.account_id}"
}

#
# SES
#

resource "aws_ses_receipt_rule" "main" {
  name = "${var.name_prefix}_store_and_post"
  rule_set_name = "${var.ses_rule_set_name}"
  recipients = ["${var.discourse_hostname}"]
  enabled = true
  scan_enabled = false

  s3_action {
    bucket_name = "${aws_s3_bucket.mailbox.id}"
    position = "${var.ses_rule_start_position}"
  }

  lambda_action {
    function_arn = "${aws_lambda_function.mail_receiver.arn}"
    invocation_type = "Event"
    position = "${var.ses_rule_start_position + 1}"
  }
}
