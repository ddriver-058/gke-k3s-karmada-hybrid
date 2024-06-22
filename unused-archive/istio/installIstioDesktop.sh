# Switch to remote desktop cluster
kubectl config use-context desktop

# Create cluster secret for desktop cluster
istioctl create-remote-secret --name=desktop > istio-remote-secret-member2.yaml

# Switch to GKE to store 
kubectl config use-context $GKE
kubectl apply -f istio-remote-secret-member2.yaml

# Get east-west gateway address
export DISCOVERY_ADDRESS=$(kubectl -n istio-system get svc istio-eastwestgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Create remote config on desktop
kubectl config use-context desktop

# Install istio operator on desktop.
# Note that in this case, this is a k3s cluster, so follow:
# https://ranchermanager.docs.rancher.com/integrations-in-rancher/istio/configuration-options/install-istio-on-rke2-cluster
cat <<EOF | istioctl install -y -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: desktop
      network: network-desktop
      remotePilotAddress: ${DISCOVERY_ADDRESS}
  components:
    cni:
      enabled: true
      k8s:
        overlays:
        - apiVersion: "apps/v1"
          kind: "DaemonSet"
          name: "istio-cni-node"
          patches:
          - path: spec.template.spec.containers.[name:install-cni].securityContext.privileged
            value: true
  values:
    cni:
      cniBinDir: /var/lib/rancher/k3s/data/current/bin
      cniConfDir: /var/lib/rancher/k3s/agent/etc/cni/net.d
EOF

# Install east-west gateway in desktop
samples/multicluster/gen-eastwest-gateway.sh --mesh mesh1 --cluster desktop --network network-desktop | istioctl install -y -f -