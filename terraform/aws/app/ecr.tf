# -------------------------------------------------- #
# Amazon ECR Repository                              #
# -------------------------------------------------- #

resource "aws_ecr_repository" "hydroserver_api_repository" {
  name         = "hydroserver-api-${var.instance}"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    "${var.tag_key}" = var.tag_value
  }
}


# -------------------------------------------------- #
# VPC Endpoints for ECR                              #
# -------------------------------------------------- #

resource "aws_vpc_endpoint" "ecr_api_endpoint" {
  vpc_id            = aws_vpc.hydroserver_vpc.id
  service_name      = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.hydroserver_private_subnet_a.id, aws_subnet.hydroserver_private_subnet_b.id]
  security_group_ids = [aws_security_group.hydroserver_vpc_sg.id]

  tags = {
    "${var.tag_key}" = var.tag_value
  }
}

resource "aws_vpc_endpoint" "ecr_dkr_endpoint" {
  vpc_id            = aws_vpc.hydroserver_vpc.id
  service_name      = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids        = [aws_subnet.hydroserver_private_subnet_a.id, aws_subnet.hydroserver_private_subnet_b.id]
  security_group_ids = [aws_security_group.hydroserver_vpc_sg.id]

  tags = {
    "${var.tag_key}" = var.tag_value
  }
}
