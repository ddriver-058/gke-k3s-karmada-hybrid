# Ingress-nginx
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm fetch ingress-nginx/ingress-nginx --version 4.10.1 --untar

# Karmada
helm repo add karmada-charts https://raw.githubusercontent.com/karmada-io/karmada/master/charts
helm fetch karmada-charts/karmada --version 1.9.0 --untar