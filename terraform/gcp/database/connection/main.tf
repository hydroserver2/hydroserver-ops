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
variable "region" {
  description = "The GCP region this HydroServer instance will be deployed in."
  type        = string
}
variable "database_url" {
  description = "A database connection URL HydroServer's API will connect to."
  type        = string
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

data "google_client_config" "current" {}

resource "google_secret_manager_secret" "hydroserver_db_connection" {
  secret_id = "hydroserver-db-connection-${var.instance}"
  labels = {
    "${var.label_key}" = local.label_value
  }
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "hydroserver_db_connection_version" {
  secret      = google_secret_manager_secret.hydroserver_db_connection.id
  secret_data = var.database_url
}
