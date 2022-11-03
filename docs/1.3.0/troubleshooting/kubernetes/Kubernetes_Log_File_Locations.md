# Kubernetes Log File Locations

Locations of various K8s log types on the system.

|Log Type|Component|Purpose|Location|
|--------|---------|-------|--------|
|Kubernetes Master|API server|Responsible for serving the API|`kubectl -n kube-system logs -l component=kube-apiserver`|
|Scheduler|Responsible for making scheduling decisions|`kubectl -n kube-system logs -l component=kube-scheduler`|
|Controller|Manages replication controllers|`kubectl -n kube-system logs -l component=kube-controller-manager`|
|Kubernetes Worker|Kubelet|Responsible for running containers on the node|`journalctl -xeu kubelet`|
|Kube proxy|Responsible for service load balancing|`kubectl -n kube-system logs -l k8s-app=kube-proxy`|

