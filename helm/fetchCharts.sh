# Ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm fetch ingress-nginx/ingress-nginx --version 4.10.1 --untar

# Karmada
helm repo add karmada-charts https://raw.githubusercontent.com/karmada-io/karmada/master/charts
helm fetch karmada-charts/karmada --version 1.9.0 --untar

# Submariner
helm repo add submariner-latest https://submariner-io.github.io/submariner-charts/charts
helm fetch submariner-latest/submariner-k8s-broker --version 0.17.1 --untar
