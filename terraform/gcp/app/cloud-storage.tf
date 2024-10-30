# -------------------------------------------------- #
# HydroServer API Storage Bucket                     #
# -------------------------------------------------- #

resource "google_storage_bucket" "hydroserver_storage_bucket" {
  name          = "hydroserver-storage-${var.instance}-${var.project_id}"
  location      = var.region
  project       = var.project_id
  force_destroy = false
  uniform_bucket_level_access = true
  iam_configuration {
    uniform_bucket_level_access {
      enabled = true
    }
  }
  public_access_prevention = "enforced"
}
