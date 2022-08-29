# `containerd`

`containerd` is a container runtime (`systemd` service) that runs on the host. It is used to run containers on the Kubernetes platform.

- [`/var/lib/containerd` filling up](#varlibcontainerd-filling-up)
- [Restarting `containerd` on a worker NCN](#restarting-containerd-on-a-worker-ncn)

## `/var/lib/containerd` filling up

In older versions of `containerd`, there are cases where the `/var/lib/containerd` directory fills up. In the event that this occurs, the following steps can be used to remediate the issue.

1. (`ncn-mw#`) Restart `containerd` on the NCN.

    > Whether or not this resolves the space issue, if this is a worker NCN, then also see the notes in the
    > [Restarting `containerd` on a worker NCN](#restarting-containerd-on-a-worker-ncn) section for subsequent steps that must be taken after
    > `containerd` is restarted.

    ```bash
    systemctl restart containerd
    ```

    Many times this will free up space in `/var/lib/containerd` -- if not, then proceed to the next step.

1. (`ncn-mw#`) Restart `kubelet` on the NCN.

    ```bash
    systemctl restart kubelet
    ```

    If restarting `kubelet` fails to free up space in `/var/lib/containerd`, then proceed to the next step.

1. (`ncn-mw#`) Prune unused container images on the NCN.

    ```bash
    crictl rmi --prune
    ```

    Any unused images will be pruned. If still encountering disk space issues in `/var/lib/containerd`, then proceed to the next step to reboot the NCN.

1. Reboot the NCN.

    Follow the [Reboot NCNs](../node_management/Reboot_NCNs.md) process to properly cordon/drain the NCN and reboot.
    Generally this will free up space in `/var/lib/containerd`.

## Restarting `containerd` on a worker NCN

If the `containerd` service is restarted on a worker node, then this may cause the `sonar-jobs-watcher` pod running on that worker node to fail when attempting
to cleanup unneeded containers. The following procedure determines if this is the case and remediates it, if necessary.

1. (`ncn-mw#`) Retrieve the name of the `sonar-jobs-watcher` pod that is running on this worker node.

    Modify the following command to specify the name of the specific worker NCN where `containerd` was restarted.

    ```bash
    kubectl get pods -l name=sonar-jobs-watcher -n services -o wide | grep ncn-w001
    ```

    Example output:

    ```text
    sonar-jobs-watcher-8z6th   1/1     Running   0          95d   10.42.0.6    ncn-w001   <none>           <none>
    ```

1. (`ncn-mw#`) View the logs for the `sonar-jobs-watcher` pod.

    Modify the following command to specify the pod name identified in the previous step.

    ```bash
    kubectl logs sonar-jobs-watcher-8z6th -n services
    ```

    Example output:

    ```text
    Found pod cray-dns-unbound-manager-1631116980-h69h6 with restartPolicy 'Never' and container 'manager' with status 'Completed'
    All containers of job pod cray-dns-unbound-manager-1631116980-h69h6 has completed. Killing istio-proxy (1c65dacb960c2f8ff6b07dfc9780c4621beb8b258599453a08c246bbe680c511) to allow job to complete
    time="2021-09-08T16:44:18Z" level=fatal msg="failed to connect: failed to connect, make sure you are running as root and the runtime has been started: context deadline exceeded"
    ```

    When this occurs, pods that are running on the node where `containerd` was restarted may remain in a `NotReady` state and never complete.

1. (`ncn-mw#`) Check if pods are stuck in a `NotReady` state.

    ```bash
    kubectl get pods -o wide -A | grep NotReady
    ```

    Example output:

    ```text
    services      cray-dns-unbound-manager-1631116980-h69h6             1/2   NotReady  0     10m   10.42.0.100  ncn-w001  <none>      <none>
    ```

1. (`ncn-mw#`) If any pods are stuck in a `NotReady` state, then restart the `sonar-jobs-watcher` `daemonset` to resolve the issue.

    ```bash
    kubectl rollout restart -n services daemonset sonar-jobs-watcher
    ```

    Expected output:

    ```text
    daemonset.apps/sonar-jobs-watcher restarted
    ```

1. (`ncn-mw#`) Verify that the restart completed successfully.

    ```bash
    kubectl rollout status -n services daemonset sonar-jobs-watcher
    ```

    Expected output:

    ```text
    daemon set "sonar-jobs-watcher" successfully rolled out
    ```

Once the `sonar-jobs-watcher` pods restart, any pods that were in a `NotReady` state should complete within about a minute.

To learn more in general about `containerd`, refer to [the `containerd` documentation](https://containerd.io/).
