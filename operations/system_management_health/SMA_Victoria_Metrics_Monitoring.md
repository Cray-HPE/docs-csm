# SMA Victoria Metrics Monitoring

SMA uses Victoria Metrics for storage. It deploys three components

- vminsert
- vmselect
- vmstorage

These components expose metrics that are scraped using a service scrape.

The service scrape configuration could be obtained using the following command

```yaml
kubectl get vmservicescrapes.operator.victoriametrics.com -n sysmgmt-health  cray-sysmgmt-health-sma-vm-metrics--exporter -o yaml
```

The metrics exposed are visualized in the SMA-VMcluster dashboard.
