# https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/latest/submodules/private-cluster

# google_client_config and kubernetes provider must be explicitly specified like the following.
data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  project_id                 = var.project_id
  name                       = var.cluster_name
  regional                   = false
  region                     = var.region
  zones                      = var.zones
  network                    = google_compute_network.default.name
  subnetwork                 = google_compute_subnetwork.default.name
  ip_range_pods              = var.ip_range_pods # This limits total pods, so set with scalability in mind
  ip_range_services          = var.ip_range_services # Same here for services
  http_load_balancing        = false # Bundles a LB
  network_policy             = false # Enforces network policy (higher system requirements)
  horizontal_pod_autoscaling = true # standard HPA functionality
  enable_vertical_pod_autoscaling = true # automatic pod right-sizing
  filestore_csi_driver       = false # PD CSI driver is fine
  enable_private_endpoint    = false
  enable_private_nodes       = true # Saves on public IPs for nodes -- use NAT router instead
  master_authorized_networks = var.master_authorized_networks # Which networks can access API server
  master_ipv4_cidr_block     = var.master_ipv4_cidr_block
  enable_resource_consumption_export = false
  deletion_protection = false
  remove_default_node_pool = true # Stops creation of "default pool"

  node_pools = var.node_pools

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/servicecontrol",
    ]
  }

  node_pools_labels = {
    all = {}

    default-node-pool = {
      default-node-pool = true
    }
  }

  node_pools_metadata = {
    all = {}

    default-node-pool = {
    #   node-pool-metadata-custom-value = "my-node-pool"
    }
  }

  node_pools_taints = {
    all = []

    default-node-pool = [
    #   {
    #     key    = "default-node-pool"
    #     value  = true
    #     effect = "PREFER_NO_SCHEDULE"
    #   },
    ]
  }

  node_pools_tags = {
    all = []

    default-node-pool = [
      "default-node-pool",
    ]
  }
}