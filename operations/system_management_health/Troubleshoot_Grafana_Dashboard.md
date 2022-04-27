# Troubleshoot Grafana Dashboard

General Grafana dashboard troubleshooting topics
  - [Ceph - OSD Overview Dashboard](#ceph-osd-overview-dashboard)
  - [Ceph - RBD Overview Dashboard](#ceph-rbd-overview-dashboard)
  - [Ceph - RGW Instance Detail Dashboard](#ceph-rgw-instance-detail-dashboard)
  - [Ceph - RGW Overview Dashboard](#ceph-rgw-overview-dashboard)

<a name="ceph-osd-overview-dashboard"></a>
## Ceph - OSD Overview Dashboard: 3 panels not found

Currently skipping cray-sysmgmt-health pie chart plugin installation for airgapped systems. If the system is non airgapped then comment out or remove plugins property in customizations.yaml.
This will be fixed in a future release.

Command to extract customizations.yaml from the site-init secret.

```bash
ncn-m001# kubectl -n loftsman get secret site-init -o jsonpath='{.data.customizations\.yaml}' | base64 -d - > customizations.yaml
```

Example for airgapped systems (please uncomment plugins property):

```bash
cray-sysmgmt-health:
          grafana:
            externalAuthority: grafana.cmn.{{ network.dns.external }}
            # Skip plugin installation for airgapped systems.
            # If the system is non airgapped then you can comment out or remove plugins property.
            plugins: ""
```

Example for non-airgapped systems (please comment out plugins property):

```bash
cray-sysmgmt-health:
          grafana:
            externalAuthority: grafana.cmn.{{ network.dns.external }}
            # Skip plugin installation for airgapped systems.
            # If the system is non airgapped then you can comment out or remove plugins property.
            # plugins: ""
```

Commands to reupload customizations.yaml file to Kubernetes so that the changes persist.

```bash
ncn-m001# kubectl delete secret -n loftsman site-init
ncn-m001# kubectl create secret -n loftsman generic site-init --from-file=customizations.yaml
```


<a name="ceph-rbd-overview-dashboard"></a>
## Ceph - RBD Overview Dashboard: No Data

Grafana dashboard not getting any ceph_rbd_* metrics from ceph exporter.
Currently, either ceph exporter or node exporter not collecting ceph_rbd* metrics (RBD rados block device) which are using in this dashboard. This will be fixed in a future release.


<a name="ceph-rgw-instance-detail-dashboard"></a>
## Ceph - RGW Instance Detail Dashboard: Panel missing and no data

Currenlty Ceph - RGW Instance Detail Dashboard using 30 seconds time range in queries which is very short duration. Due to this the dashboard is unable to load the data.
The Grafana dashboard will be fixed in future release and before that pie chart plugin issue for workload breakdown panel need to be fixed. This will also be fixed in future release.


<a name="ceph-rgw-overview-dashboard"></a>
## Ceph - RGW Overview Dashboard: No data

Currenlty Ceph - RGW overview Dashboard using 30 seconds time range in queries which is very short duration. Due to this the dashboard is unable to load the data.
The Grafana dashboard will be fixed in future release.

