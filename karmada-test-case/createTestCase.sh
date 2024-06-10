# Create an nginx deployment and service and propagate to member clusters
# The service is labeled for linkerd export
export KUBECONFIG=~/.kube/karmada.config
kubectl create deployment --image nginx nginx
kubectl apply -f propagationPolicy.yaml

# Now we have 2 nginx deployments. GKE has an nginx and nginx-desktop service.
# So, create a traffic splitting service between them.
export KUBECONFIG=~/.kube/config # We could also propagate the HTTPRoute, but I'm just applying directly for speed
kubectl apply -f httproute.yaml

# Let's ensure that the traffic is routed 50/50 by changing /usr/share/nginx/html/index.html in the desktop nginx.
# Use kubectl exec.


