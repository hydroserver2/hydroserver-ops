resource "google_vpc_access_connector" "hydroserver_vpc_connector" {
  name    = "hydroserver-vpc-connector-${var.instance}"
  region  = var.region
  network = var.vpc_name
}
