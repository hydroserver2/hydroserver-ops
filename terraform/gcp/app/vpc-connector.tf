resource "google_vpc_access_connector" "hydroserver_vpc_connector" {
  name    = "hs-${var.instance}"
  region  = var.region
  network = var.vpc_name
}
