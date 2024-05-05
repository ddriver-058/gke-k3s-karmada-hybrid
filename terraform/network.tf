resource "google_compute_network" "default" {
  name = var.network
  auto_create_subnetworks = "false"
  project = var.project_id

  # Specify routing mode, i.e., availability of GKE router
  # GLOBAL reduces network hops in multregion scenarios.
  # Our cluster is zonal, so set to regional.
  routing_mode = "REGIONAL" 
}

resource "google_compute_subnetwork" "default" {
  name          = var.subnetwork
  ip_cidr_range = var.network_cidr # For general network resources
  region        = var.region
  network       = google_compute_network.default.name
  secondary_ip_range = [
    {
        range_name    = var.ip_range_pods
        ip_cidr_range = var.ip_range_pods_cidr # Unaffiliated IP range for pods
    },
    {
        range_name    = var.ip_range_services
        ip_cidr_range = var.ip_range_services_cidr # unaffiliated IP range for svc
    }
  ]
}

