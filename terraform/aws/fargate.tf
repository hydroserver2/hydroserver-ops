# ---------------------------------
# ECS Fargate Cluster
# ---------------------------------

resource "aws_ecs_cluster" "workers" {
  name = "hydroserver-workers-${var.instance}"
}


# ---------------------------------
# Worker Task Definition
# ---------------------------------

resource "aws_ecs_task_definition" "hydroserver_worker" {
  family                   = "hydroserver-worker-${var.instance}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"  # 1 vCPU
  memory                   = "2048"  # 2 GB
  execution_role_arn       = aws_iam_role.app_runner_access_role.arn
  task_role_arn            = aws_iam_role.app_runner_service_role.arn

  container_definitions = jsonencode([
    {
      name      = "hydroserver_worker"
      image     = "${aws_ecr_repository.api_repository.repository_url}:latest"
      command   = ["python", "manage.py", "db_worker"]

      environment = [
        { name = "DEPLOYED", value = "True" },
        { name = "DEPLOYMENT_BACKEND", value = "aws" },
        { name = "USE_TASKS_BACKEND", value = "True" },
        { name = "STATIC_BUCKET_NAME", value = aws_s3_bucket.static_bucket.bucket },
        { name = "MEDIA_BUCKET_NAME",  value = aws_s3_bucket.media_bucket.bucket }
      ]

      secrets = [
        { name = "DATABASE_URL", valueFrom = aws_ssm_parameter.database_url.arn },
        { name = "SMTP_URL",     valueFrom = aws_ssm_parameter.smtp_url.arn },
        { name = "SECRET_KEY",   valueFrom = aws_ssm_parameter.secret_key.arn },
        { name = "AWS_CLOUDFRONT_KEY_ID", valueFrom = aws_ssm_parameter.signing_key_id.arn },
        { name = "AWS_CLOUDFRONT_KEY",    valueFrom = aws_ssm_parameter.signing_key.arn },
        { name = "PROXY_BASE_URL",        valueFrom = aws_ssm_parameter.proxy_base_url.arn },
        { name = "DEBUG",                 valueFrom = aws_ssm_parameter.debug_mode.arn },
        { name = "DEFAULT_SUPERUSER_EMAIL",    valueFrom = aws_ssm_parameter.admin_email.arn },
        { name = "DEFAULT_SUPERUSER_PASSWORD", valueFrom = aws_ssm_parameter.admin_password.arn },
        { name = "DEFAULT_FROM_EMAIL",         valueFrom = aws_ssm_parameter.default_from_email.arn },
        { name = "ACCOUNT_SIGNUP_ENABLED",     valueFrom = aws_ssm_parameter.account_signup_enabled.arn },
        { name = "ACCOUNT_OWNERSHIP_ENABLED",  valueFrom = aws_ssm_parameter.account_ownership_enabled.arn },
        { name = "SOCIALACCOUNT_SIGNUP_ONLY",  valueFrom = aws_ssm_parameter.socialaccount_signup_only.arn }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/hydroserver-worker-${var.instance}"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}


# ---------------------------------
# ECS Fargate Service
# ---------------------------------

resource "aws_ecs_service" "hydroserver_worker" {
  name            = "hydroserver-worker-${var.instance}"
  cluster         = aws_ecs_cluster.workers.id
  task_definition = aws_ecs_task_definition.hydroserver_worker.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets = [
      aws_subnet.private_subnet_az1.id,
      aws_subnet.private_subnet_az2.id
    ]
    security_groups = [aws_security_group.app_runner_sg.id]
    assign_public_ip = false
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
}