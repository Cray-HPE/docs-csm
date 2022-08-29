# `containerd`

`containerd` is a container runtime (`systemd` service) that runs on the host. It is used to run containers on the Kubernetes platform.

- [`/var/lib/containerd` filling up](#varlibcontainerd-filling-up)
- [`containerd` slow startup after reboot](#containerd-slow-startup-after-reboot)
- [Restarting `containerd` on a worker NCN](#restarting-containerd-on-a-worker-ncn)

## `/var/lib/containerd` filling up

In older versions of `containerd`, there are cases where the `/var/lib/containerd` directory fills up. In the event that this occurs, the following steps can be used to remediate the issue.

1. Restart `containerd` on the NCN.

    > Whether or not this resolves the space issue, if this is a worker NCN, then also see the notes in the
    > [Restarting `containerd` on a worker NCN](#restarting-containerd-on-a-worker-ncn) section for subsequent steps that must be taken after
    > `containerd` is restarted.

    ```bash
    ncn-mw# systemctl restart containerd
    ```

    Many times this will free up space in `/var/lib/containerd` -- if not, then proceed to the next step.

1. Restart `kubelet` on the NCN.

    ```bash
    ncn-mw# systemctl restart kubelet
    ```

    If restarting `kubelet` fails to free up space in `/var/lib/containerd`, then proceed to the next step.

1. Prune unused container images on the NCN.

    ```bash
    ncn-mw# crictl rmi --prune
    ```

    Any unused images will be pruned. If still encountering disk space issues in `/var/lib/containerd`, then proceed to the next step to reboot the NCN.

1. Reboot the NCN.

    Follow the [Reboot NCNs](../node_management/Reboot_NCNs.md) process to properly cordon/drain the NCN and reboot.
    Generally this will free up space in `/var/lib/containerd`.

## `containerd` slow startup after reboot

On some systems, `containerd` can take a very long time to start after a reboot. This has been fixed in CSM 1.3, but if this symptom occurs,
messages indicating `cleaning up dead shim` may appear in the `containerd` log files. For example:

```text
Aug 26 00:06:10 ncn-w001 containerd[4005]: time="2022-08-26T00:06:10.522985910Z" level=info msg="cleaning up dead shim"
Aug 26 00:06:10 ncn-w001 containerd[4005]: time="2022-08-26T00:06:10.556198245Z" level=warning msg="cleanup warnings time=\"2022-08-26T00:06:10Z\" level=info msg=\"starting signal loop\" namespace=k8s.io pid=57627\n"
Aug 26 00:06:10 ncn-w001 containerd[4005]: time="2022-08-26T00:06:10.556821890Z" level=info msg="loading plugin \"io.containerd.monitor.v1.cgroups\"..." type=io.containerd.monitor.v1
Aug 26 00:06:10 ncn-w001 containerd[4005]: time="2022-08-26T00:06:10.557576058Z" level=info msg="loading plugin \"io.containerd.service.v1.tasks-service\"..." type=io.containerd.service.v1
```

Instructing `containerd` to remove shims when `containerd` is being shutdown will correct this issue.

1. Edit the `/srv/cray/resources/common/containerd/containerd.service` file.

    Add the following `ExecStopPost` line to the file:

    ```text
    ExecStopPost=/usr/bin/find /run/containerd/io.containerd.runtime.v2.task -name address -type f -delete
    ```

    After the edit, the relevant section of the file should look similar to the following:

    ```text
    [Service]
    ExecStartPre=/sbin/modprobe overlay && /sbin/modprobe br_netfilter
    ExecStart=/usr/local/bin/containerd
    ExecStopPost=/usr/bin/find /run/containerd/io.containerd.runtime.v2.task -name address -type f -delete
    Restart=always
    RestartSec=5
    Delegate=yes
    ```

1. Restart `containerd` to pick up the change.

    > If this is a worker NCN, then also see the notes in the [Restarting `containerd` on a worker NCN](#restarting-containerd-on-a-worker-ncn)
    > section for subsequent steps that must be taken after `containerd` is restarted.

    ```bash
    ncn-mw# systemctl restart containerd
    ```

**NOTE:** If this NCN is rebuilt, then this change will need to be re-applied (until the system is upgraded to CSM 1.3).

## Restarting `containerd` on a worker NCN

If the `containerd` service is restarted on a worker node, then this may cause the `sonar-jobs-watcher` pod running on that worker node to fail when attempting
to cleanup unneeded containers. The following procedure determines if this is the case and remediates it, if necessary.

1. Retrieve the name of the `sonar-jobs-watcher` pod that is running on this worker node.

    Modify the following command to specify the name of the specific worker NCN where `containerd` was restarted.

    ```bash
    ncn-mw# kubectl get pods -l name=sonar-jobs-watcher -n services -o wide | grep ncn-w001
    ```

    Example output:

    ```text
    sonar-jobs-watcher-8z6th   1/1     Running   0          95d   10.42.0.6    ncn-w001   <none>           <none>
    ```

1. View the logs for the `sonar-jobs-watcher` pod.

    Modify the following command to specify the pod name identified in the previous step.

    ```bash
    ncn-mw# kubectl logs sonar-jobs-watcher-8z6th -n services
    ```

    Example output:

    ```text
    Found pod cray-dns-unbound-manager-1631116980-h69h6 with restartPolicy 'Never' and container 'manager' with status 'Completed'
    All containers of job pod cray-dns-unbound-manager-1631116980-h69h6 has completed. Killing istio-proxy (1c65dacb960c2f8ff6b07dfc9780c4621beb8b258599453a08c246bbe680c511) to allow job to complete
    time="2021-09-08T16:44:18Z" level=fatal msg="failed to connect: failed to connect, make sure you are running as root and the runtime has been started: context deadline exceeded"
    ```

    When this occurs, pods that are running on the node where `containerd` was restarted may remain in a `NotReady` state and never complete.

1. Check if pods are stuck in a `NotReady` state.

    ```bash
    ncn-mw# kubectl get pods -o wide -A | grep NotReady
    ```

    Example output:

    ```text
    services      cray-dns-unbound-manager-1631116980-h69h6             1/2   NotReady  0     10m   10.42.0.100  ncn-w001  <none>      <none>
    ```

1. If any pods are stuck in a `NotReady` state, then restart the `sonar-jobs-watcher` `daemonset` to resolve the issue.

    ```bash
    ncn-mw# kubectl rollout restart -n services daemonset sonar-jobs-watcher
    ```

    Expected output:

    ```text
    daemonset.apps/sonar-jobs-watcher restarted
    ```

1. Verify that the restart completed successfully.

    ```bash
    ncn-mw# kubectl rollout status -n services daemonset sonar-jobs-watcher
    ```

    Expected output:

    ```text
    daemon set "sonar-jobs-watcher" successfully rolled out
    ```

Once the `sonar-jobs-watcher` pods restart, any pods that were in a `NotReady` state should complete within about a minute.

To learn more in general about `containerd`, refer to [the `containerd` documentation](https://containerd.io/).
