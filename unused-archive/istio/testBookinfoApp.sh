# Switch to karmada api server context
export KUBECONFIG=$HOME/.kube/karmada.config
kubectl config use-context karmada-apiserver 

# Create test deployment namespace
kubectl create namespace istio-demo
kubectl label namespace istio-demo istio-injection=enabled

# Deploy app
kubectl apply -n istio-demo -f https://raw.githubusercontent.com/istio/istio/release-1.12/samples/bookinfo/platform/kube/bookinfo.yaml

# Create destination rules
kubectl apply -n istio-demo -f https://raw.githubusercontent.com/istio/istio/release-1.12/samples/bookinfo/networking/destination-rule-all.yaml
# Create virtual service
kubectl apply -n istio-demo -f https://raw.githubusercontent.com/istio/istio/release-1.12/samples/bookinfo/networking/virtual-service-all-v1.yaml

# Apply propagation policy
cat <<EOF | kubectl apply -nistio-demo -f -
apiVersion: policy.karmada.io/v1alpha1
kind: PropagationPolicy
metadata:
  name: service-propagation
spec:
  resourceSelectors:
    - apiVersion: v1
      kind: Service
      name: productpage
    - apiVersion: v1
      kind: Service
      name: details
    - apiVersion: v1
      kind: Service
      name: reviews
    - apiVersion: v1
      kind: Service
      name: ratings
  placement:
    clusterAffinity:
      clusterNames:
        - gke
        - desktop
---
apiVersion: policy.karmada.io/v1alpha1
kind: PropagationPolicy
metadata:
  name: produtpage-propagation
spec:
  resourceSelectors:
    - apiVersion: apps/v1
      kind: Deployment
      name: productpage-v1
    - apiVersion: v1
      kind: ServiceAccount
      name: bookinfo-productpage
  placement:
    clusterAffinity:
      clusterNames:
        - gke
---
apiVersion: policy.karmada.io/v1alpha1
kind: PropagationPolicy
metadata:
  name: details-propagation
spec:
  resourceSelectors:
    - apiVersion: apps/v1
      kind: Deployment
      name: details-v1

    - apiVersion: v1
      kind: ServiceAccount
      name: bookinfo-details
  placement:
    clusterAffinity:
      clusterNames:
        - desktop
---
apiVersion: policy.karmada.io/v1alpha1
kind: PropagationPolicy
metadata:
  name: reviews-propagation
spec:
  resourceSelectors:
    - apiVersion: apps/v1
      kind: Deployment
      name: reviews-v1
    - apiVersion: apps/v1
      kind: Deployment
      name: reviews-v2
    - apiVersion: apps/v1
      kind: Deployment
      name: reviews-v3
    - apiVersion: v1
      kind: ServiceAccount
      name: bookinfo-reviews
  placement:
    clusterAffinity:
      clusterNames:
        - gke
        - desktop
---
apiVersion: policy.karmada.io/v1alpha1
kind: PropagationPolicy
metadata:
  name: ratings-propagation
spec:
  resourceSelectors:
    - apiVersion: apps/v1
      kind: Deployment
      name: ratings-v1
    - apiVersion: v1
      kind: ServiceAccount
      name: bookinfo-ratings
  placement:
    clusterAffinity:
      clusterNames:
        - desktop
EOF

# Deploy fortio
kubectl apply -nistio-demo -f https://raw.githubusercontent.com/istio/istio/release-1.12/samples/httpbin/sample-client/fortio-deploy.yaml

# Create Propagation Policy for fortio services
cat <<EOF | kubectl apply -nistio-demo -f -
apiVersion: policy.karmada.io/v1alpha1
kind: PropagationPolicy
metadata:
  name: fortio-propagation
spec:
  resourceSelectors:
    - apiVersion: v1
      kind: Service
      name: fortio
    - apiVersion: apps/v1
      kind: Deployment
      name: fortio-deploy
  placement:
    clusterAffinity:
      clusterNames:
        - gke
        - desktop
EOF

# switch to GKE
export KUBECONFIG="$HOME/.kube/config"
kubectl config use-context $GKE

# Verify productpage app install
export FORTIO_POD=`kubectl get po -nistio-demo | grep fortio | awk '{print $1}'`
kubectl exec -it ${FORTIO_POD} -nistio-demo -- fortio load -t 3s productpage:9080/productpage