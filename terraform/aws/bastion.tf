# ---------------------------------
# AWS SSM Bastion Host
# ---------------------------------

resource "aws_instance" "bastion" {
  count = var.database_url == "" ? 1 : 0

  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private_subnet_az1.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.bastion_profile.name
  associate_public_ip_address = false

  tags = {
    "${var.tag_key}" = local.tag_value
  }
}

data "aws_ami" "amazon_linux" {
  count = var.database_url == "" ? 1 : 0

  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


# ---------------------------------
# AWS SSM Bastion Security Group
# ---------------------------------

resource "aws_security_group" "bastion_sg" {
  count = var.database_url == "" ? 1 : 0

  name        = "bastion-sg"
  description = "Security group for HydroServer SSM bastion"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# ---------------------------------
# AWS SSM Bastion IAM
# ---------------------------------

resource "aws_iam_role" "bastion_role" {
  count = var.database_url == "" ? 1 : 0

  name = "bastion-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  count = var.database_url == "" ? 1 : 0

  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion_profile" {
  count = var.database_url == "" ? 1 : 0

  name = "bastion-ssm-profile"
  role = aws_iam_role.bastion_role.name
}
