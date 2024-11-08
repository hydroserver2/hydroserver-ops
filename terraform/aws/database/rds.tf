# -------------------------------------------------- #
# AWS HydroServer RDS PostgreSQL Database            #
# -------------------------------------------------- #

resource "aws_db_instance" "hydroserver_db_instance" {
  identifier              = "hydroserver-${var.instance}"
  engine                  = "postgres"
  engine_version          = "15"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  storage_type            = "gp2"
  publicly_accessible     = false
  db_subnet_group_name    = aws_db_subnet_group.hydroserver_db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.hydroserver_vpc_sg.id]
  max_allocated_storage   = 100

  username = "hsdbadmin"
  password = random_password.hydroserver_db_user_password.result

  tags = {
    "${var.tag_key}" = var.tag_value
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

resource "random_password" "hydroserver_db_user_password" {
  length  = 16
  special = false
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
  secret_string = "postgresql://${aws_db_instance.hydroserver_db_instance.username}:${random_password.hydroserver_db_user_password.result}@${aws_db_instance.hydroserver_db_instance.endpoint}:${aws_db_instance.hydroserver_db_instance.port}/${aws_db_instance.hydroserver_db_instance.db_name}?sslmode=disable"
}

resource "random_password" "hydroserver_api_secret_key" {
  length           = 50
  special          = true
  upper            = true
  lower            = true
  number           = true
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
