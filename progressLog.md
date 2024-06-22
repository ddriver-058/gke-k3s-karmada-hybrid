- 6/21/2024
	- I worked over the past week or so on the last steps of development and on migration. Using an HTTPRoute with injected ingress-nginx worked, but the built-in circuit-breaking of linkerd didn't prevent frequent failed requests when I had only 1 backend replica. I'm not sure if proxy-level retries would have fixed it, but ingress-nginx can't implement them with service-upstream=true anyway. Also, retries can't be combined with traffic splitting with linkerd alone.
	- So, instead of HTTPRoutes, I switched to using TrafficSplit powered by linkerd-smi with automatic weight adjustment via linkerd-failover. This works well to ensure traffic is sent to the available backend on all requests, meaning it will be perfect for failover (where only 1 healthy instance is assumed to be running across 2 clusters).
	- This was the final development step. I formed the migrationPlan.txt and followed it to migrate my home network's HA k3s cluster to karmada management using a cloud-based ArgoCD (so it can access Karmada's API server). I used the knowledge from migrating my existing apps to prepare helm/example, which shows the necessary changes, including service mirroring, propagationpolicy, and ingress annotations required to migrate an application. The archtecture pictured in gke-k3s-karmada-hybrid.drawio.png now powers https://scaeangate.io!
- 6/9/2024
     - With linkerd and karmada configured, I propagated an nginx deployment to my 2 clusters, along with a service labeled for mirroring. This led to services for each instance appearing in the GKE cluster, so I defined a linkerd HTTPRoute to split traffic between them. To test this, I'll need some kind of injected access method, so I figure this would be a good time to test out using ingress-nginx to reach the HTTPRoute. Next time I work on this project, I plan to install an injected ingress-nginx and change the index.html of one of the propagated nginx instances to confirm the traffic split.
	 - I also want to document why I've needed to reinstall linkerd each time I work on this project: The trust anchor certificates expire when the clusters are suspended. Deleting the linkerd and linkerd-multicluster namespaces and reinstalling fixes the issue.
 - 6/5/2024
     - To more securely expose my desktop k8s's API server, I just need to filter traffic on one node, so UFW is fine (no  need for a tool like OPNsense). I can allow traffic to the linkerd/k3s ports from the public IP of my cloud router, but disable access otherwise. This, combined with the usual client cert requirement, makes me comfortable enough to move forward.
	 - Because I'll be connecting to the local cluster directly with Karmada's Push mode, I won't need to rely on a linkerd service, so I removed the injected proxies as they seemed to give Karmada issues.
	 - I was once again able to configure a linkerd-multicluster link from desktop to cloud, as well as register both clusters with Karmada. Now, though, I can avoid the pitfall of having a widely-exposed API server.
	 - I explored a few different ideas for avoiding the need to widely expose the desktop API server, which taught me some important lessons about linkerd-multicluster's requirements around exposing the API server, the best tools to restrict traffic to the API server, and the practicality of port forwarding as an alternative to other network meshing approaches (e.g., submariner, VPNs). It was a significant side-track, but I learned a lot.
 - 5/30/2024
     - After a bit of a break, I did some research today to investigate how I can safely expose my desktop cluster's API server, since this will be necessary (linkerd-multicluster requires the destination cluster for mirrored services to have an exposed API server). My goal is to combine the k3s client cert requirement with IP whitelisting. While nginx and HAProxy support IP whitelisting, it doesn't apply to the k8s API server, which is a tcp service, not a web service. Instead, I'm going to focus on the possibility of using a firewall like OPNsense to restrict traffic to it, because I assume it can define rules for tcp connections, like ufw can. With access to the API server behind a source IP whitelist and a client cert requirement, I'll feel OK about moving forward to focus on using linkerd mirrored services with traffic splitting to access karmada-managed deployments.
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