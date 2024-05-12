# Install karmada CLI
# https://karmada.io/docs/next/installation/install-cli-tools
curl -s https://raw.githubusercontent.com/karmada-io/karmada/master/hack/install-cli.sh | sudo bash

# Join our member cluster
# https://karmada.io/docs/userguide/clustermanager/cluster-registration/
# In my case, I will use PULL mode because my member cluster doesn't expose its API
# server to the outside world. This means I use karmadactl register.

# Create a join token.
# First, get the karmada API server kubeconfig from the GKE cluster.
kubectl get secret -n karmada-system karmada-kubeconfig -o jsonpath={.data.kubeconfig} | base64 -d > karmada.config

# Need to resolve the internal address of the generated karmada API server config.
# I chose to use telepresence.
telepresence helm install
telepresence connect

# Because I deploy the control plane with helm, I had no /etc/karmada, which caused an error.
# Define it here.
sudo mkdir /etc/karmada
sudo chown $USER /etc/karmada

# Now we can create the token.
karmadactl token create --print-register-command --kubeconfig karmada.config

# Switch to member cluster context and execute join command.
kubectl config use-context desktop
karmadactl register <CONTROL_PLANE_API> --token <TOKEN> --discovery-token-ca-cert-hash <CA_CERT_HASH>

