# gke-k3s-karmada-hybrid
Ensure uptime through automatic failover for my local k3s cluster to GKE via Karmada.

 ## Progress
 This project is a work-in-progress. 
 
 - 4/12/2024 
	 - Current challenge is configuring Submariner. We need to because Karmada exposes its API server on a cluster-internal address when installed via Helm (it seemed to use a node IP when installed via karmadactl, which is unworkable without a VPN),
	 - GKE requires a workaround to work with submariner. See [here](https://submariner.io/getting-started/quickstart/managed-kubernetes/gke/)
	 - Since I'm using spot nodes, the most sustainable path is to implement the workaround script as a daemonset. 
	 - I'll also need to adjust my GKE Terraform manifests to configure firewall rules, etc. to match the requirements.
