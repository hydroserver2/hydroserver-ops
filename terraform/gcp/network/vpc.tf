# -------------------------------------------------- #
# Google Cloud HydroServer VPC                       #
# -------------------------------------------------- #

resource "google_compute_network" "vpc_network" {
  name                    = "hydroserver-${var.instance}"
  auto_create_subnetworks = true
}

resource "google_vpc_access_connector" "vpc_access_connector" {
  name          = "hydroserver-${var.instance}"
  region        = var.region
  network       = google_compute_network.vpc_network.name
  ip_cidr_range = "10.8.0.0/28"
}
