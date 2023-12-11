# Known Issue: RTS fails to restart after a worker node has been rebooted

After a system has been running a while and a worker node is rebooted either due to maintenance or
failure, any RTS pod that is running on that worker node may not properly start up.

1. (`ncn-mw#`) Check current status of RTS.

```bash
kubectl get pods -n services | egrep rts | egrep -v Running
```
```text
services         cray-hms-rts-744577c9b5-fs287                 0/3     Init:0/2           0                 45m
services         cray-hms-rts-snmp-776695546-thxlb             0/3     Init:0/2           0                 45m
```

The RTS pods are looking for the `cray-hms-rts-init` job that indicates the prerequisites are ready
but that job no longer exists because it has been cleaned up.

## Fix

1. (`ncn-mw#`) Generate a RTS init yaml from the manifest.

```bash
helm get manifest -n services cray-hms-rts | yq4 ea 'select(.kind == "Job")' > cray-hms-rts-init.yaml
```

1. (`ncn-mw#`) Apply the RTS init yaml to get it created.

```bash
kubectl apply -n services -f cray-hms-rts-init.yaml
```

1. (`ncn-mw#`) Wait for the RTS init job to complete.

```bash
while [ -z "$DONT_WAIT" -a "`kubectl get jobs -n services cray-hms-rts-init \
-o jsonpath='{.status.conditions[0].type}'`" != "Complete" ]; do \
echo "Waiting for cray-hms-rts-init to complete"; sleep 3;  done; echo "Completed";
```

```text
Waiting for cray-hms-rts-init to complete
Waiting for cray-hms-rts-init to complete
Waiting for cray-hms-rts-init to complete
Waiting for cray-hms-rts-init to complete
Waiting for cray-hms-rts-init to complete
Waiting for cray-hms-rts-init to complete
Waiting for cray-hms-rts-init to complete
Waiting for cray-hms-rts-init to complete
Waiting for cray-hms-rts-init to complete
Waiting for cray-hms-rts-init to complete
Waiting for cray-hms-rts-init to complete
Waiting for cray-hms-rts-init to complete
Waiting for cray-hms-rts-init to complete
Waiting for cray-hms-rts-init to complete
Completed
```

1. (`ncn-mw#`) Check to make sure RTS has properly been started.

```bash
kubectl get pods -n services | egrep rts
```

```text
cray-hms-rts-dbbc87df4-rzrgl                                      3/3     Running            0                 4m20s
cray-hms-rts-init-vctgv                                           0/2     Completed          0                 104s
cray-hms-rts-snmp-776695546-zh4k4                                 3/3     Running            0                 24h
```
