# CSM services not starting when `/var/lib/containerd` is full during IUF upgrade

While running the IUF management-node-rollout stage for a worker node, pods on the worker node are drained and restarted on other worker nodes. If the other worker nodes have their `/var/lib/containerd` filesystem 100% full, the restart of the pods fail.

## Issue Description

As part of worker node rollout the node is drained to allow restart of the same pods on a different worker node .
During this process, if the worker selected by the Kubernetes scheduler has its container runtime storage (`/var/lib/containerd`) full, the pods fail to restart.
Kubernetes continues to place pods there until pulls fail. This can cause many CSM services to become unavailable.

## Error Identification

- After the worker node is rolled out, check the status of the pods using below command:

    ```bash
    kubectl get pods -o wide -A | egrep -v "Run|Comp"

    cert-manager     cray-certmanager-cert-manager-6b757c6c68-sm98n                    1/2     ImagePullBackOff            0                 50m     10.40.0.109   ncn-w004   <none>           <none>
    cert-manager     cray-certmanager-cert-manager-cainjector-6f6558dbc-97x64          0/2     Init:CreateContainerError   1 (39m ago)       50m     10.40.0.117   ncn-w004   <none>           <none>
    operators        strimzi-cluster-operator-647bfc796d-vk8n7                         0/1     CreateContainerError        0                 50m     10.40.0.108   ncn-w004   <none>           <none>
    pki-operator     trustedcerts-operator-6f9d94bdb5-4nm2f                            0/2     CreateContainerError        2 (31m ago)       50m     10.40.0.120   ncn-w004   <none>           <none>
    services         cray-dhcp-kea-7495995c78-hqjgd                                    0/3     Init:CreateContainerError   0                 50m     10.40.0.110   ncn-w004   <none>           <none>
    services         cray-dhcp-kea-postgres-1                                          0/3     Init:0/1                    0                 24s     <none>        ncn-w001   <none>           <none>
    services         cray-dns-powerdns-postgres-2                                      2/3     CreateContainerError        0                 81m     10.40.0.102   ncn-w004   <none>           <none>
    services         cray-hms-badger-postgres-1                                        2/3     CreateContainerError        0                 81m     10.40.0.101   ncn-w004   <none>           <none>
    services         cray-keycloak-2                                                   0/2     Init:CreateContainerError   0                 50m     10.40.0.106   ncn-w004   <none>           <none>
    services         cray-meds-7bbb9b8b6b-sp5pf                                        0/2     Init:CreateContainerError   0                 50m     10.40.0.111   ncn-w004   <none>           <none>
    services         cray-scsd-7649c49c7d-pljrk                                        1/2     ImagePullBackOff            0                 50m     10.40.0.21    ncn-w004   <none>           <none>
    services         hms-discovery-29243088-kzhv7                                      1/2     NotReady                    0                 73s     10.32.0.4     ncn-w001   <none>           <none>
    services         keycloak-postgres-2                                               2/3     CreateContainerError        0                 81m     10.40.0.104   ncn-w004   <none>           <none>
    ```

- Check logs of the deployment to see the errors/warnings as shown:

    ```bash
    Warning  FailedCreatePodSandBox  58m                  kubelet            Failed to create pod sandbox: rpc error: code = Unknown desc = failed to create containerd container: failed to create temp dir: mkdir /var/lib/containerd/io.containerd.snapshotter.v1.native/snapshots/new-555311316: no space left on device

    Warning  Failed           39m                    kubelet       Error: failed to create containerd container: copying of parent failed: failed to copy files: copy file range failed: no space left on device
    ```

- Check disk space usage for worker nodes using the below command:

    ```bash
    ncn-w004:~  df -h /var/lib/containerd
    Filesystem            Size  Used Avail Use% Mounted on
    containerd_overlayfs  646G  646G   68K 100% `/var/lib/containerd`  
    ```

## Workaround Description

1. Follow the steps mentioned in [Cleanup `Containerd`](../../operations/kubernetes/Containerd.md) to free up the space.

2. Run the IUF management-node-rollout stage and ensure it completes successfully.
