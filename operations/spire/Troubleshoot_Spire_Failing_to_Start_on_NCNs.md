# Troubleshoot Spire Failing to Start on NCNs

The spire-agent service may fail to start on Kubernetes non-compute nodes
\(NCNs\). A key indication of this failure is when logging errors occur with
the `journalctl` command. The following are logging errors that will indicate
if the spire-agent is failing to start:

- The `join token does not exist or has already been used` message is returned
- The last lines of the logs contain multiple lines of `systemd[1]:
  spire-agent.service: Start request repeated too quickly.`

Deleting the `request-ncn-join-token` `daemonset` pod running on the node may
clear the issue.

While the spire-agent `systemctl` service on the Kubernetes node should
eventually restart cleanly, administrators may need to log in to the impacted
nodes and restart the service. The easiest way to delete the appropriate pod is
to create the following function and run it on the impacted node.

```bash
function renewncnjoin() {
    if [ -z "$1" ]; then echo "usage: renewncnjoin NODE_HOSTNAME"
    else
        for pod in $(kubectl get pods -n spire | grep request-ncn-join-token | awk '{print $1}');
        do
            if kubectl describe -n spire pods $pod | grep -q "Node:.*$1";
            then echo "Restarting $pod running on $1"; kubectl delete -n spire pod "$pod";
            fi
        done
    fi
}
```

Run the `renewncnjoin` function on the NCN where `kubectl` is running:

```bash
renewncnjoin NODE_HOSTNAME
```

The spire-agent service may also fail if an NCN was powered off for too long
and its tokens expired. If this happens, delete `/var/lib/spire/agent_svid.der`,
`/var/lib/spire/bundle.der`, and `/var/lib/spire/data/keys.json` off the NCN before
deleting the `request-ncn-join-token` `daemonset` pod.

```bash
rm /var/lib/spire/agent_svid.der
rm /var/lib/spire/bundle.der
rm /var/lib/spire/data/keys.json
```
