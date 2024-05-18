# Install karmada CLI
# https://karmada.io/docs/next/installation/install-cli-tools
curl -s https://raw.githubusercontent.com/karmada-io/karmada/master/hack/install-cli.sh | sudo bash

# Deploy control plane
# This is done via Helm, which results in the karmada API server being accessed from a cluster-internal hostname

# Join GKE member cluster
# https://karmada.io/docs/userguide/clustermanager/cluster-registration/
# We will use "Pull" mode because the GKE cluster can reach the Karmada API server
# by its internal address. "Push" mode seemed to fail, as the karmada api control plane
# cluster couldn't access the GKE public endpoint, probably due to a security issue
# (although likely not the master authorized network as I tried adjusting it already)

# Create a join token.
# First, get the karmada API server kubeconfig from the GKE cluster.
kubectl get secret -n karmada-system karmada-kubeconfig -o jsonpath={.data.kubeconfig} | base64 -d > ~/.kube/karmada.config

# Need to resolve the internal address of the generated karmada API server config.
# I chose to use telepresence.
telepresence helm install
telepresence connect

# Now we can create the token.
karmadactl token create --print-register-command --kubeconfig karmada.config

# Switch to member cluster context and execute join command.
kubectl config use-context $GKE
# cluster-name=gke is used for easier referencing + max name length
karmadactl register <CONTROL_PLANE_API> --token <TOKEN> --discovery-token-ca-cert-hash <CA_CERT_HASH> --cluster-name gke 


# Join the local desktop cluster
# The desktop can't access the karmada API server by its internal address.
# For now, I exposed the desktop cluster's API server, so we can use "Push" mode.
karmadactl join desktop --kubeconfig=$HOME/.kube/karmada.config --cluster-kubeconfig=$HOME/.kube/config

# Using istio / linkerd to expose the desktop API server to a cluster-internal service could get around this issue.