terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  backend "s3" {}
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}

variable "instance" {
  description = "The name of this HydroServer instance."
  type        = string
}
variable "region" {
  description = "The AWS region this HydroServer instance will be deployed in."
  type        = string
}
variable "hydroserver_version" {
  description = "The version of HydroServer to deploy."
  type        = string
  default     = "latest"
}
variable "database_url" {
  description = "A database connection for HydroServer to use."
  type        = string
  sensitive   = true
  default     = ""
}
variable "default_superuser_email" {
  type        = string
  sensitive   = true
  default     = "admin@hydroserver.org"
}
variable "default_superuser_password" {
  type        = string
  sensitive   = true
  default     = "pass"
}
variable "tag_key" {
  description = "The key of the AWS tag that will be attached to this HydroServer instance."
  type        = string
  default     = "HydroServerInstance"
}
variable "tag_value" {
  description = "The value of the AWS tag that will be attached to this HydroServer instance."
  type        = string
  default     = ""
}

locals {
  tag_value = var.tag_value != "" ? var.tag_value : var.instance
}

data "aws_caller_identity" "current" {}
