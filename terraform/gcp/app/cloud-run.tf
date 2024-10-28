# -------------------------------------------------- #
# HydroServer GCP Cloud Run Service                  #
# -------------------------------------------------- #

resource "google_cloud_run_v2_service" "hydroserver_api" {
  name     = "hydroserver-api-${var.instance}"
  location = var.region

  template {
    containers {
      image = "${var.region}-docker.pkg.dev/${data.google_project.gcp_project.project_id}/${var.instance}/hydroserver-api-services:latest"

      resources {
        limits = {
          memory = "512Mi"
        }
      }

      ports {
        container_port = 8000
      }

      env {
        name  = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret = "hydroserver-db-connection-${var.instance}"
            version  = "latest"
          }
        }
      }

      env {
        name  = "SECRET_KEY"
        value_source {
          secret_key_ref {
            secret = "hydroserver-secret-key-${var.instance}"
            version  = "latest"
          }
        }
      }
    }

    service_account = google_service_account.cloud_run_service_account.email

    vpc_access{
      connector = "projects/${data.google_project.gcp_project.project_id}/locations/${var.region}/connectors/hydroserver-${var.instance}"
      egress = "ALL_TRAFFIC"
    }

    labels = {
      "${var.label_key}" = local.label_value
    }
  }

  traffic {
    latest_revision  = true
    percent = 100
  }
}

# -------------------------------------------------- #
# HydroServer GCP Cloud Run Service Account          #
# -------------------------------------------------- #

resource "google_service_account" "cloud_run_service_account" {
  account_id   = "hydroserver-api-${var.instance}"
  display_name = "HydroServer Cloud Run Service Account - ${var.instance}"
  project      = data.google_project.gcp_project.project_id
}

resource "google_project_iam_member" "secret_manager_access" {
  project = data.google_project.gcp_project.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.cloud_run_service_account.email}"
}

resource "google_project_iam_member" "cloud_run_invoker" {
  project = data.google_project.gcp_project.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.cloud_run_service_account.email}"
}

# -------------------------------------------------- #
# HydroServer GCP Cloud Run Service NEG              #
# -------------------------------------------------- #

# resource "google_compute_region_network_endpoint_group" "hydroserver_neg" {
#   name                  = "hydroserver-api-neg-${var.instance}"
#   region                = var.region
#   network_endpoint_type = "SERVERLESS"

#   cloud_run {
#     service = google_cloud_run_service.hydroserver_api.name
#   }

#   labels = {
#     var.label_key = local.label_value  
#   }
# }
