# -------------------------------------------------- #
# Google Cloud HydroServer VPC                       #
# -------------------------------------------------- #

resource "google_compute_network" "vpc_network" {
  name                    = "hydroserver-${var.instance}"
  auto_create_subnetworks = true
}

resource "google_compute_global_address" "private_service_ip" {
  name          = "hydroserver-${var.instance}-vpc-ip-range"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network = google_compute_network.vpc_network.id
}

resource "google_service_networking_connection" "private_service_connection" {
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_service_ip.name]
}

resource "google_vpc_access_connector" "vpc_access_connector" {
  name          = "hydroserver-${var.instance}"
  region        = var.region
  network       = google_compute_network.vpc_network.name
  ip_cidr_range = "10.8.0.0/28"
}
