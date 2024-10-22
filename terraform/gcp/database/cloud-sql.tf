resource "google_sql_database_instance" "default" {
  name             = "hydroserver-${var.instance}"
  database_version = "POSTGRES_15"
  region           = var.region
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled      = false
      private_network   = var.vpc_name
      require_ssl       = true
    }
    database_flags {
      name  = "max_connections"
      value = "100"
    }
  }
}
