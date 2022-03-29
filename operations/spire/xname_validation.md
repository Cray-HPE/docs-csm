# Xname Validation

CSM 1.2.5 supports the ability to require API calls that contain xnames to be
from the node with that xname. This is done by assigning unique workloads per
node. This may impact performance and require the replica count of the
spire-server statefulset to be increased.

Note: While spire is being reinstalled during the enable or disable process the
OPA validation will fail. This will cause all API requests that go through the
API Gateway to fail until the spire-jwks service is running again.

## Enable Xname Validation

In order to enable xname validation you need the docs-csm RPM installed and the
CSM 1.2.5 or newer tarball extracted somewhere on the node you are enabling it
from. In the command example below the CSM 1.2.5 tarball is extracted to
`/etc/cray/upgrade/csm/csm-1.2.5/tarball`.

Enabling xname validation requires the reinstallation of the spire server and
rejoining all nodes to spire. The `xnamevalidation.sh` script handles this for
NCNs and Storage nodes. Compute and UAN nodes will need to be restarted after
the `xnamevalidation.sh` script has finished running. If you do not restart
these nodes then they will be unable to acquire JWTs from spire.

### Example Commands

```bash
cd /etc/cray/upgrade/csm/csm-1.2.5/tarball/csm-1.2.5
/usr/share/doc/csm/scripts/operations/xnamevalidation.sh enable
```

### Example Output

```bash
ncn:/etc/cray/upgrade/csm/csm-1.2.5/tarball/csm-1.2.5 # /usr/share/doc/csm/scripts/operations/xnamevalidation.sh enable

Backup copy of the site-init secret has been saved to /tmp/tmp.rsDPG4zZf6/site-init.yaml
Stopping spire on NCNs
Warning: Permanently added 'ncn-s001,10.252.1.6' (ECDSA) to the list of known hosts.
[TRUNCATED]
Warning: Permanently added 'ncn-w004,10.252.1.7' (ECDSA) to the list of known hosts.
Uninstalling spire
release "spire" uninstalled
Waiting for all spire pods to be terminated.
Waiting for all spire pods to be terminated.
Waiting for all spire pods to be terminated.
No resources found in spire namespace.
Removing spire-server PVCs
persistentvolumeclaim "spire-data-spire-server-0" deleted
persistentvolumeclaim "spire-data-spire-server-1" deleted
persistentvolumeclaim "spire-data-spire-server-2" deleted
2022-03-29T18:15:22Z INF Initializing the connection to the Kubernetes cluster using KUBECONFIG (system default), and context (current-context) command=ship
2022-03-29T18:15:22Z INF Initializing helm client object command=ship
         |\
         | \
         |  \
         |___\      Shipping your Helm workloads with Loftsman
       \--||___/
  ~~~~~~\_____/~~~~~~~

2022-03-29T18:15:22Z INF Ensuring that the loftsman namespace exists command=ship
2022-03-29T18:15:22Z INF Loftsman will use the packaged charts at /etc/cray/upgrade/csm/csm-1.2.5/tarball/csm-1.2.5/helm as the Helm install source command=ship
2022-03-29T18:15:22Z INF Running a release for the provided manifest at /tmp/tmp.rsDPG4zZf6/manifest.yaml command=ship

~~~~~~~~~~~~~~~~~~~~~~~~~~~
Releasing spire v2.3.1
~~~~~~~~~~~~~~~~~~~~~~~~~~~

[TRUNCATED]

2022-03-29T18:15:28Z INF Recording log data to configmap loftsman-xnamevalidation-ship-log in namespace loftsman command=ship
deployment.apps/cray-opa-ingressgateway restarted
deployment.apps/cray-opa-ingressgateway-customer-admin restarted
deployment.apps/cray-opa-ingressgateway-customer-user restarted
Warning: resource secrets/site-init is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
secret/site-init configured
spire-server is not ready. Will retry after 30 seconds. (1/30)
[TRUNCATED]
spire-server is not ready. Will retry after 30 seconds. (7/30)
Enabling spire on NCNs
Warning: Permanently added 'ncn-m001,10.252.1.13' (ECDSA) to the list of known hosts.
[TRUNCATED]
ncn-s001 is being joined to spire.
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    86  100    54  100    32    637    377 --:--:-- --:--:-- --:--:--  1023
Warning: Permanently added 'ncn-s001,10.252.1.6' (ECDSA) to the list of known hosts.
[TRUNCATED]
ncn-s002 is being joined to spire.
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    86  100    54  100    32    623    369 --:--:-- --:--:-- --:--:--  1000
Warning: Permanently added 'ncn-s002,10.252.1.5' (ECDSA) to the list of known hosts.
[TRUNCATED]
ncn-s003 is being joined to spire.
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    87  100    54  100    33    781    477 --:--:-- --:--:-- --:--:--  1279
Warning: Permanently added 'ncn-s003,10.252.1.4' (ECDSA) to the list of known hosts.
[TRUNCATED]
component name (xname) validation has been enabled.
```

### Validation

To validate that xname validation is enabled, request a test JWT using the
`heartbeat-spire-agent` command. The token shown will include an xname.

