# -------------------------------------------------- #
# AWS HydroServer VPC Setup                          #
# -------------------------------------------------- #

resource "aws_vpc" "hydroserver_vpc" {
  cidr_block           = "10.8.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name             = "hydroserver-${var.instance}"
    "${var.tag_key}" = var.tag_value
  }
}

resource "aws_subnet" "hydroserver_private_subnet_a" {
  vpc_id            = aws_vpc.hydroserver_vpc.id
  cidr_block        = "10.8.0.0/24"
  availability_zone = "${var.region}a"

  tags = {
    name             = "hydroserver-private-${var.instance}-a"
    "${var.tag_key}" = var.tag_value
  }
}

resource "aws_subnet" "hydroserver_private_subnet_b" {
  vpc_id            = aws_vpc.hydroserver_vpc.id
  cidr_block        = "10.8.1.0/24"
  availability_zone = "${var.region}b"

  tags = {
    name             = "hydroserver-private-${var.instance}-b"
    "${var.tag_key}" = var.tag_value
  }
}

# -------------------------------------------------- #
# AWS HydroServer VPC Security Group                 #
# -------------------------------------------------- #

resource "aws_security_group" "hydroserver_vpc_sg" {
  name_prefix = "hydroserver-${var.instance}-sg"
  description = "Security group for HydroServer VPC"
  vpc_id      = aws_vpc.hydroserver_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.8.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name             = "hydroserver-${var.instance}"
    "${var.tag_key}" = var.tag_value
  }
}
