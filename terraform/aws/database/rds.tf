er# -------------------------------------------------- #
# AWS HydroServer RDS PostgreSQL Database            #
# -------------------------------------------------- #

resource "aws_db_instance" "hydroserver_db_instance" {

  # Basic Configuration
  identifier            = "hydroserver-${var.instance}"
  engine                = "postgres"
  engine_version        = "15"
  instance_class        = "db.t4g.micro"
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"
  publicly_accessible   = false

  # Networking Configuration
  db_subnet_group_name   = aws_db_subnet_group.hydroserver_db_subnet_group.name
  vpc_security_group_ids = [data.aws_security_group.hydroserver_sg.id]

  # High Availability
  multi_az = true

  # Encryption
  storage_encrypted = true

  # Backup Configuration
  backup_retention_period = 7
  backup_window           = "03:00-04:00"

  # Performance Insights
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  # Enhanced Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.enhanced_monitoring_role.arn

  # Database Credentials
  username = "hsdbadmin"
  password = random_password.hydroserver_db_user_password.result

  # Tags for resource tracking
  tags = {
    "${var.tag_key}" = var.tag_value
  }

  # Lifecycle settings
  lifecycle {
    ignore_changes = [
      instance_class,
      allocated_storage,
      max_allocated_storage
    ]
  }
}

resource "null_resource" "create_hydroserver_db" {
  depends_on = [aws_db_instance.hydroserver_db_instance]

  provisioner "local-exec" {
    command = <<EOT
      PGPASSWORD="${random_password.hydroserver_db_user_password.result}" \
      psql -h ${aws_db_instance.hydroserver_db_instance.address} \
           -U hsdbadmin \
           -c "CREATE DATABASE hydroserver;"
    EOT
  }
}

data "aws_subnet" "hydroserver_subnet_a" {
  filter {
    name   = "tag:name"
    values = ["hydroserver-private-${var.instance}-a"]
  }
}

data "aws_subnet" "hydroserver_subnet_b" {
  filter {
    name   = "tag:name"
    values = ["hydroserver-private-${var.instance}-b"]
  }
}

resource "aws_db_subnet_group" "hydroserver_db_subnet_group" {
  name       = "hydroserver-db-subnet-group"
  subnet_ids = [
    data.aws_subnet.hydroserver_subnet_a.id,
    data.aws_subnet.hydroserver_subnet_b.id
  ]

  tags = {
    "${var.tag_key}" = var.tag_value
  }
}

data "aws_security_group" "hydroserver_sg" {
  filter {
    name   = "tag:name"
    values = ["hydroserver-${var.instance}"]
  }
}

resource "random_password" "hydroserver_db_user_password" {
  length  = 16
  special = false
}

# -------------------------------------------------- #
# IAM Role for RDS Enhanced Monitoring               #
# -------------------------------------------------- #

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
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring_role_attachment" {
  role       = aws_iam_role.enhanced_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# -------------------------------------------------- #
# AWS Secrets Manager for Database Credentials       #
# -------------------------------------------------- #

resource "aws_secretsmanager_secret" "hydroserver_database_url" {
  name = "hydroserver-database-url-${var.instance}"

  tags = {
    "${var.tag_key}" = var.tag_value
  }
}

resource "aws_secretsmanager_secret_version" "hydroserver_database_url_version" {
  secret_id     = aws_secretsmanager_secret.hydroserver_database_url.id
  secret_string = "postgresql://${aws_db_instance.hydroserver_db_instance.username}:${random_password.hydroserver_db_user_password.result}@${aws_db_instance.hydroserver_db_instance.endpoint}/hydroserver?sslmode=disable"
}

resource "random_password" "hydroserver_api_secret_key" {
  length           = 50
  special          = true
  upper            = true
  lower            = true
  numeric          = true
  override_special = "!@#$%^&*()-_=+{}[]|:;\"'<>,.?/"
}

resource "aws_secretsmanager_secret" "hydroserver_api_secret_key" {
  name = "hydroserver-api-secret-key-${var.instance}"

  tags = {
    "${var.tag_key}" = var.tag_value
  }
}

resource "aws_secretsmanager_secret_version" "hydroserver_api_secret_key_version" {
  secret_id     = aws_secretsmanager_secret.hydroserver_api_secret_key.id
  secret_string = random_password.hydroserver_api_secret_key.result
}
