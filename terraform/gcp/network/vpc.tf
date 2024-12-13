# -------------------------------------------------- #
# Google Cloud HydroServer VPC                       #
# -------------------------------------------------- #

resource "google_compute_network" "hydroserver_vpc_network" {
  name                    = "hydroserver-${var.instance}"
  auto_create_subnetworks = true
}

resource "google_vpc_access_connector" "hydroserver_vpc_connector" {
  name          = "hs-vpc-conn-${var.instance}"
  region        = var.region
  network       = google_compute_network.hydroserver_vpc_network.self_link
  ip_cidr_range = "10.8.0.0/28"
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
