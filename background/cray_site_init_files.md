# Cray Site Init Files

This page describes administrative knowledge around the pre-config files to `csi` or the output files from `csi`.

> Information for collecting certain files starts in [Configuration Payload](../install/prepare_configuration_payload.md#configuration_payload) 

   * [`application_node_config.yaml`](../install/prepare_configuration_payload.md#application_node_config_yaml)
   * [`cabinets.yaml`](../install/prepare_configuration_payload.md#cabinets_yaml)
   * [`hmn_connections.json`](../install/prepare_configuration_payload.md#hmn_connections_json)
   * [`ncn_metadata.csv`](../install/prepare_configuration_payload.md#ncn_metadata_csv)
   * [`switch_metadat.csv`](../install/prepare_configuration_payload.md#create_switch_metadata_csv)

### Topics: 
  
   * [Save-File / Avoiding Parameters](#save-file--avoiding-parameters)

## Details

<a name="save-file--avoiding-parameters"></a>
### Save-File / Avoiding Parameters

A `system_config.yaml` file may be provided by the administrator that will omit the need for specifying parameters on the command line.

> This file is dumped in the generated configs after every `csi config init` call, the new dumped file
serves as a fingerprint for re-generated the same configs.

Here is an example file

```yaml
bgp-asn: "65533"
bootstrap-ncn-bmc-pass: admin
bootstrap-ncn-bmc-user: admin
can-bootstrap-vlan: 7
can-cidr: 10.102.9.0/24
can-dynamic-pool: 10.102.9.128/25
can-gateway: 10.102.9.20
can-external-dns: 10.102.9.113
can-gw: 10.102.9.20
can-static-pool: 10.102.9.112/28
ceph-cephfs-image: dtr.dev.cray.com/cray/cray-cephfs-provisioner:0.1.0-nautilus-1.3
ceph-rbd-image: dtr.dev.cray.com/cray/cray-rbd-provisioner:0.1.0-nautilus-1.3
chart-repo: http://helmrepo.dev.cray.com:8080
docker-image-registry: dtr.dev.cray.com
help: false
hill-cabinets: 0
hmn-bootstrap-vlan: 4
hmn-cidr: 10.254.0.0/17
hmn-connections: hmn_connections.json
hsn-cidr: 10.250.0.0/16
install-ncn: ncn-m001
install-ncn-bond-members: p801p1,p801p2
ipv4-resolvers: 8.8.8.8, 9.9.9.9
management-net-ips: 0
manifest-release: ""
mountain-cabinets: 0
mtl-cidr: 10.1.1.0/16
ncn-metadata: ncn_metadata.csv
nmn-bootstrap-vlan: 2
nmn-cidr: 10.252.0.0/17
ntp-pool: time.nist.gov
river-cabinets: 1
rpm-repository: https://packages.nmn/repository/shasta-master
site-dns: 172.30.84.40
site-domain: dev.cray.com
site-gw: 172.30.48.1
site-ip: 172.30.53.153/20
site-nic: em1
starting-hill-cabinet: 9000
starting-mountain-cabinet: 5000
starting-mountain-nid: 1000
starting-river-cabinet: 3000
starting-river-nid: 1
supernet: true
switch-metadata: switch_metadata.csv
system-name: redbull
upstream_ntp_server: time.nist.gov
v2-registry: https://registry.nmn/
```
