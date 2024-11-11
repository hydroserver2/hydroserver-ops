# -------------------------------------------------- #
# HydroServer AWS App Runner Service                 #
# -------------------------------------------------- #

resource "aws_apprunner_service" "hydroserver_api" {
  service_name = "hydroserver-api-${var.instance}"

  source_configuration {
    image_repository {
      image_identifier = "${aws_ecr_repository.hydroserver_api_repository.repository_url}:latest"
      image_repository_type = "ECR"
    }

    authentication_configuration {
      access_role_arn = aws_iam_role.app_runner_service_role.arn
    }

    environment_variables {
      DATABASE_URL         = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:hydroserver-database-url-${var.instance}"
      SECRET_KEY           = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:hydroserver-api-secret-key-${var.instance}"
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

  vpc_configuration {
    vpc_id          = aws_vpc.hydroserver_vpc.id
    subnets         = [aws_subnet.hydroserver_private_subnet_a.id, aws_subnet.hydroserver_private_subnet_b.id]
    security_group_ids = [aws_security_group.hydroserver_vpc_sg.id]
  }

  health_check_configuration {
    protocol = "HTTP"
    path     = "/"
    interval_seconds = 30
    timeout_seconds = 5
    retries = 3
  }

  service_role = aws_iam_role.app_runner_service_role.arn

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
          # aws_secretsmanager_secret.hydroserver_smtp_url.arn,
          # aws_secretsmanager_secret.hydroserver_oauth_google.arn,
          # aws_secretsmanager_secret.hydroserver_oauth_hydroshare.arn,
          # aws_secretsmanager_secret.hydroserver_oauth_orcid.arn,
          # aws_s3_bucket.hydroserver_storage_bucket.arn
        ]
      }
    ]
  })
}
