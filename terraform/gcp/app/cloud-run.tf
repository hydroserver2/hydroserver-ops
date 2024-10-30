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
    }

    env {
      name  = "SMTP_URL"
      value_source {
        secret_key_ref {
          secret  = google_secret_manager_secret.hydroserver_smtp_url.id
          version = "latest"
        }
      }
    }

    env {
      name  = "OAUTH_GOOGLE"
      value_source {
        secret_key_ref {
          secret  = google_secret_manager_secret.hydroserver_oauth_google.id
          version = "latest"
        }
      }
    }

    env {
      name  = "OAUTH_ORCID"
      value_source {
        secret_key_ref {
          secret  = google_secret_manager_secret.hydroserver_oauth_orcid.id
          version = "latest"
        }
      }
    }


    env {
      name  = "OAUTH_HYDROSHARE"
      value_source {
        secret_key_ref {
          secret  = google_secret_manager_secret.hydroserver_oauth_hydroshare.id
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
      value = ""
    }

    env {
      name  = "ACCOUNTS_EMAIL"
      value = var.accounts_email
    }

    env {
      name  = "PROXY_BASE_URL"
      value = var.proxy_base_url
    }

    env {
      name  = "ALLOWED_HOSTS"
      value = var.allowed_hosts
    }

    env {
      name  = "DEBUG"
      value = var.debug
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

resource "google_secret_manager_secret_version" "hydroserver_smtp_url_version" {
  secret      = google_secret_manager_secret.hydroserver_smtp_url.id
  secret_data = var.smtp_url
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

resource "google_secret_manager_secret_version" "hydroserver_oauth_google_version" {
  secret      = google_secret_manager_secret.hydroserver_oauth_google.id
  secret_data = var.oauth_google
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

resource "google_secret_manager_secret_version" "hydroserver_oauth_hydroshare_version" {
  secret      = google_secret_manager_secret.hydroserver_oauth_hydroshare.id
  secret_data = var.oauth_hydroshare
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

resource "google_secret_manager_secret_version" "hydroserver_oauth_orcid_version" {
  secret      = google_secret_manager_secret.hydroserver_oauth_orcid.id
  secret_data = var.oauth_orcid
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
    "hydroserver-db-connection-${var.instance}",
    "hydroserver-api-secret-key-${var.instance}"
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
