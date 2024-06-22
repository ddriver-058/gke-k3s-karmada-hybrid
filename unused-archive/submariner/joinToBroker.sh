# Install subctl
curl -Ls https://get.submariner.io | bash
export PATH=$PATH:~/.local/bin
echo export PATH=\$PATH:~/.local/bin >> ~/.profile

# Deploy broker
subctl deploy-broker --cluster $GKE # $GKE is the context name

# Join other cluster
# https://stackoverflow.com/questions/44190607/how-do-you-find-the-cluster-service-cidr-of-a-kubernetes-cluster
# Use tools like kubectl cluster-info dump to find svc and pod CIDR. If clusters overlap, use global CIDR.
subctl join --cluster desktop broker-info.subm --clusterid desktop

subctl join broker-info.subm 