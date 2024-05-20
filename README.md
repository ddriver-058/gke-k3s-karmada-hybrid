# gke-k3s-karmada-hybrid
Ensure uptime through automatic failover for my local k3s cluster to GKE via Karmada.

 ## Progress
 This project is a work-in-progress. 
 
 - 5/20/2024
     - I tested accessing my desktop cluster's API server from a linkerd mirrored service, which seemed to work OK. However, adding sidecar proxy injectors to the karmada pods didn't seem to allow karmadactl join to add the desktop server by the mirrored service, as it returned an error connecting to server: EOF error. I'm not certain where the issue is, but both the CLI (via telepresence) and the karmada pods could access the mirrored service, so the issue may be with the handoff of API server requests through the linkerd gateway.
	 - One obvious workaround would be to attempt to join the desktop cluster to the karmada api server in Pull mode. I'm not exactly sure how the mechanics of pull mode differ, but at the very least, it would involve mirroring the karmada api server service from GKE to desktop. Given that the GKE cluster can be joined via Pull mode by reaching the service, it could be that joining the desktop via a mirrored service "just works" the same way.
 - 5/18/2024
     - After configuring istio, I was still interested in solutions that avoid the need to expose the local k3s cluster's API server. I decided to configure linkerd due to its hierarchical mode for multicluster networking, which involves one-way copying of services between clusters. This could work well for my case, since I plan to have traffic flow in to the cloud cluster, so I just need local services copied to the cloud cluster.
	 - I configured service mirroring with linkerd and successfully completed a cross-cluster, cloud-to-local request to a helloworld deployment! See configureLinkerd.sh for the test case.
	 - For the previous /healthz issue, it can be worked around by registering the GKE cluster in karmada's Pull mode.
	 - I tried exposing the k3s API server directly, and was able to register it to the karmada control plane in Push mode. I succesfully used Karmada to propagate the Istio secrets to my clusters! 
	     - It seems like it should be possible to inject the linkerd sidecar into the correct karmada components to enable it to access the k3s API server via a mirrored service, eliminating the need to expose the API server, which would be a security boost.
	 - I'm planning to continue with linkerd because it's a cost-effective solution that meets the requirements for this project. Ideally, with linkerd, the GKE cluster will only need one CLB.
	 - The other remaining challenge is to dynamically route to either the cloud service or the mirrored desktop service based on availability.
 - 5/16/2024
     - The submariner workaround requires an OS image for GKE nodes that is no longer supported. Hence submariner is a no-go.
	 - Multicluster networking can still be achieved in a non-flat network, as described [here](https://karmada.io/docs/userguide/service/working-with-istio-on-non-flat-network). I added an istio folder containing the setup scripts.
	 - The current challenge is that the karmada cluster controller manager can't access the GKE API server /healthz. I thought the issue could be needing the VPC added as a master authorized network, but that didn't seem to help. I tried adding pod and svc CIDR as well. I will need to dig into more reasons why the /healthz would return an i/o timeout from the karmada control plane.
 - 5/12/2024 
	 - Current challenge is configuring Submariner. We need to because Karmada exposes its API server on a cluster-internal address when installed via Helm (it seemed to use a node IP when installed via karmadactl, which is unworkable without a VPN),
	 - GKE requires a workaround to work with submariner. See [here](https://submariner.io/getting-started/quickstart/managed-kubernetes/gke/)
	 - Since I'm using spot nodes, the most sustainable path is to implement the workaround script as a daemonset. 
	 - I'll also need to adjust my GKE Terraform manifests to configure firewall rules, etc. to match the requirements.
