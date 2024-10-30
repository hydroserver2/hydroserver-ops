terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  backend "gcs" {}
  required_version = ">= 1.2.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
}

variable "instance" {
  description = "The name of this HydroServer instance."
  type        = string
}
variable "project_id" {
  description = "The project ID for this HydroServer instance."
  type        = string
}
variable "region" {
  description = "The GCP region this HydroServer instance will be deployed in."
  type        = string
}
variable "hydroserver_version" {
  description = "The version of HydroServer to deploy."
  type        = string
  default     = "latest"
}
variable "smtp_url" {
  description = "The SMTP connection URL HydroServer will use to send emails."
  type        = string
  default     = ""
}
variable "accounts_email" {
  description = "The email HydroServer will send emails from."
  type        = string
  default     = null
}
variable "proxy_base_url" {
  description = "The URL HydroServer will be served from."
  type        = string
  default     = null
}
variable "allowed_hosts" {
  description = "Hosts HydroServer can be served from."
  type        = string
  default     = null
}
variable "debug" {
  description = "Toggles Django's debug mode."
  type        = string
  default     = "True"
}
variable "oauth_google" {
  description = "Google OAuth Credentials."
  type        = string
  default     = ""
}
variable "oauth_orcid" {
  description = "ORCID OAuth Credentials."
  type        = string
  default     = ""
}
variable "oauth_hydroshare" {
  description = "HydroShare OAuth Credentials."
  type        = string
  default     = ""
}
variable "label_key" {
  description = "The key of the GCP label that will be attached to this HydroServer instance."
  type        = string
  default     = "hydroserver-instance"
}
variable "label_value" {
  description = "The value of the GCP label that will be attached to this HydroServer instance."
  type        = string
  default     = ""
}

locals {
  label_value = var.label_value != "" ? var.label_value : var.instance
}

data "google_project" "gcp_project" {
  project_id = var.project_id
}
data "google_client_config" "current" {}
