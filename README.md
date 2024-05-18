# gke-k3s-karmada-hybrid
Ensure uptime through automatic failover for my local k3s cluster to GKE via Karmada.

 ## Progress
 This project is a work-in-progress. 
 
 - 4/18/2024
     - After configuring istio, I was still interested in solutions that avoid the need to expose the local k3s cluster's API server. I decided to configure linkerd due to its hierarchical mode for multicluster networking, which involves one-way copying of services between clusters. This could work well for my case, since I plan to have traffic flow in to the cloud cluster, so I just need local services copied to the cloud cluster.
	 - I configured service mirroring with linkerd and successfully completed a cross-cluster, cloud-to-local request to a helloworld deployment! See configureLinkerd.sh for the test case.
	 - For the previous /healthz issue, it can be worked around by registering the GKE cluster in karmada's Pull mode.
	 - I tried exposing the k3s API server directly, and was able to register it to the karmada control plane in Push mode. I succesfully used Karmada to propagate the Istio secrets to my clusters! 
	     - It seems like it should be possible to inject the linkerd sidecar into the correct karmada components to enable it to access the k3s API server via a mirrored service, eliminating the need to expose the API server, which would be a security boost.
	 - I'm planning to continue with linkerd because it's a cost-effective solution that meets the requirements for this project. Ideally, with linkerd, the GKE cluster will only need one CLB.
	 - The other remaining challenge is to dynamically route to either the cloud service or the mirrored desktop service based on availability.
 - 4/16/2024
     - The submariner workaround requires an OS image for GKE nodes that is no longer supported. Hence submariner is a no-go.
	 - Multicluster networking can still be achieved in a non-flat network, as described [here](https://karmada.io/docs/userguide/service/working-with-istio-on-non-flat-network). I added an istio folder containing the setup scripts.
	 - The current challenge is that the karmada cluster controller manager can't access the GKE API server /healthz. I thought the issue could be needing the VPC added as a master authorized network, but that didn't seem to help. I tried adding pod and svc CIDR as well. I will need to dig into more reasons why the /healthz would return an i/o timeout from the karmada control plane.
 - 4/12/2024 
	 - Current challenge is configuring Submariner. We need to because Karmada exposes its API server on a cluster-internal address when installed via Helm (it seemed to use a node IP when installed via karmadactl, which is unworkable without a VPN),
	 - GKE requires a workaround to work with submariner. See [here](https://submariner.io/getting-started/quickstart/managed-kubernetes/gke/)
	 - Since I'm using spot nodes, the most sustainable path is to implement the workaround script as a daemonset. 
	 - I'll also need to adjust my GKE Terraform manifests to configure firewall rules, etc. to match the requirements.
