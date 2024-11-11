# -------------------------------------------------- #
# Amazon ECR Repository                              #
# -------------------------------------------------- #

resource "aws_ecr_repository" "hydroserver_api_repository" {
  name = "hydroserver-api-${var.instance}"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    "${var.label_key}" = var.label_value
  }
}


# -------------------------------------------------- #
# VPC Endpoints for ECR                              #
# -------------------------------------------------- #

resource "aws_vpc_endpoint" "ecr_api_endpoint" {
  vpc_id            = aws_vpc.hydroserver_vpc.id
  service_name      = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.hydroserver_subnet_a.id, aws_subnet.hydroserver_subnet_b.id]
  security_group_ids = [aws_security_group.hydroserver_sg.id]

  tags = {
    "${var.label_key}" = var.label_value
  }
}

resource "aws_vpc_endpoint" "ecr_dkr_endpoint" {
  vpc_id            = aws_vpc.hydroserver_vpc.id
  service_name      = "com.amazonaws.${var.region}.ecr.dkr"  # Docker ECR endpoint
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.hydroserver_subnet_a.id, aws_subnet.hydroserver_subnet_b.id]
  security_group_ids = [aws_security_group.hydroserver_sg.id]

  tags = {
    "${var.label_key}" = var.label_value
  }
}
