# `containerd`

`containerd` is a `daemonset` that runs on the host. It is used to run containers on the Kubernetes platform.

## `/var/lib/containerd` filling up

In older versions of `containerd`, there are cases where the `/var/lib/containerd` directory fills up. In the event that this occurs, the following steps can be used to remediate the issue.

1. Restart `containerd` on the NCN.

   ```bash
   ncn# systemctl restart containerd
   ```

   Many times this will free up space in `/var/lib/containerd` -- if not, then proceed to the next step.
   In either case, see the notes in the [Restart `containerd`](#restart-containerd) section for subsequent steps that must be taken after `containerd` is restarted (independent of disk space issues).

1. Restart `kubelet` on the NCN.

   ```bash
   ncn# systemctl restart kubelet
   ```

   If restarting `kubelet` fails to free up space in `/var/lib/containerd`, then proceed to the next step.

1. Prune unused container images on the NCN:

   ```bash
   ncn-w001 # crictl rmi --prune
   ```

   Any unused images will be pruned. Finally, if still encountering disk space issues in `/var/lib/containerd`, proceed to the next step to reboot the NCN.

1. Reboot the NCN:

   Follow the [Reboot NCNs](../node_management/Reboot_NCNs.md) process to properly cordon/drain the NCN and reboot. Generally this final step will free up space in `/var/lib/containerd`.

### Restart `containerd`

If the `containerd` service is restarted on a worker node, this may cause the sonar-jobs-watcher pod running on that worker node to fail when attempting to cleanup unneeded containers. For example:

1. Restart `containerd`.

    ```bash
    ncn-w001# systemctl restart containerd
    ```

1. Retrieve the name of the sonar-jobs-watcher pod.

    ```bash
    ncn-w001# kubectl get pods -l name=sonar-jobs-watcher -n services -o wide | grep ncn-w001
    ```

    Example output:

    ```bash
    sonar-jobs-watcher-8z6th   1/1     Running   0          95d   10.42.0.6    ncn-w001   <none>           <none>
    ```

1. View the logs for the sonar-jobs-watcher pod.

    ```bash
    ncn-w001# kubectl logs sonar-jobs-watcher-8z6th -n services
    ```

    Example output:

    ```bash
    Found pod cray-dns-unbound-manager-1631116980-h69h6 with restartPolicy 'Never' and container 'manager' with status 'Completed'
    All containers of job pod cray-dns-unbound-manager-1631116980-h69h6 has completed. Killing istio-proxy (1c65dacb960c2f8ff6b07dfc9780c4621beb8b258599453a08c246bbe680c511) to allow job to complete
    time="2021-09-08T16:44:18Z" level=fatal msg="failed to connect: failed to connect, make sure you are running as root and the runtime has been started: context deadline exceeded"
    ```

    When this occurs, pods that are running on the node where containerd was restarted may remain in a `NotReady` state and never complete.

1. Check if pods are stuck in a `NotReady` state.

    ```bash
    ncn-w001 # kubectl get pods -o wide -A | cray-dns-unbound-manager
    ```

    Example output:

    ```bash
    services      cray-dns-unbound-manager-1631116980-h69h6             1/2   NotReady  0     10m   10.42.0.100  ncn-w001  <none>      <none>
    ```

1. If pods are stuck in a `NotReady` state, restart the sonar-jobs-watcher `daemonset` to resolve the issue.

    Once the sonar-jobs-watcher pods restart, the pod(s) that were in a `NotReady` state should complete within about a minute.

    ```bash
    ncn-w001 # kubectl rollout restart -n services daemonset sonar-jobs-watcher
    ```

    `daemonset.apps/sonar-jobs-watcher restarted` will be returned when the pods have restarted.

To learn more in general about `containerd`, refer to [https://containerd.io/](https://containerd.io/).

## `containerd` slow startup after reboot

On some systems, `containerd` can take a very long time to start after a reboot.  This has been fixed in CSM 1.3, but if this symptom occurs, you may see the following messages indicating `cleaning up dead shim` in the `containerd` log files:

```bash
Aug 26 00:06:10 ncn-w001 containerd[4005]: time="2022-08-26T00:06:10.522985910Z" level=info msg="cleaning up dead shim"
Aug 26 00:06:10 ncn-w001 containerd[4005]: time="2022-08-26T00:06:10.556198245Z" level=warning msg="cleanup warnings time=\"2022-08-26T00:06:10Z\" level=info msg=\"starting signal loop\" namespace=k8s.io pid=57627\n"
Aug 26 00:06:10 ncn-w001 containerd[4005]: time="2022-08-26T00:06:10.556821890Z" level=info msg="loading plugin \"io.containerd.monitor.v1.cgroups\"..." type=io.containerd.monitor.v1
Aug 26 00:06:10 ncn-w001 containerd[4005]: time="2022-08-26T00:06:10.557576058Z" level=info msg="loading plugin \"io.containerd.service.v1.tasks-service\"..." type=io.containerd.service.v1
```

Instructing `containerd` to remove shims when `containerd` is being shutdown will correct this issue. Add the following `ExecStopPost` line to the `/srv/cray/resources/common/containerd/containerd.service` file:

```bash
.
.
[Service]
ExecStartPre=/sbin/modprobe overlay && /sbin/modprobe br_netfilter
ExecStart=/usr/local/bin/containerd
ExecStopPost=/usr/bin/find /run/containerd/io.containerd.runtime.v2.task -name address -type f -delete
Restart=always
RestartSec=5
Delegate=yes
.
.
```

Restart `containerd` to pick up the change:

```bash
ncn-mw# systemctl restart containerd
```

**NOTE:** If this NCN is rebuilt, this change will need to be re-applied (until the system is upgraded to CSM 1.3).
