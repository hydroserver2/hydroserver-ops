# -------------------------------------------------- #
# HydroServer AWS App Runner Service                 #
# -------------------------------------------------- #

resource "aws_apprunner_service" "hydroserver_api" {
  service_name = "hydroserver-api-${var.instance}"

  source_configuration {
    image_repository {
      image_identifier = "${aws_ecr_repository.hydroserver_api_repository.repository_url}:latest"
      image_repository_type = "ECR"
      image_configuration {
        runtime_environment_secrets = {
          DATABASE_URL         = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:hydroserver-database-url-${var.instance}"
          SECRET_KEY           = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:hydroserver-api-secret-key-${var.instance}"
        }
    
        runtime_environment_variables = {
          DEPLOYED             = "True"
          DEPLOYMENT_BACKEND   = "aws"
          # STORAGE_BUCKET       = aws_s3_bucket.hydroserver_storage_bucket.bucket
          # SMTP_URL             = aws_secretsmanager_secret.hydroserver_smtp_url.arn
          # ACCOUNTS_EMAIL       = aws_secretsmanager_secret.hydroserver_oauth_google.arn
          PROXY_BASE_URL       = ""
          ALLOWED_HOSTS        = ""
          # OAUTH_GOOGLE         = aws_secretsmanager_secret.hydroserver_oauth_google.arn
          # OAUTH_ORCID          = aws_secretsmanager_secret.hydroserver_oauth_orcid.arn
          # OAUTH_HYDROSHARE     = aws_secretsmanager_secret.hydroserver_oauth_hydroshare.arn
          DEBUG                = ""
        }
      }
    }

    auto_deployments_enabled = false

    authentication_configuration {
      access_role_arn = aws_iam_role.app_runner_service_role.arn
    }
  }

  network_configuration {
    ingress_configuration {
      is_publicly_accessible = false
    }

    egress_configuration {
      egress_type       = "VPC"
      vpc_connector_arn = aws_vpc.hydroserver_vpc.arn
    }
  }

  health_check_configuration {
    protocol = "HTTP"
    path     = "/admin/"
    interval = 20
    timeout  = 5
  }

  tags = {
    "${var.tag_key}" = var.tag_value
  }
}

# -------------------------------------------------- #
# IAM Role for App Runner Service                   #
# -------------------------------------------------- #

resource "aws_iam_role" "app_runner_service_role" {
  name = "hydroserver-api-service-role-${var.instance}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "app_runner_policy_attachment" {
  name       = "hydroserver-api-service-policy-attachment-${var.instance}"
  policy_arn = aws_iam_policy.app_runner_service_policy.arn
  roles      = [aws_iam_role.app_runner_service_role.name]
}

resource "aws_iam_policy" "app_runner_service_policy" {
  name = "hydroserver-api-service-policy-${var.instance}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = [
          "secretsmanager:GetSecretValue",
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = [
        ]
      }
    ]
  })
}


