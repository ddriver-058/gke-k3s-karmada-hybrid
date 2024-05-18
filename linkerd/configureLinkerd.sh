# Download CLI and move to location in PATH
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install-edge | sh
sudo mv ~/.linkerd2/bin/linkerd-edge-24.5.3 /usr/local/bin/linkerd

# Install step
wget https://dl.smallstep.com/cli/docs-ca-install/latest/step-cli_amd64.deb
sudo dpkg -i step-cli_amd64.deb

# Create trust anchor and associated certificate
mkdir ~/linkerd
cd ~/linkerd
step certificate create root.linkerd.cluster.local ca.crt ca.key \
--profile root-ca --no-password --insecure

step certificate create identity.linkerd.cluster.local issuer.crt issuer.key \
--profile intermediate-ca --not-after 8760h --no-password --insecure \
--ca ca.crt --ca-key ca.key

# Install linkerd using the certificates
kubectl config use-context $GKE
linkerd install --crds | kubectl apply -f -
linkerd install \
  --identity-trust-anchors-file ca.crt \
  --identity-issuer-certificate-file issuer.crt \
  --identity-issuer-key-file issuer.key \
  | kubectl apply -f -

kubectl config use-context desktop
linkerd install --crds | kubectl apply -f -
linkerd install \
  --identity-trust-anchors-file ca.crt \
  --identity-issuer-certificate-file issuer.crt \
  --identity-issuer-key-file issuer.key \
  | kubectl apply -f -


# Install linkerd multicluster
kubectl config use-context $GKE
linkerd multicluster install | \
    kubectl apply -f -

# Install linkerd to desktop
kubectl config use-context desktop
linkerd multicluster install | \
    kubectl apply -f -

# Now link. First, we'll link the GKE to the desktop.
# This copies services from GKE to the desktop.
# Commenting this out because it seems not strictly necessary for my use case.
# linkerd --context=$GKE multicluster link --cluster-name gke |
#   kubectl --context=desktop apply -f -

# The other way around: copying desktop services to cloud.
# For using a local LB like service LB for k3s, we need to overwrite the gateway address with the WAN IP.
# We'll then need to expose the gateway by port forwarding.
linkerd --context=desktop multicluster link --cluster-name desktop --gateway-addresses 65.185.3.10 |
  kubectl --context=$GKE apply -f -

# Check via:
linkerd --context=$GKE multicluster check

# test deployment
wget -O helloworld.yaml https://2706222677-files.gitbook.io/~/files/v0/b/gitbook-legacy-files/o/assets%2F-Mg-RBIbw2wF_IDwm1S7%2F-Mg-eT5UEM5d-ScyWiDQ%2F-Mg-lXNXhi_7S9fgmLiE%2Fhelloworld.yaml?alt=media&token=2d24ef35-8890-4efa-a8e2-9b4f76995eab
kubectl apply -f helloworld.yaml
kubectl expose deployment helloworld --type=ClusterIP
kubectl label svc helloworld mirror.linkerd.io/exported=true

# Create an injected nginx container and send a request to the copied service.
kubectl config use-context $GKE
kubectl create deployment --image nginx test
kubectl get deployment test -o yaml | linkerd inject - | kubectl apply --context $GKE -f -
kubectl exec -it test-7fbd6cb5dd-md52j --container nginx -- bash # curl http://helloworld-desktop.default.svc.cluster.local