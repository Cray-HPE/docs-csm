# Prometheus log having prometheus-kafka-adapter errors during installation.

On a fresh install of CSM 1.3.1 the prometheus log has following example errors:

```bash
ts=2022-12-05T13:35:53.495Z caller=dedupe.go:112 component=remote level=warn remote_name=2eb187 url=http://prometheus-kafka-adapter.sma.svc.cluster.local:80/receive msg="Failed to send batch, retrying" err="Post \"http://prometheus-kafka-adapter.sma.svc.cluster.local:80/receive\": dial tcp: lookup prometheus-kafka-adapter.sma.svc.cluster.local on 10.16.0.10:53: no such host"
```

SMA has not been installed yet so this kafka service doesn't exist, due to this the above errors for retry are logged. Prometheus can operate without SMA kafka and it should periodically retry the connection to kafka. These errors will be logged until SMA is installed and can hence be disregarded.