```bash
ncn# /usr/bin/heartbeat-spire-agent api fetch jwt -socketPath=/root/spire/agent.sock -audience test | head -n1
token(spiffe://shasta/ncn/x3000c0s2b0n0/workload/heartbeat):
```

## Disable Xname Validation

In order to disable xname validation you need the docs-csm RPM installed and the
CSM 1.2.5 or newer tarball extracted somewhere on the node you are enabling it
from. In the command example below the CSM 1.2.5 tarball is extracted to
`/etc/cray/upgrade/csm/csm-1.2.5/tarball`.

Disabling xname validation requires the reinstallation of the spire server and
rejoining all nodes to spire. The `xnamevalidation.sh` script handles this for
NCNs and Storage nodes. Compute and UAN nodes will need to be restarted after
the `xnamevalidation.sh` script has finished running. If you do not restart
these nodes then they will be unable to acquire JWTs from spire.

### Example Commands

```bash
cd /etc/cray/upgrade/csm/csm-1.2.5/tarball/csm-1.2.5
/usr/share/doc/csm/scripts/operations/xnamevalidation.sh disable
```

### Example Output

```bash
ncn:/etc/cray/upgrade/csm/csm-1.2.5/tarball/csm-1.2.5 # /usr/share/doc/csm/scripts/operations/xnamevalidation.sh disable

Backup copy of the site-init secret has been saved to /tmp/tmp.HbfRHgiQzP/site-init.yaml
Stopping spire on NCNs
Warning: Permanently added 'ncn-s001,10.252.1.6' (ECDSA) to the list of known hosts.
[TRUNCATED]
Warning: Permanently added 'ncn-w004,10.252.1.7' (ECDSA) to the list of known hosts.
Uninstalling spire
release "spire" uninstalled
Waiting for all spire pods to be terminated.
Waiting for all spire pods to be terminated.
Waiting for all spire pods to be terminated.
No resources found in spire namespace.
Removing spire-server PVCs
persistentvolumeclaim "spire-data-spire-server-0" deleted
persistentvolumeclaim "spire-data-spire-server-1" deleted
persistentvolumeclaim "spire-data-spire-server-2" deleted
2022-03-29T18:27:14Z INF Initializing the connection to the Kubernetes cluster using KUBECONFIG (system default), and context (current-context) command=ship
2022-03-29T18:27:14Z INF Initializing helm client object command=ship
         |\
         | \
         |  \
         |___\      Shipping your Helm workloads with Loftsman
       \--||___/
  ~~~~~~\_____/~~~~~~~

2022-03-29T18:27:14Z INF Ensuring that the loftsman namespace exists command=ship
2022-03-29T18:27:15Z INF Loftsman will use the packaged charts at /etc/cray/upgrade/csm/csm-1.2.5/tarball/csm-1.2.5/helm as the Helm install source command=ship
2022-03-29T18:27:15Z INF Running a release for the provided manifest at /tmp/tmp.HbfRHgiQzP/manifest.yaml command=ship

~~~~~~~~~~~~~~~~~~~~~~~~~~~
Releasing spire v2.3.1
~~~~~~~~~~~~~~~~~~~~~~~~~~~

[TRUNCATED]
2022-03-29T18:27:20Z INF Recording log data to configmap loftsman-xnamevalidation-ship-log in namespace loftsman command=ship
deployment.apps/cray-opa-ingressgateway restarted
deployment.apps/cray-opa-ingressgateway-customer-admin restarted
deployment.apps/cray-opa-ingressgateway-customer-user restarted
secret/site-init configured
spire-server is not ready. Will retry after 30 seconds. (1/30)
[TRUNCATED]
spire-server is not ready. Will retry after 30 seconds. (6/30)
Enabling spire on NCNs
Warning: Permanently added 'ncn-m001,10.252.1.13' (ECDSA) to the list of known hosts.
ncn-s001 is being joined to spire.
[TRUNCATED]
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    86  100    54  100    32    716    424 --:--:-- --:--:-- --:--:--  1146
Warning: Permanently added 'ncn-s001,10.252.1.6' (ECDSA) to the list of known hosts.
ncn-s002 is being joined to spire.
[TRUNCATED]
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    86  100    54  100    32    819    485 --:--:-- --:--:-- --:--:--  1323
Warning: Permanently added 'ncn-s002,10.252.1.5' (ECDSA) to the list of known hosts.
ncn-s003 is being joined to spire.
[TRUNCATED]
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100    87  100    54  100    33    832    509 --:--:-- --:--:-- --:--:--  1359
Warning: Permanently added 'ncn-s003,10.252.1.4' (ECDSA) to the list of known hosts.
component name (xname) validation has been disabled.
```

### Validation

To validate that xname validation is disabled, request a test JWT using the
`heartbeat-spire-agent` command. The token shown will not include an xname.

```bash
ncn# /usr/bin/heartbeat-spire-agent api fetch jwt -socketPath=/root/spire/agent.sock -audience test | head -n1
token(spiffe://shasta/ncn/workload/heartbeat):
```
