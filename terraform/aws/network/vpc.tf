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
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name             = "hydroserver-private-${var.instance}-a"
    "${var.tag_key}" = var.tag_value
  }
}

resource "aws_subnet" "hydroserver_private_subnet_b" {
  vpc_id            = aws_vpc.hydroserver_vpc.id
  cidr_block        = "10.8.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name             = "hydroserver-private-${var.instance}-b"
    "${var.tag_key}" = var.tag_value
  }
}
