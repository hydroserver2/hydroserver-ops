# -------------------------------------------------- #
# HydroServer API Storage Bucket                     #
# -------------------------------------------------- #

resource "google_storage_bucket" "hydroserver_storage_bucket" {
  name          = "hydroserver-storage-${var.instance}-${var.project_id}"
  location      = var.region
  project       = var.project_id
  force_destroy = false
  uniform_bucket_level_access = true
  public_access_prevention = "enforced"
}

# -------------------------------------------------- #
# HydroServer Data Management App Bucket             #
# -------------------------------------------------- #

resource "google_storage_bucket" "hydroserver_data_mgmt_app_bucket" {
  name          = "hydroserver-data-mgmt-app-${var.instance}-${var.project_id}"
  location      = var.region
  project       = var.project_id
  force_destroy = true
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  website {
    main_page_suffix = "index.html"
  }
}

