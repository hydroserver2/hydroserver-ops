# ---------------------------------
# AWS App Runner Service
# ---------------------------------

resource "aws_apprunner_service" "api" {
  service_name = "hydroserver-api-${var.instance}"

  depends_on = [
    aws_s3_bucket.static_bucket,
    aws_s3_bucket.media_bucket
  ]
  
  instance_configuration {
    instance_role_arn = aws_iam_role.app_runner_service_role.arn
  }

  source_configuration {
    image_repository {
      image_identifier = "${aws_ecr_repository.api_repository.repository_url}:latest"
      image_repository_type = "ECR"
      image_configuration {
        port = "8000"
        runtime_environment_secrets = {
          DATABASE_URL         = data.aws_secretsmanager_secret.rds_database_url.arn
          SECRET_KEY           = data.aws_secretsmanager_secret.api_secret_key.arn
        }
        runtime_environment_variables = {
          DEPLOYED             = "True"
          DEPLOYMENT_BACKEND   = "aws"
          PROXY_BASE_URL       = "https://www.example.com"
          STATIC_BUCKET_NAME   = aws_s3_bucket.static_bucket.bucket
          MEDIA_BUCKET_NAME    = aws_s3_bucket.media_bucket.bucket
        }
      }
    }

    auto_deployments_enabled = false

    authentication_configuration {
      access_role_arn = aws_iam_role.app_runner_access_role.arn
    }
  }

  health_check_configuration {
    protocol = "HTTP"
    interval = 20
    timeout  = 18
  }

  network_configuration {
    egress_configuration {
      egress_type = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.rds_connector.arn
    }
  }

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}


# ---------------------------------
# App Runner RDS VPC Connector
# ---------------------------------

resource "aws_apprunner_vpc_connector" "rds_connector" {
  vpc_connector_name = "hydroserver-${var.instance}"
  subnet_ids = [
    aws_subnet.rds_subnet_a.id,
    aws_subnet.rds_subnet_b.id
  ]

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}
