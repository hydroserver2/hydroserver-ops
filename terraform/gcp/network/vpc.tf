# -------------------------------------------------- #
# Google Cloud HydroServer VPC                       #
# -------------------------------------------------- #

resource "google_compute_network" "hydroserver_vpc_network" {
  name                    = "hydroserver-${var.instance}"
  auto_create_subnetworks = false
}

resource "google_compute_global_address" "hydroserver_private_service_ip_range" {
  name          = "hydroserver-private-service-range-${var.instance}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.hydroserver_vpc_network.id
}

resource "google_service_networking_connection" "hydroserver_private_service_connection" {
  network = google_compute_network.hydroserver_vpc_network.id
  service = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [
    google_compute_global_address.hydroserver_private_service_ip_range.name
  ]
}

# -------------------------------------------------- #
# Private Subnets for Database                       #
# -------------------------------------------------- #

resource "google_compute_subnetwork" "hydroserver_private_db_subnet_a" {
  name          = "hydroserver-private-db-${var.instance}-a"
  ip_cidr_range = "10.8.0.0/24"
  region        = var.region
  network       = google_compute_network.hydroserver_vpc_network.id
  private_ip_google_access = true
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# -------------------------------------------------- #
# Private Subnets for Applications                   #
# -------------------------------------------------- #

resource "google_compute_subnetwork" "hydroserver_private_app_subnet_a" {
  name          = "hydroserver-private-app-${var.instance}-a"
  ip_cidr_range = "10.8.2.0/24"
  region        = var.region
  network       = google_compute_network.hydroserver_vpc_network.id
  private_ip_google_access = true
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# -------------------------------------------------- #
# Cloud Router for VPC Internet Access               #
# -------------------------------------------------- #

resource "google_compute_router" "hydroserver_vpc_router" {
  name    = "hydroserver-vpc-router-${var.instance}"
  region  = var.region
  network = google_compute_network.hydroserver_vpc_network.id
}

resource "google_compute_router_nat" "hydroserver_vpc_router_nat" {
  name                       = "hydroserver-vpc-router-nat-${var.instance}"
  router                     = google_compute_router.hydroserver_vpc_router.name
  region                     = var.region
  nat_ip_allocate_option     = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_firewall" "hydroserver_vpc_allow_egress_internet" {
  name    = "hydroserver-vpc-allow-egress-internet-${var.instance}"
  network = google_compute_network.hydroserver_vpc_network.id

  allow {
    protocol = "all"
  }

  direction = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]
}
