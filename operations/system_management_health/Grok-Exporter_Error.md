# `grok-exporter` pod status showing as `ContainerStatusUnknown` Error

## Symptom

On CSM upgrade, the grok-exporter pod log has errors similar to the following:

```text
The node was low on resource: ephemeral-storage. Container grok-exporter was using 127200Ki, which exceeds its request of 0.
```

## Solution

This Kafka service does not exist, because the [System Monitoring Application (SMA)](../../glossary.md#system-monitoring-application-sma)
has not been installed yet. This causes the above errors for retry to be logged. VictoriaMetrics can operate without SMA Kafka and it will
periodically retry the connection to Kafka. These errors will be logged until SMA is installed. Therefore, if they are seen before SMA is
installed, then disregard them.

The root file system on master is at more than 80% but keeps hitting the threshold to raise `NodeHasDiskPressure`(85%) which causes the
node to then attempt to reclaim ephemeral-storage.

Increase/clean the root filesystem and delete the grok exporter pod as follows:

```bash
kubectl delete pod -l app=grok-exporter -n sysmgmt-health
```
