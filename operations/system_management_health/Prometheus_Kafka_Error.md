# `prometheus-kafka-adapter` errors during installation

## Symptom

On a fresh install of CSM, the Prometheus log has errors similar to the following:

```text
ts=2022-12-05T13:35:53.495Z caller=dedupe.go:112 component=remote level=warn remote_name=2eb187 
url=http://prometheus-kafka-adapter.sma.svc.cluster.local:80/receive msg="Failed to send batch, retrying"
err="Post \"http://prometheus-kafka-adapter.sma.svc.cluster.local:80/receive\": 
dial tcp: lookup prometheus-kafka-adapter.sma.svc.cluster.local on 10.16.0.10:53: no such host"
```

## Explanation

This Kafka service does not exist, because SMA has not been installed yet. This causes the above errors for retry to be logged.
Prometheus can operate without SMA Kafka and it will periodically retry the connection to Kafka.
These errors will be logged until SMA is installed. Therefore, if they are seen before SMA is installed,
then disregard them.
