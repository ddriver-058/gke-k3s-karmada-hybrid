# gke-k3s-karmada-hybrid
Ensure uptime through automatic failover for my local k3s cluster to GKE via Karmada.

 ## Progress
 This project is a work-in-progress. 
 
 - 4/16/2024
     - The submariner workaround requires an OS image for GKE nodes that is no longer supported. Hence submariner is a no-go.
	 - Multicluster networking can still be achieved in a non-flat network, as described [here](https://karmada.io/docs/userguide/service/working-with-istio-on-non-flat-network). I added an istio folder containing the setup scripts.
	 - The current challenge is that the karmada cluster controller manager can't access the GKE API server /healthz. I thought the issue could be needing the VPC added as a master authorized network, but that didn't seem to help. I tried adding pod and svc CIDR as well. I will need to dig into more reasons why the /healthz would return an i/o timeout from the karmada control plane.
 - 4/12/2024 
	 - Current challenge is configuring Submariner. We need to because Karmada exposes its API server on a cluster-internal address when installed via Helm (it seemed to use a node IP when installed via karmadactl, which is unworkable without a VPN),
	 - GKE requires a workaround to work with submariner. See [here](https://submariner.io/getting-started/quickstart/managed-kubernetes/gke/)
	 - Since I'm using spot nodes, the most sustainable path is to implement the workaround script as a daemonset. 
	 - I'll also need to adjust my GKE Terraform manifests to configure firewall rules, etc. to match the requirements.
