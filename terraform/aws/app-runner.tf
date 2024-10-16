# ------------------------------------------------ #
# Create an ECR Repository                         #
# ------------------------------------------------ #

resource "aws_ecr_repository" "hydroserver_api_repo" {
  name = "hydroserver-api-${var.instance}"
  lifecycle {
    prevent_destroy = false
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
      image_identifier = "${aws_ecr_repository.hydroserver_repo.repository_url}:latest"
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
}
