# generate ssh key pair

# get nodes
kubectl get nodes -o wide

NAME                                STATUS   ROLES   AGE     VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
aks-agentpool-35472979-vmss000000   Ready    agent   3d19h   v1.26.6   10.224.0.113   <none>        Ubuntu 22.04.3 LTS   5.15.0-1049-azure   containerd://1.7.5-1
aks-agentpool-35472979-vmss000001   Ready    agent   3d19h   v1.26.6   10.224.0.4     <none>        Ubuntu 22.04.3 LTS   5.15.0-1049-azure   containerd://1.7.5-1

# deploy and connect to debug pod
kubectl debug node/aks-agentpool-35472979-vmss000000 -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0

# node kubelet logs
kubectl get --raw "/api/v1/nodes/aks-agentpool-35472979-vmss000000/proxy/logs/messages"|grep kubelet

