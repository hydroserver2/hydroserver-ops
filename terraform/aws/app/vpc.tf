# -------------------------------------------------- #
# AWS HydroServer VPC Setup                          #
# -------------------------------------------------- #

resource "aws_vpc" "hydroserver_vpc" {
  cidr_block           = "10.8.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    "${var.tag_key}" = var.tag_value
  }
}

resource "aws_subnet" "hydroserver_subnet" {
  vpc_id            = aws_vpc.hydroserver_vpc.id
  cidr_block        = "10.8.0.0/24"
  availability_zone = "${var.region}"

  tags = {
    "${var.tag_key}" = var.tag_value
  }
}

resource "aws_security_group" "hydroserver_vpc_sg" {
  name_prefix = "hydroserver-${var.instance}-sg"
  description = "Security group for HydroServer VPC"
  vpc_id      = aws_vpc.hydroserver_vpc.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "-1"
    cidr_blocks = ["10.8.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "${var.tag_key}" = var.tag_value
  }
}
