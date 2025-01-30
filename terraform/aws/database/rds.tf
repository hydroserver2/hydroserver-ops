# ---------------------------------
# RDS PostgreSQL Database
# ---------------------------------

resource "aws_db_instance" "rds_db_instance" {
  identifier                 = "hydroserver-${var.instance}"
  engine                     = "postgres"
  engine_version             = "15"
  instance_class             = "db.t4g.micro"

  storage_type               = "gp2"
  storage_encrypted          = true
  allocated_storage          = 20
  max_allocated_storage      = 100

  publicly_accessible        = false
  multi_az                   = true

  db_subnet_group_name       = aws_db_subnet_group.rds_subnet_group.name

  deletion_protection        = true
  apply_immediately          = true
  auto_minor_version_upgrade = true

  backup_retention_period = 7
  backup_window           = "03:00-04:00"

  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.enhanced_monitoring_role.arn

  db_name  = "hydroserver"
  username = "hsdbadmin"
  password = "${random_string.rds_db_user_password_prefix.result}${random_password.rds_db_user_password.result}"

  tags = {
    "${var.tag_key}" = local.tag_value
  }

  lifecycle {
    ignore_changes = [
      instance_class,
      storage_type,
      allocated_storage,
      max_allocated_storage,
      backup_retention_period,
      backup_window,
      performance_insights_enabled,
      performance_insights_retention_period,
      monitoring_interval
    ]
  }
}

resource "random_password" "rds_db_user_password" {
  length           = 15
  upper            = true
  min_upper        = 1
  lower            = true
  min_lower        = 1
  numeric          = true
  min_numeric      = 1
  special          = true
  min_special      = 1
  override_special = "-_~*"
}

resource "random_string" "rds_db_user_password_prefix" {
  length           = 1
  upper            = true
  lower            = true
  numeric          = false
  special          = false
}


# ---------------------------------
# IAM Role for RDS Monitoring
# ---------------------------------

resource "aws_iam_role" "enhanced_monitoring_role" {
  name = "hydroserver-enhanced-monitoring-role-${var.instance}"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
          "Service": "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring_role_attachment" {
  role       = aws_iam_role.enhanced_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}


# ---------------------------------
# AWS Secrets Manager
# ---------------------------------

resource "aws_secretsmanager_secret" "rds_database_url" {
  name = "hydroserver-${var.instance}-database-url"

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_secretsmanager_secret_version" "rds_database_url_version" {
  secret_id     = aws_secretsmanager_secret.rds_database_url.id
  secret_string = "postgresql://${aws_db_instance.rds_db_instance.username}:${random_password.rds_db_user_password.result}@${aws_db_instance.rds_db_instance.endpoint}/hydroserver?sslmode=require"
}

resource "random_password" "api_secret_key" {
  length           = 50
  special          = true
  upper            = true
  lower            = true
  numeric          = true
  override_special = "!@#$%^&*()-_=+{}[]|:;\"'<>,.?/"
}

resource "aws_secretsmanager_secret" "api_secret_key" {
  name = "hydroserver-${var.instance}-api-secret-key"

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

resource "aws_secretsmanager_secret_version" "api_secret_key_version" {
  secret_id     = aws_secretsmanager_secret.api_secret_key.id
  secret_string = random_password.api_secret_key.result
}
