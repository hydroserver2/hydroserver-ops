# -------------------------------------------------- #
# Global Static IP Address                           #
# -------------------------------------------------- #

resource "google_compute_global_address" "cdn_ip_address" {
  name = "hydroserver-${var.instance}-cdn-ip"
}

# -------------------------------------------------- #
# Cloud CDN Backend Service                          #
# -------------------------------------------------- #

resource "google_compute_backend_service" "cloud_cdn_backend" {
  name                  = "hydroserver-${var.instance}-cdn-backend"
  load_balancing_scheme = "EXTERNAL"
  protocol              = "HTTP"
  port_name             = "http"

  cdn_policy {
    cache_mode = "USE_ORIGIN_HEADERS"
    cache_key_policy {
      include_host          = true
      include_protocol      = true
    }
  }
}

# -------------------------------------------------- #
# URL Map                                            #
# -------------------------------------------------- #

resource "google_compute_url_map" "cdn_url_map" {
  name            = "hydroserver-${var.instance}-cdn-url-map"
  default_service = google_compute_backend_service.cloud_cdn_backend.id
}

# -------------------------------------------------- #
# HTTP(S) Proxy                                      #
# -------------------------------------------------- #

resource "google_compute_target_http_proxy" "cdn_http_proxy" {
  name    = "hydroserver-${var.instance}-cdn-http-proxy"
  url_map = google_compute_url_map.cdn_url_map.id
}

# -------------------------------------------------- #
# Global Forwarding Rule                             #
# -------------------------------------------------- #

resource "google_compute_global_forwarding_rule" "cdn_forwarding_rule" {
  name       = "hydroserver-${var.instance}-cdn-forwarding"
  ip_address = google_compute_global_address.cdn_ip_address.id
  target     = google_compute_target_http_proxy.cdn_http_proxy.id
  port_range = "80"
}
