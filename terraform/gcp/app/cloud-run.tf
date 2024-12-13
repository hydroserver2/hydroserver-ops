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
            secret = "hydroserver-database-url-${var.instance}"
            version  = "latest"
          }
        }
      }

      env {
        name  = "SECRET_KEY"
        value_source {
          secret_key_ref {
            secret  = "hydroserver-api-secret-key-${var.instance}"
            version = "latest"
          }
        }
      }
      env {
        name  = "DEPLOYED"
        value = "True"
      }
      env {
        name  = "DEPLOYMENT_BACKEND"
        value = "gcp"
      }
      env {
        name  = "STORAGE_BUCKET"
        value = google_storage_bucket.hydroserver_storage_bucket.name
      }
      env {
        name  = "SMTP_URL"
        value = ""
      }
      env {
        name  = "ACCOUNTS_EMAIL"
        value = ""
      }
      env {
        name  = "PROXY_BASE_URL"
        value = ""
      }
      env {
        name  = "ALLOWED_HOSTS"
        value = ""
      }
      env {
        name  = "OAUTH_GOOGLE"
        value = ""
      }
      env {
        name  = "OAUTH_ORCID"
        value = ""
      }
      env {
        name  = "OAUTH_HYDROSHARE"
        value = ""
      }
      env {
        name  = "DEBUG"
        value = ""
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
}

resource "google_cloud_run_service_iam_member" "public_access" {
  location = var.region
  project  = data.google_project.gcp_project.project_id
  service  = google_cloud_run_v2_service.hydroserver_api.name

  role   = "roles/run.invoker"
  member = "allAuthenticatedUsers"
}

# -------------------------------------------------- #
# HydroServer GCP Cloud Run Environment Secrets      #
# -------------------------------------------------- #

resource "google_secret_manager_secret" "hydroserver_smtp_url" {
  secret_id = "hydroserver-smtp-url-${var.instance}"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret" "hydroserver_oauth_google" {
  secret_id = "hydroserver-oauth-google-${var.instance}"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret" "hydroserver_oauth_hydroshare" {
  secret_id = "hydroserver-oauth-hydroshare-${var.instance}"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret" "hydroserver_oauth_orcid" {
  secret_id = "hydroserver-oauth-orcid-${var.instance}"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
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

resource "google_secret_manager_secret_iam_member" "secret_access" {
  for_each = toset([
    "hydroserver-database-url-${var.instance}",
    "hydroserver-api-secret-key-${var.instance}",
  ])
  project   = data.google_project.gcp_project.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloud_run_service_account.email}"
}

resource "google_project_iam_member" "cloud_run_invoker" {
  project = data.google_project.gcp_project.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.cloud_run_service_account.email}"
}

resource "google_storage_bucket_iam_member" "cloud_run_storage_bucket_access" {
  bucket = google_storage_bucket.hydroserver_storage_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.cloud_run_service_account.email}"
}

# -------------------------------------------------- #
# HydroServer GCP Cloud Run Service NEG              #
# -------------------------------------------------- #

resource "google_compute_region_network_endpoint_group" "hydroserver_neg" {
  name                  = "hydroserver-api-neg-${var.instance}"
  region                = var.region
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = google_cloud_run_v2_service.hydroserver_api.name
  }
}
