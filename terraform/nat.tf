# Use NAT to enable access to the public internet (for image pulls)
# This solution scales less directly with # of VMs, and focuses
# more on total data transfer, which is easier to control

resource "google_compute_router" "default" {
  name    = var.router
  project = google_compute_subnetwork.default.project
  region  = google_compute_subnetwork.default.region
  network = google_compute_network.default.id
}

resource "google_compute_router_nat" "default" {
  name                               = var.router_nat
  router                             = google_compute_router.default.name
  region                             = google_compute_router.default.region
  project                            = google_compute_router.default.project
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}