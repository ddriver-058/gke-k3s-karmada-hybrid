# https://linkerd.io/2.15/tasks/automatic-failover/

# Install linkerd-smi -- provides an alternative to HTTPRoute for trafficplitting (TrafficSplit)
# I'll failover from GKE, so we will install there
helm --kube-context=$GKE repo add linkerd-smi https://linkerd.github.io/linkerd-smi
helm --kube-context=$GKE repo up
helm --kube-context=$GKE install linkerd-smi -n linkerd-smi --create-namespace linkerd-smi/linkerd-smi

# Install linkerd-failover in GKE. Provides a means to failover inactive services
helm --kube-context=$GKE repo add linkerd-edge https://helm.linkerd.io/edge
helm --kube-context=$GKE repo up
helm --kube-context=$GKE install linkerd-failover -n linkerd-failover --create-namespace --devel linkerd-edge/linkerd-failover
