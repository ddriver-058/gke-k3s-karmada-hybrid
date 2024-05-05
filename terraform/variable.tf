
# CLUSTER VARS
variable "project_id" {}
variable "cluster_name" {}
variable "region" {}
variable "zones" {}
variable "master_ipv4_cidr_block" {}
variable "network" {}
variable "subnetwork" {}
variable "network_cidr" {}
variable "ip_range_pods" {}
variable "ip_range_pods_cidr" {}
variable "ip_range_services" {}
variable "ip_range_services_cidr" {}
variable "master_authorized_networks" {}

# NODE POOL VARS
variable "machine_type" {}
variable "node_locations" {}
variable "node_pool_service_account" {}

# NAT VARS
variable "router" {}
variable "router_nat" {}

# IP ADDR VARS
variable "lb_ip_name" {}