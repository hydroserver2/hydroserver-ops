# resource "google_sql_database_instance" "hydroserver_db_instance" {
#   name             = "hydroserver-${var.instance}"
#   database_version = "POSTGRES_15"
#   region           = var.region
#   settings {
#     tier = "db-f1-micro"
#     ip_configuration {
#       ipv4_enabled    = false
#       private_network = var.vpc_name
#       require_ssl     = true
#     }
#     database_flags {
#       name  = "max_connections"
#       value = "100"
#     }
#     user_labels = {
#       (var.label_key) = local.label_value
#     }
#   }
# }

# resource "google_sql_database" "hydroserver_db" {
#   name     = "hydroserver"
#   instance = google_sql_database_instance.hydroserver_db_instance.name
# }

resource "random_password" "hydroserver_db_user_password" {
  length  = 16
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "google_secret_manager_secret" "hydroserver_secret_key" {
  secret_id = "hydroserver-secret-key-${var.instance}"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "hydroserver_secret_key_secret_version" {
  secret      = google_secret_manager_secret.hydroserver_secret_key.id
  secret_data = random_password.hydroserver_db_user_password.result
}

# resource "google_sql_user" "hydroserver_db_user" {
#   name     = "hsdbadmin"
#   instance = google_sql_database_instance.hydroserver_db_instance.name
#   password = random_password.hydroserver_db_user_password.result
# }

# locals {
#   hydroserver_db_connection_url = "postgresql://${google_sql_user.hydroserver_db_user.name}:${google_sql_user.hydroserver_db_user.password}@${google_sql_database_instance.hydroserver_db_instance.ip_address[0].ip_address}/${google_sql_database.hydroserver_db.name}"
# }

# resource "google_storage_bucket_object" "hydroserver_db_connection_file" {
#   name   = "credentials/${var.instance}/postgresql-connection.txt"
#   bucket = var.state_bucket
#   content = <<EOT
# # Database connection details for HydroServer instance: ${var.instance}
# Database Name: ${google_sql_database.hydroserver_db.name}
# Username: ${google_sql_user.hydroserver_db_user.name}
# Password: ${google_sql_user.hydroserver_db_user.password}
# Host: ${google_sql_database_instance.hydroserver_db_instance.ip_address[0].ip_address}
# Port: 5432
# Connection URL: ${local.hydroserver_db_connection_url}
# EOT
# }

# output "hydroserver_db_connection_url" {
#   value     = local.hydroserver_db_connection_url
#   sensitive = true
# }
