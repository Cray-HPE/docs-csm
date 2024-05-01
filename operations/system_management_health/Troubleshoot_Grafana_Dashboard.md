# Troubleshoot Grafana Dashboard

General Grafana dashboard troubleshooting topics

- [Ceph - OSD Overview Dashboard](#ceph---osd-overview-dashboard-3-panels-not-found)
- [Ceph - RBD Overview Dashboard](#ceph---rbd-overview-dashboard-no-data)
- [Ceph - RGW Instance Detail Dashboard](#ceph---rgw-instance-detail-dashboard-panel-missing-and-no-data)
- [Ceph - RGW Overview Dashboard](#ceph---rgw-overview-dashboard-no-data)

## Ceph - OSD Overview Dashboard: 3 panels not found

This means that the `cray-sysmgmt-health` pie chart plugin is not installed.
If the system is not airgapped, then it can be installed by commenting out or removing the plugins property in `customizations.yaml`.
This will be fixed in a future release.

(`ncn-mw#`) Command to extract `customizations.yaml` from the `site-init` secret.

```bash
kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > customizations.yaml
```

Example:

```yaml
cray-sysmgmt-health:
          grafana:
            externalAuthority: grafana.cmn.{{ network.dns.external }}
            plugins: ""
```

In the above section, comment or delete the `plugins` line in order to install the pie chart plugin.

(`ncn-mw#`) Upload `customizations.yaml` file to Kubernetes so that the changes persist.

```bash
kubectl delete secret -n loftsman site-init
kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
```

## Ceph - RBD Overview Dashboard: No Data

This means that the Grafana dashboard is not getting any `ceph_rbd_*` metrics from the Ceph exporter.
This will be fixed in a future release.

## Ceph - RGW Instance Detail Dashboard: Panel missing and no data

Ceph - RGW Instance Detail Dashboard uses a 30 second time range in queries, which is a very short duration. Because of this, the dashboard is unable to load the data.
This will be fixed in a future release.

## Ceph - RGW Overview Dashboard: No data

Ceph - RGW Overview Dashboard uses a 30 second time range in queries, which is a very short duration. Because of this, the dashboard is unable to load the data.
This will be fixed in a future release.
