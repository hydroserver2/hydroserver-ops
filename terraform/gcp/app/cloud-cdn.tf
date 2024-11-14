# -------------------------------------------------- #
# Cloud CDN Backend Service                          #
# -------------------------------------------------- #

resource "google_compute_backend_service" "cloud_run_backend" {
  name        = "hydroserver-${var.instance}-cdn-backend"
  description = "Backend service for HydroServer API"
  backend {
    group = google_compute_region_network_endpoint_group.hydroserver_neg.id
  }
  enable_cdn = true
  security_policy = google_compute_security_policy.cdn_security_policy.id
}

# -------------------------------------------------- #
# Cloud CDN Backend Bucket - Web Content             #
# -------------------------------------------------- #

resource "google_compute_backend_bucket" "data_mgmt_bucket_backend" {
  name       = "hydroserver-${var.instance}-data-mgmt-bucket"
  bucket_name = google_storage_bucket.hydroserver_data_mgmt_app_bucket.name
  enable_cdn  = true
  security_policy = google_compute_security_policy.cdn_security_policy.id
}

# -------------------------------------------------- #
# Cloud CDN Backend Bucket - Static/Media Content    #
# -------------------------------------------------- #

resource "google_compute_backend_bucket" "storage_bucket_backend" {
  name       = "hydroserver-${var.instance}-storage-bucket"
  bucket_name = google_storage_bucket.hydroserver_storage_bucket.name
  enable_cdn  = true
  security_policy = google_compute_security_policy.cdn_security_policy.id
}

# -------------------------------------------------- #
# URL Map                                            #
# -------------------------------------------------- #

resource "google_compute_url_map" "cdn_url_map" {
  name            = "hydroserver-${var.instance}-cdn-url-map"
  default_service = google_compute_backend_bucket.data_mgmt_bucket_backend.id
  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }
  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_bucket.data_mgmt_bucket_backend.self_link
    path_rule {
      paths   = ["/api/*", "/admin/*"]
      service = google_compute_backend_service.cloud_run_backend.self_link
    }
    path_rule {
      paths   = ["/static/*", "/photos/*"]
      service = google_compute_backend_bucket.storage_bucket_backend.self_link
    }
  }
}

# -------------------------------------------------- #
# HTTPS Proxy                                        #
# -------------------------------------------------- #

resource "google_compute_target_http_proxy" "cdn_http_proxy" {
  name    = "hydroserver-${var.instance}-cdn-http-proxy"
  url_map = google_compute_url_map.cdn_url_map.id
}

resource "google_compute_managed_ssl_certificate" "temporary_ssl_cert" {
  name = "temp-ssl-cert-${var.instance}"
  managed {
    domains = ["hydroserver.example.com"]
  }
}

resource "google_compute_target_https_proxy" "cdn_https_proxy" {
  name    = "hydroserver-${var.instance}-cdn-https-proxy"
  url_map = google_compute_url_map.cdn_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.temporary_ssl_cert.id]

  lifecycle {
    ignore_changes = [ssl_certificates]
  }
}

# -------------------------------------------------- #
# Global Static IP Address                           #
# -------------------------------------------------- #

resource "google_compute_global_address" "cdn_ip_address" {
  name = "hydroserver-${var.instance}-cdn-ip"
}

# -------------------------------------------------- #
# Global Forwarding Rule                             #
# -------------------------------------------------- #

resource "google_compute_global_forwarding_rule" "cdn_https_forwarding_rule" {
  name                  = "hydroserver-${var.instance}-cdn-https-forwarding"
  ip_address            = google_compute_global_address.cdn_ip_address.id
  target                = google_compute_target_https_proxy.cdn_https_proxy.id
  port_range            = "443"
  load_balancing_scheme = "EXTERNAL"
}
