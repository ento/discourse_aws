data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_s3_bucket" "files" {
  bucket = "discourse-files-${var.cname_prefix}-${data.aws_caller_identity.current.account_id}"

  tags = "${var.tags}"

  # ignore lifecycle rule set up by discourse
  # see: discourse/lib/s3_helper.rb
  lifecycle {
    ignore_changes = ["lifecycle_rule"]
  }
}

resource "aws_iam_instance_profile" "main" {
  name = "${var.name_prefix}_instance_profile"
  role = "${aws_iam_role.main.name}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "main" {
  name = "${var.name_prefix}_role"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "web_tier" {
  role       = "${aws_iam_role.main.name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "ecr" {
  role       = "${aws_iam_role.main.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy" "s3" {
  name = "${var.name_prefix}_s3_access"
  role = "${aws_iam_role.main.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${var.cert_s3_bucket}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "arn:aws:s3:::${var.cert_s3_bucket}/certs/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.files.id}",
        "arn:aws:s3:::${aws_s3_bucket.files.id}/*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "extras" {
  role       = "${aws_iam_role.main.name}"
  policy_arn = "${element(var.iam_role_policy_arns,count.index)}"
  count      = "${var.iam_role_policy_arn_count}"
}

resource "aws_elastic_beanstalk_environment" "main" {
  name                = "${var.env_name}"
  application         = "${var.app_name}"
  cname_prefix        = "${var.cname_prefix}"
  solution_stack_name = "64bit Amazon Linux 2016.09 v2.5.0 running Docker 1.12.6"

  tags = "${var.tags}"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "${aws_iam_instance_profile.main.arn}"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.small"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = "${join(",",var.security_group_ids)}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = "${var.vpc_id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${var.subnet_id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "true"
  }

  # for credstash
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "AWS_DEFAULT_REGION"
    value     = "${data.aws_region.current.name}"
  }

  # ssl

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "CERT_DOMAIN"
    value     = "${var.hostname}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "CERT_EMAIL"
    value     = "${var.cert_email}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "CERT_S3_BUCKET"
    value     = "${var.cert_s3_bucket}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "CERTBOT_EXTRA_ARGS"
    value     = "${var.certbot_extra_args}"
  }

  # discourse env vars

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "LANG"
    value     = "en_US.UTF-8"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RAILS_ENV"
    value     = "production"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "UNICORN_WORKERS"
    value     = "3"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "UNICORN_SIDEKIQS"
    value     = "1"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RUBY_GLOBAL_METHOD_CACHE_SIZE"
    value     = "131072"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RUBY_GC_HEAP_GROWTH_MAX_SLOTS"
    value     = "40000"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RUBY_GC_HEAP_INIT_SLOTS"
    value     = "400000"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR"
    value     = "1.5"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DISCOURSE_HOSTNAME"
    value     = "${var.hostname}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DISCOURSE_DEVELOPER_EMAILS"
    value     = "${var.developer_emails}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DISCOURSE_ENV"
    value     = "${var.env_name}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DISCOURSE_DB_HOST"
    value     = "${var.db_host}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "DISCOURSE_SMTP_ADDRESS"
    value     = "${var.smtp_address}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "DeploymentPolicy"
    value     = "${var.deployment_policy}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = "${var.service_role}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }
}
