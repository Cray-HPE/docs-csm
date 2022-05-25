# TDS Lower CPU Requests

TDS systems with three worker nodes will encounter pod scheduling issues when worker nodes are taken out of the Kubernetes cluster and being upgraded.  _*For systems with only three worker nodes*_, the following script should be executed to reduce the CPU request for some services with high CPU requests in order to allow critical upgrade-related services to be successfully scheduled on two worker nodes:

>
>```bash
> ncn-m001# /usr/share/doc/csm/upgrade/1.2/scripts/k8s/tds_lower_cpu_requests.sh
>```
>

Note that some services with these lower CPU request may encounter CPU throttling (see [Determine if Pods are Hitting Resource Limits](./Determine_if_Pods_are_Hitting_Resource_Limits.md)). If needed, the top portion of the script (see below) can be edited and re-run to further adjust these CPU requests. Note that commenting out any of the lines below will indicate the script should not adjust the CPU resource for that service. Also see the `Kubernetes/Compute Resources/Namespace (Pods)` grafana page ([Access System Management Health Services](../system_management_health/Access_System_Management_Health_Services.md)) for a historical view of a given pod's CPU utilization for this specific system.

>
>```
> spire_postgres_new_limit=1000m
> elasticsearch_master_new_cpu_request=1500m
> cluster_kafka_new_cpu_request=1
> sma_grafana_new_cpu_request=100m
> sma_kibana_new_cpu_request=100m
> cluster_zookeeper_new_cpu_request=100m
> cray_smd_new_cpu_request=1
> cray_smd_postgres_new_cpu_request=500m
> sma_postgres_cluster_new_cpu_request=500m
> cray_capmc_new_cpu_request=500m
> nexus_new_cpu_request=2
> cray_metallb_speaker_new_cpu_request=1
>```
>

The script will output the current value of the request along with the new value. It is recommended to capture and save the output (and store it external to the cluster) from this script in order to retain which values were changed (and from what value) in the event rolling back to the original value is desired:

>
>```
> Patching cray-capmc deployment with new cpu request of 500m (from 2100m)
> deployment.apps/cray-capmc patched
> Waiting for deployment spec update to be observed...
> Waiting for deployment "cray-capmc" rollout to finish: 0 out of 3 new replicas have been updated...
> Waiting for deployment "cray-capmc" rollout to finish: 1 out of 3 new replicas have been updated...
> Waiting for deployment "cray-capmc" rollout to finish: 1 out of 3 new replicas have been updated...
> Waiting for deployment "cray-capmc" rollout to finish: 1 out of 3 new replicas have been updated...
> Waiting for deployment "cray-capmc" rollout to finish: 2 out of 3 new replicas have been updated...
> Waiting for deployment "cray-capmc" rollout to finish: 2 out of 3 new replicas have been updated...
> Waiting for deployment "cray-capmc" rollout to finish: 2 out of 3 new replicas have been updated...
> Waiting for deployment "cray-capmc" rollout to finish: 1 old replicas are pending termination...
> Waiting for deployment "cray-capmc" rollout to finish: 1 old replicas are pending termination...
> deployment "cray-capmc" successfully rolled out
>```
