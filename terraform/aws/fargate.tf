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
  execution_role_arn       = aws_iam_role.ecs_worker_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_worker_task_role.arn

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


# ---------------------------------
# ECS Task Role
# ---------------------------------

resource "aws_iam_role" "ecs_worker_task_role" {
  name = "hydroserver-${var.instance}-ecs-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "ecs_worker_role_ssm" {
  name       = "hydroserver-${var.instance}-ecs-ssm-attachment"
  roles      = [aws_iam_role.ecs_worker_task_role.name]
  policy_arn = aws_iam_policy.app_runner_ssm_policy.arn
}

resource "aws_iam_policy_attachment" "ecs_worker_task_role_s3" {
  name       = "hydroserver-${var.instance}-ecs-s3-attachment"
  roles      = [aws_iam_role.ecs_worker_task_role.name]
  policy_arn = aws_iam_policy.app_runner_s3_policy.arn
}

resource "aws_iam_policy_attachment" "ecs_worker_task_role_rds" {
  name       = "hydroserver-${var.instance}-ecs-worker-rds-attachment"
  roles      = [aws_iam_role.ecs_worker_task_role.name]
  policy_arn = aws_iam_policy.app_runner_rds_policy[0].arn
}

# ---------------------------------
# ECS Execution Role
# ---------------------------------

resource "aws_iam_role" "ecs_worker_execution_role" {
  name = "hydroserver-${var.instance}-ecs-worker-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy_attachment" "ecs_worker_execution_ecr" {
  name       = "hydroserver-${var.instance}-ecs-worker-ecr-attachment"
  roles      = [aws_iam_role.ecs_worker_execution_role.name]
  policy_arn = aws_iam_policy.app_runner_ecr_access_policy.arn
}

resource "aws_iam_policy_attachment" "ecs_worker_execution_logs" {
  name       = "hydroserver-${var.instance}-ecs-worker-logs-attachment"
  roles      = [aws_iam_role.ecs_worker_execution_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_task_ssm_policy_attachment" {
  role       = aws_iam_role.ecs_worker_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_ssm_policy.arn
}
