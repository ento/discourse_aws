data "aws_availability_zones" "available" {
}

module "vpc" {
  source = "github.com/terraform-community-modules/tf_aws_vpc?ref=e1d1541"

  name = var.name_prefix

  cidr            = "10.0.0.0/16"
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24"]

  azs = [data.aws_availability_zones.available.names]

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = var.tags
}

resource "aws_security_group" "web" {
  name   = "${var.name_prefix}_web"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_security_group" "db" {
  name   = "${var.name_prefix}_db"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "TCP"
    security_groups = [aws_security_group.web.id]
  }

  tags = var.tags
}
