# Cilium Network Troubleshooting Runbook

CSM uses Cilium Container Network Interface (CNI) plugin, responsible for assigning IP addresses to pods and establishing network connectivity within and between Kubernetes nodes.
This document provides guidance on how to troubleshoot Cilium-related issues in a CSM environment.

    1. [Check Cilium Status](#check-cilium-status)
    2. [Inspect Cilium Logs](#inspect-cilium-logs)
    3. [Cilium Monitoring](#cilium-monitoring)
    4. [Troubleshooting using Hubble](#troubleshooting-using-hubble)

## Check Cilium Status

 - Run `cilium status` to check the overall health of Cilium components.
 - Look for any errors or warnings in the output.
 
(`ncn-m001#`) On any Kubernetes NCN run:

 ```bash
 cilium status 
 ```

Expected output resembles the following:
 ```text
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    OK
 \__/¯¯\__/    Hubble Relay:       OK
    \__/       ClusterMesh:        disabled

DaemonSet              cilium             Desired: 7, Ready: 7/7, Available: 7/7
DaemonSet              cilium-envoy       Desired: 7, Ready: 7/7, Available: 7/7
Deployment             cilium-operator    Desired: 1, Ready: 1/1, Available: 1/1
Deployment             hubble-relay       Desired: 1, Ready: 1/1, Available: 1/1
Deployment             hubble-ui          Desired: 1, Ready: 1/1, Available: 1/1
Containers:            cilium             Running: 7
                       cilium-envoy       Running: 7
                       cilium-operator    Running: 1
                       hubble-relay       Running: 1
                       hubble-ui          Running: 1
Cluster Pods:          311/311 managed by Cilium
Helm chart version:    1.16.5
Image versions         cilium             artifactory.algol60.net/csm-docker/stable/quay.io/cilium/cilium:v1.16.5: 7
                       cilium-envoy       artifactory.algol60.net/csm-docker/stable/quay.io/cilium/cilium-envoy:v1.30.8: 7
                       cilium-operator    artifactory.algol60.net/csm-docker/stable/quay.io/cilium/operator-generic:v1.16.5: 1
                       hubble-relay       artifactory.algol60.net/csm-docker/stable/quay.io/cilium/hubble-relay:v1.16.5: 1
                       hubble-ui          artifactory.algol60.net/csm-docker/stable/quay.io/cilium/hubble-ui-backend:v0.13.1: 1
                       hubble-ui          artifactory.algol60.net/csm-docker/stable/quay.io/cilium/hubble-ui:v0.13.1: 1
 ```

All the pods should have `Running` status and the number of `Ready` pods should match the `Desired` count. If there are discrepancies, it may indicate issues with Cilium components.
If any errors or warnings are observed, investigate further by checking the logs of the specific Cilium pod or component. Ensure that all Cilium components are running and healthy.

## Inspect Cilium Logs

To get node specific status exec into the cilium pod by performing the following steps.

(`ncn-m001#`) On any Kubernetes NCN run:
 ```bash
 kubectl -n kube-system get pod -l k8s-app=cilium -o wide
 ```

Expected output resembles the following:

 ```text
NAME           READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
cilium-9k9wp   1/1     Running   0          17d   10.252.1.9    ncn-m002   <none>           <none>
cilium-dlp8x   1/1     Running   0          17d   10.252.1.11   ncn-w004   <none>           <none>
cilium-ps8gx   1/1     Running   0          17d   10.252.1.8    ncn-m003   <none>           <none>
cilium-t2dn8   1/1     Running   0          17d   10.252.1.6    ncn-w002   <none>           <none>
cilium-tlzqz   1/1     Running   0          17d   10.252.1.7    ncn-w001   <none>           <none>
cilium-xqm8f   1/1     Running   0          17d   10.252.1.5    ncn-w003   <none>           <none>
cilium-zx2d2   1/1     Running   0          17d   10.252.1.10   ncn-m001   <none>           <none>
 ```
Any errors or warnings that may indicate issues with network connectivity or policies. In this example, the pod `cilium-dlp8x` is running on node `ncn-w004` and it is used to check the status of Cilium on that node.

Then exec into the cilium pod:

 ```bash
  kubectl -n kube-system exec -it cilium-dlp8x -- cilium status
 ```

Expected output resembles the following:

 ```text
    Defaulted container "cilium-agent" out of: cilium-agent, config (init), mount-cgroup (init), apply-sysctl-overwrites (init), mount-bpf-fs (init), clean-cilium-state (init), install-cni-binaries (init)
KVStore:                 Ok   Disabled
Kubernetes:              Ok   1.32 (v1.32.5) [linux/amd64]
Kubernetes APIs:         ["EndpointSliceOrEndpoint", "cilium/v2::CiliumClusterwideNetworkPolicy", "cilium/v2::CiliumEndpoint", "cilium/v2::CiliumNetworkPolicy", "cilium/v2::CiliumNode", "cilium/v2alpha1::CiliumCIDRGroup", "core/v1::Namespace", "core/v1::Pods", "core/v1::Service", "networking.k8s.io/v1::NetworkPolicy"]
KubeProxyReplacement:    False
Host firewall:           Disabled
SRv6:                    Disabled
CNI Chaining:            none
CNI Config file:         successfully wrote CNI configuration file to /host/etc/cni/net.d/05-cilium.conflist
Cilium:                  Ok   1.16.5 (v1.16.5-ad688277)
NodeMonitor:             Listening for events on 64 CPUs with 64x4096 of shared memory
Cilium health daemon:    Ok
IPAM:                    IPv4: 49/254 allocated from 10.32.9.0/24,
IPv4 BIG TCP:            Disabled
IPv6 BIG TCP:            Disabled
BandwidthManager:        Disabled
Routing:                 Network: Tunnel [vxlan]   Host: Legacy
Attach Mode:             TCX
Device Mode:             veth
Masquerading:            IPTables [IPv4: Enabled, IPv6: Disabled]
Controller Status:       258/258 healthy
Proxy Status:            OK, ip 10.32.9.170, 0 redirects active on ports 10000-20000, Envoy: external
Global Identity Range:   min 256, max 65535
Hubble:                  Ok              Current/Max Flows: 4095/4095 (100.00%), Flows/s: 210.25   Metrics: Ok
Encryption:              Disabled
Cluster health:          7/7 reachable   (2025-08-07T21:36:12Z)
Modules Health:          Stopped(0) Degraded(0) OK(236)
 ```

## Cilium Monitoring

Cilium monitoring helps to identify issues with network policies, connectivity, and more. Hubble can also be used for more advanced monitoring and troubleshooting.
Please refer to the [Cilium and Hubble Monitoring](../operations/system_management_health/Cilium_Monitoring.md) documentation for more information. 

## Troubleshooting using Hubble

To use the Hubble tool to diagnose network problems start a port-forwarding session like this:

(`ncn-m001#`) On any Kubernetes NCN run:

 ```bash
cilium hubble port-forward &
[1] 903511
ncn-m001:~ # ℹ️  Hubble Relay is available at 127.0.0.1:4245
 ```
    
Then, you can use the `hubble` command to inspect network traffic and events.
The Hubble CLI tool can then be used to gather information.

For example to look at traffic that is being dropped due to network policies:

 ```bash
hubble observe --verdict DROPPED --last 5
 ```
This command will show the last 5 dropped packets along with their details.

 ```text
ncn-m001:~ # hubble observe --verdict DROPPED --last 5
Aug  7 21:40:47.320: fe80::a0ec:7cff:fe45:72b (ID:32748) <> ff02::2 (unknown) Unsupported L3 protocol DROPPED (ICMPv6 RouterSolicitation)
Aug  7 21:40:49.515: sysmgmt-health/vmagent-vms-0-6cbf9d467c-49nxn:39932 (ID:64899) <> dvs/cray-dvs-mqtt-ss-1:15020 (ID:50714) Policy denied DROPPED (TCP Flags: SYN)
Aug  7 21:40:50.084: sysmgmt-health/vmagent-vms-1-5d5dddd445-q9znc:60136 (ID:3549) <> dvs/cray-dvs-mqtt-ss-0:15020 (ID:50714) Policy denied DROPPED (TCP Flags: SYN)
Aug  7 21:40:50.091: sysmgmt-health/vmagent-vms-1-5d5dddd445-jp7gf:58510 (ID:3549) <> dvs/cray-dvs-mqtt-ss-0:15020 (ID:50714) policy-verdict:none INGRESS DENIED (TCP Flags: SYN)
 ```

For Hubble documentation, refer : [Hubble documentation](https://docs.cilium.io/en/stable/observability/hubble/hubble-cli/)
