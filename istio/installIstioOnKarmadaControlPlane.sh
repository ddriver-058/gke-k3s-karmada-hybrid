# Export karmada api server kubeconfig
kubectl get secret -n karmada-system karmada-kubeconfig -o jsonpath={.data.kubeconfig} | base64 -d > ~/.kube/karmada.config

# Flatten network to GKE cluster via telepresence
telepresence helm install
telepresence connect

# Switch to API server config and populate keys to cluster
export KUBECONFIG=$HOME/.kube/karmada.config

kubectl create namespace istio-system
kubectl create secret generic cacerts -n istio-system \
    --from-file=certs/primary/ca-cert.pem \
    --from-file=certs/primary/ca-key.pem \
    --from-file=certs/primary/root-cert.pem \
    --from-file=certs/primary/cert-chain.pem

# Create propagation policy of cluster secrets
cat <<EOF | kubectl apply -f -
apiVersion: policy.karmada.io/v1alpha1
kind: PropagationPolicy
metadata:
  name: cacerts-propagation
  namespace: istio-system
spec:
  resourceSelectors:
    - apiVersion: v1
      kind: Secret
      name: cacerts
  placement:
    clusterAffinity:
      clusterNames:
        - gke
        - desktop
EOF

# Override network label on cluster 1
cat <<EOF | kubectl apply -f -
apiVersion: policy.karmada.io/v1alpha1
kind: ClusterOverridePolicy
metadata:
  name: istio-system-gke
spec:
  resourceSelectors:
    - apiVersion: v1
      kind: Namespace
      name: istio-system
  overrideRules:
    - targetCluster:
        clusterNames:
          - gke
      overriders:
        plaintext:
          - path: "/metadata/labels"
            operator: add
            value:
              topology.istio.io/network: gke-network
EOF

# Override network label on cluster 2
cat <<EOF | kubectl apply -f -
apiVersion: policy.karmada.io/v1alpha1
kind: ClusterOverridePolicy
metadata:
  name: istio-system-desktop
spec:
  resourceSelectors:
    - apiVersion: v1
      kind: Namespace
      name: istio-system
  overrideRules:
    - targetCluster:
        clusterNames:
          - desktop
      overriders:
        plaintext:
          - path: "/metadata/labels"
            operator: add
            value:
              topology.istio.io/network: desktop-network
EOF

# install istio CRDs
istioctl manifest generate --set profile=remote \
  --set values.global.configCluster=true \
  --set values.global.externalIstiod=false \
  --set values.global.defaultPodDisruptionBudget.enabled=false \
  --set values.telemetry.enabled=false | kubectl apply -f -