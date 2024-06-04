// Default AWS Access Credentials
variable "access_key" {}
variable "secret_key" {}
variable "instance" {}
variable "region" {}
variable "db_user" {}
variable "db_password" {}
variable "aws_ami" {
  default = "ami-00beae93a2d981137"
}
variable "private_key" {}
variable "public_key" {}
variable "aws_type" {
  default = "t2.micro"
}


