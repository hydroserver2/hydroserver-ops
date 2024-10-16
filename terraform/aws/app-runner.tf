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
# Create App Runner Service                         #
# ------------------------------------------------ #

resource "aws_apprunner_service" "hydroserver_api_service" {
  service_name = "hydroserver-api-${var.instance}"

  service_role_arn = aws_iam_role.apprunner_service_role.arn

  source {
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
  }

  auto_deployments_enabled = true

  tags = {
    (var.tag_key) = local.tag_value
  }
}

# ------------------------------------------------ #
# Create a Service Role for App Runner            #
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

resource "aws_iam_role_policy_attachment" "service_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/hydroserver-api-service-role-${var.instance}"
  role       = aws_iam_role.apprunner_service_role.name
}

resource "aws_iam_role_policy_attachment" "ecr_access_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.apprunner_service_role.name
}
