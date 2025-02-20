# ---------------------------------
# GCP Cloud Run Service
# ---------------------------------

resource "google_cloud_run_v2_service" "api" {
  name                = "hydroserver-api-${var.instance}"
  location            = var.region
  ingress             = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  deletion_protection = false

  depends_on = [
    google_secret_manager_secret_version.database_url_version,
    google_secret_manager_secret_version.smtp_url_version,
    google_secret_manager_secret_version.api_secret_key_version
  ]

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

      volume_mounts {
        name      = "cloudsql"
        mount_path = "/cloudsql"
      }

      dynamic "env" {
        for_each = {
          DATABASE_URL = google_secret_manager_secret.database_url.id
          SMTP_URL     = google_secret_manager_secret.smtp_url.id
          SECRET_KEY   = google_secret_manager_secret.api_secret_key.id
        }
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value
              version = "latest"
            }
          }
        }
      }

      dynamic "env" {
        for_each = {
          USE_CLOUD_SQL_AUTH_PROXY  = "true"
          DEPLOYED                  = "True"
          DEPLOYMENT_BACKEND        = "gcp"
          STATIC_BUCKET_NAME        = google_storage_bucket.static_bucket.name
          MEDIA_BUCKET_NAME         = google_storage_bucket.media_bucket.name
          PROXY_BASE_URL            = ""
          DEBUG                     = ""
          DEFAULT_FROM_EMAIL        = ""
          ACCOUNT_SIGNUP_ENABLED    = ""
          ACCOUNT_OWNERSHIP_ENABLED = ""
          SOCIALACCOUNT_SIGNUP_ONLY = ""
        }
        content {
          name  = env.key
          value = env.value
        }
      }
    }

    service_account = google_service_account.cloud_run_service_account.email

    # dynamic "volumes" {
    #   for_each = var.database_url != "" ? [google_sql_database_instance.db_instance[0].connection_name] : []
    #   content {
    #     name = "cloudsql"
    #     cloud_sql_instance {
    #       instances = [volumes.value]
    #     }
    #   }
    # }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.db_instance[0].connection_name]
      }
    }

    labels = {
      "${var.label_key}" = local.label_value
    }
  }
}

resource "google_compute_region_network_endpoint_group" "api_neg" {
  name                  = "hydroserver-api-${var.instance}-neg"
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = google_cloud_run_v2_service.api.name
  }
}

resource "google_secret_manager_secret" "smtp_url" {
  secret_id = "hydroserver-${var.instance}-api-smtp-url"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "smtp_url_version" {
  secret      = google_secret_manager_secret.smtp_url.id
  secret_data = "smtp://127.0.0.1:1025"

  lifecycle {
    ignore_changes = [secret_data]
  }
}


# ---------------------------------
# GCP Cloud Run Service Account
# ---------------------------------

resource "google_service_account" "cloud_run_service_account" {
  account_id   = "hydroserver-api-${var.instance}"
  display_name = "HydroServer Cloud Run Service Account - ${var.instance}"
  project      = data.google_project.gcp_project.project_id
}

resource "google_project_iam_member" "cloud_run_sql_access" {
  project = data.google_project.gcp_project.project_id
  role   = "roles/cloudsql.client"
  member = "serviceAccount:${google_service_account.cloud_run_service_account.email}"
}

resource "google_secret_manager_secret_iam_member" "secret_access" {
  for_each = {
    "database_url"   = google_secret_manager_secret.database_url.id,
    "smtp_url"       = google_secret_manager_secret.smtp_url.id,
    "api_secret_key" = google_secret_manager_secret.api_secret_key.id
  }
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
  for_each = toset([
    google_storage_bucket.static_bucket.name,
    google_storage_bucket.media_bucket.name,
  ])
  bucket = each.value
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.cloud_run_service_account.email}"
}
