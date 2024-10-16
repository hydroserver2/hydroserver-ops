# ------------------------------------------------ #
# Create an ECR Repository                         #
# ------------------------------------------------ #

resource "aws_ecr_repository" "hydroserver_api_repo" {
  name = "hydroserver-api-${var.instance}"

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    (var.tag_key) = local.tag_value
  }
}

# ------------------------------------------------ #
# Create App Runner Service                        #
# ------------------------------------------------ #

resource "aws_apprunner_service" "hydroserver_api_service" {
  service_name = "hydroserver-api-${var.instance}"

  source_configuration {
    authentication_configuration {
      access_role_arn = aws_iam_role.apprunner_service_role.arn
    }
    image_repository {
      image_identifier = "${aws_ecr_repository.hydroserver_api_repo.repository_url}:latest"
      image_repository_type = "ECR"
      image_configuration {
        port = "8000"
      }
    }
  }

  instance_configuration {
    cpu    = "1 vCPU"
    memory = "2 GB"
    instance_role_arn = aws_iam_role.apprunner_service_role.arn
  }

  tags = {
    (var.tag_key) = local.tag_value
  }
}

# ------------------------------------------------ #
# Create a Service Role for App Runner             #
# ------------------------------------------------ #

resource "aws_iam_role" "apprunner_service_role" {
  name = "hydroserver-api-service-role-${var.instance}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "build.apprunner.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    (var.tag_key) = local.tag_value
  }
}

# ------------------------------------------------ #
# Attach Policies to Service Role                  #
# ------------------------------------------------ #

resource "aws_iam_policy" "apprunner_service_role_policy" {
  name = "hydroserver-api-service-role-policy-${var.instance}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::hydroserver-api-storage-${var.instance}",
          "arn:aws:s3:::hydroserver-api-storage-${var.instance}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories",
          "ecr:GetAuthorizationToken"
        ]
        Resource = "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/hydroserver-api-${var.instance}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "apprunner_service_role_policy_attachment" {
  role       = aws_iam_role.apprunner_service_role.name
  policy_arn = aws_iam_policy.apprunner_service_role_policy.arn
}
