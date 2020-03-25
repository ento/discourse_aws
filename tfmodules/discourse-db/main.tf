resource "aws_db_instance" "main" {
  allocated_storage = var.allocated_storage
  engine            = "postgres"
  engine_version    = var.engine_version
  identifier        = replace(var.name_prefix, "_", "-")
  instance_class    = var.instance_class
  storage_type      = var.storage_type

  name     = "discourse"
  password = "changeme"
  username = "discourse"

  backup_retention_period = var.backup_retention_period

  multi_az = var.multi_az

  vpc_security_group_ids = [var.vpc_security_group_ids]
  db_subnet_group_name   = aws_db_subnet_group.main.name

  parameter_group_name = aws_db_parameter_group.main.name

  tags = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_db_subnet_group" "main" {
  name        = var.name_prefix
  description = var.name_prefix
  subnet_ids  = var.subnet_ids

  tags = var.tags
}

resource "aws_db_parameter_group" "main" {
  name   = replace(var.name_prefix, "_", "-")
  family = var.parameter_group_family

  #  parameter = ["${concat(var.default_parameters, var.extra_parameters)}"]
  parameter {
    name  = "synchronous_commit"
    value = "off"
  }
  parameter {
    # commenting out: trusting RDS's default
    #    {
    #      name = "shared_buffers"
    #      value = "256MB"
    #    },
    name = "work_mem"

    value = 10 * 1024 # 10MB: unit is kb in RDS param group
  }
  parameter {
    # commenting out: not in RDS parameter group
    #    {
    #      name = "default_text_search_config"
    #      value = "pg_catalog.english"
    #    },
    # commenting out: not in RDS parameter group
    #    {
    #      name = "wal_level"
    #      value = "minimal"
    #    },
    # commenting out: cannot set to zero on RDS
    #    {
    #      name = "max_wal_senders"
    #      value = "0"
    #    },
    # commenting out: not in RDS parameter group
    #    {
    #      name = "checkpoint_segments"
    #      value = "6"
    #    },
    # commenting out: logging_collector cannot be modified on RDS
    #    {
    #      name = "logging_collector"
    #      value = "off"
    #    },
    name = "log_min_duration_statement"

    value = "100"
  }

  tags = var.tags
}
