# Switch to remote desktop cluster
kubectl config use-context $DEKSTOP

# Create cluster secret for desktop cluster
istioctl create-remote-secret --name=desktop > istio-remote-secret-member2.yaml

# Switch to GKE
kubectl config use-context $GKE
kubectl apply -f istio-remote-secret-member2.yaml

# Get east-west gateway address
export DISCOVERY_ADDRESS=$(kubectl -n istio-system get svc istio-eastwestgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Create remote config on desktop
kubectl config use-context $DEKSTOP
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
EOF

# Install east-west gateway in desktop
samples/multicluster/gen-eastwest-gateway.sh --mesh mesh1 --cluster desktop --network network-desktop | istioctl install -y -f -