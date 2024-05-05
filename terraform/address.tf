# Global compute addresses are used for HTTP(S) load balancing
# We will assign one here to be used by our cluster's nginx
resource "google_compute_global_address" "default" {
  name = var.lb_ip_name
}
