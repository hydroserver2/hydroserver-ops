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

# -------------------------------------------------- #
# Private Subnets for Database                       #
# -------------------------------------------------- #

resource "aws_subnet" "hydroserver_private_db_subnet_a" {
  vpc_id            = aws_vpc.hydroserver_vpc.id
  cidr_block        = "10.8.0.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name             = "hydroserver-private-db-${var.instance}-a"
    "${var.tag_key}" = var.tag_value
  }
}

resource "aws_subnet" "hydroserver_private_db_subnet_b" {
  vpc_id            = aws_vpc.hydroserver_vpc.id
  cidr_block        = "10.8.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name             = "hydroserver-private-db-${var.instance}-b"
    "${var.tag_key}" = var.tag_value
  }
}

# -------------------------------------------------- #
# Private Subnets for Applications                   #
# -------------------------------------------------- #

resource "aws_subnet" "hydroserver_private_app_subnet_a" {
  vpc_id            = aws_vpc.hydroserver_vpc.id
  cidr_block        = "10.8.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name             = "hydroserver-private-app-${var.instance}-a"
    "${var.tag_key}" = var.tag_value
  }
}

resource "aws_subnet" "hydroserver_private_app_subnet_b" {
  vpc_id            = aws_vpc.hydroserver_vpc.id
  cidr_block        = "10.8.3.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name             = "hydroserver-private-app-${var.instance}-b"
    "${var.tag_key}" = var.tag_value
  }
}

# -------------------------------------------------- #
# Internet Gateway and Route Table for Public Access #
# -------------------------------------------------- #

resource "aws_internet_gateway" "hydroserver_igw" {
  vpc_id = aws_vpc.hydroserver_vpc.id

  tags = {
    Name             = "hydroserver-igw-${var.instance}"
    "${var.tag_key}" = var.tag_value
  }
}

# -------------------------------------------------- #
# Public Route Table for Internet Access            #
# -------------------------------------------------- #

resource "aws_route_table" "hydroserver_public_route_table" {
  vpc_id = aws_vpc.hydroserver_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.hydroserver_igw.id
  }

  tags = {
    Name             = "hydroserver-public-route-table-${var.instance}"
    "${var.tag_key}" = var.tag_value
  }
}

resource "aws_route_table_association" "hydroserver_public_route_table_association" {
  subnet_id      = aws_subnet.hydroserver_private_app_subnet_a.id
  route_table_id = aws_route_table.hydroserver_public_route_table.id
}

resource "aws_route_table_association" "hydroserver_public_route_table_association_b" {
  subnet_id      = aws_subnet.hydroserver_private_app_subnet_b.id
  route_table_id = aws_route_table.hydroserver_public_route_table.id
}

# -------------------------------------------------- #
# Private Route Tables for Internal Services        #
# -------------------------------------------------- #

resource "aws_route_table" "hydroserver_private_route_table" {
  vpc_id = aws_vpc.hydroserver_vpc.id

  tags = {
    Name             = "hydroserver-private-route-table-${var.instance}"
    "${var.tag_key}" = var.tag_value
  }
}

resource "aws_route_table_association" "hydroserver_private_route_table_association_a" {
  subnet_id      = aws_subnet.hydroserver_private_db_subnet_a.id
  route_table_id = aws_route_table.hydroserver_private_route_table.id
}

resource "aws_route_table_association" "hydroserver_private_route_table_association_b" {
  subnet_id      = aws_subnet.hydroserver_private_db_subnet_b.id
  route_table_id = aws_route_table.hydroserver_private_route_table.id
}

# -------------------------------------------------- #
# Availability Zones Data Fetch                     #
# -------------------------------------------------- #

data "aws_availability_zones" "available" {
  state = "available"
}
