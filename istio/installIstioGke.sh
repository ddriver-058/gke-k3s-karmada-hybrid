# Switch to gke context
export KUBECONFIG="$HOME/.kube/config"
kubectl config use-context $GKE

# Join GKE to karmada control plane
karmadactl join gke --kubeconfig=~/.kube/karmada.config --cluster-kubeconfig=~/.kube/config --cluster-context=$GKE


# Apply istio operator
cat <<EOF | istioctl install -y -f -
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  meshConfig:
    accessLogFile: /dev/stdout
  values:
    global:
      meshID: mesh1
      multiCluster:
        clusterName: member1
      network: network1
EOF

# Add east-west gateway
samples/multicluster/gen-eastwest-gateway.sh --mesh mesh1 --cluster gke --network gke-network | istioctl install -y -f -

# Expose control plane and service
kubectl apply -f samples/multicluster/expose-istiod.yaml -n istio-system
kubectl apply -f samples/multicluster/expose-services.yaml -n istio-system

