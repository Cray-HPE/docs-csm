## Containerd

Containerd is a daemonset that runs on the host. It is used to run containers on the Kubernetes platform.

### /var/lib/containerd filling up

In older versions of containerd, there are cases where the `/var/lib/containerd` directory fills up. In the event that this occurs, the following steps can be used to remediate the issue.

1. Restart containerd on the NCN:

   ```bash
   ncn-w001 # systemctl restart containerd
   ```

   Many times this will free up space in `/var/lib/containerd` -- if not proceed to Step 2.  See notes below for subsequent steps that must be taken after containerd is restarted (independent of disk space issues).

1. Restart kubelet on the NCN:

   ```bash
   ncn-w001 # systemctl restart kubelet
   ```

   If restarting kubelet fails to free up space in `/var/lib/containerd`, proceed to Step 3.

1. Prune unused container images on the NCN:

   ```bash
   ncn-w001 # crictl rmi --prune
   ```

   Any unused images will be pruned.  Finally, if still encountering disk space issues in `/var/lib/containerd`, proceed to the next step to reboot the NCN.

1. Reboot the NCN:

   Follow the [Reboot_NCNs](../node_management/Reboot_NCNs.md) process to properly cordon/drain the NCN and reboot.  Generally this final step will free up space in `/var/lib/containerd`.

### Restarting containerd

If the containerd service is restarted on a worker node, this may cause the sonar-jobs-watcher pod running on that worker node to fail when attempting to cleanup unneeded containers. For example:

```bash
ncn-w001 # systemctl restart containerd

ncn-w001 # ncn-w001:~ # kubectl get pods -l name=sonar-jobs-watcher -n services -o wide | grep ncn-w001
sonar-jobs-watcher-8z6th   1/1     Running   0          95d   10.42.0.6    ncn-w001   <none>           <none>

ncn-w001 # kubectl logs sonar-jobs-watcher-8z6th -n services 
Found pod cray-dns-unbound-manager-1631116980-h69h6 with restartPolicy 'Never' and container 'manager' with status 'Completed'
All containers of job pod cray-dns-unbound-manager-1631116980-h69h6 has completed. Killing istio-proxy (1c65dacb960c2f8ff6b07dfc9780c4621beb8b258599453a08c246bbe680c511) to allow job to complete
time="2021-09-08T16:44:18Z" level=fatal msg="failed to connect: failed to connect, make sure you are running as root and the runtime has been started: context deadline exceeded"
```

When this occurs, pods that are running on the node where containerd was restarted may remain in a `NotReady` state and never complete. For example:

```bash
ncn-w001 # kubectl get pods -o wide -A | cray-dns-unbound-manager
services      cray-dns-unbound-manager-1631116980-h69h6             1/2   NotReady  0     10m   10.42.0.100  ncn-w001  <none>      <none>

```

Restarting the sonar-jobs-watcher daemonset should resolve the issue. Once the sonar-jobs-watcher pods restart, the pod(s) that were in a `NotReady` state should complete within about a minute.

```bash
ncn-w001 # kubectl rollout restart -n services daemonset sonar-jobs-watcher
daemonset.apps/sonar-jobs-watcher restarted
```


To learn more in general about containerd, refer to [https://containerd.io/](https://containerd.io/).
