# LiveCD - Metal Basecamp
Metal Basecamp is a cloud-init DataSource available on the LiveCD. Basecamp's configuration file offers many inputs for various cloud-init scripts baked into the NCN images.

This page details what those settings are.

* [Basecamp](#basecamp)
  * [Config Files](#config-files)
  * [Purging Basecamp](#purging-basecamp)
* [CAN](#can)
* [CEPH](#ceph)
    * [Certificate Authority](#certificate-authority)
    * [RADOS Gateway](#rados-gateway)
    * [Wiping](#wiping)
* [DNS](#dns)
        * [Resolution Configuration](#resolution-configuration)
        * [Static Fallback](#static-fallback)
* [Kubernetes](#kubernetes)
* [NTP](#ntp)
* [Node Auditing](#node-auditing)


**Generally these settings are determined by the cray-site-init tool.** See `csi config --help` for more information. Manual adjustments typically are for debug and development.

<a name="basecamp"></a>
## Basecamp

<a name="config-files"></a>
### Config Files

- The cloud-init configuration file is located at `/var/www/ephemeral/configs/data.json.`
- The basecamp server configuration file is located at `/var/www/ephemeral/configs/server.yaml`
- The static artifact directory served by basecamp can be leveraged at `/var/www/ephemeral/static`

> **`NOTE`** The `jq` tool is provided on the LiveCD to facilitate viewing JSON files like these.

<a name="purging-basecamp"></a>
### Purging Basecamp

If the desire to reset basecamp to defaults comes up, you can do so by following these commands.

```bash
pit# systemctl stop basecamp
pit# podman rm basecamp
pit# podman rmi basecamp
pit# rm -f /var/www/ephemeral/configs/server.yaml
pit# systemctl start basecamp
```

Basecamp is now entirely fresh.

<a name="can"></a>
## CAN

Customer Access Network.

---
Key: `can-gw`

data:
```json
{
  // ...
  "can-gw": "10.102.9.20",
  // ...
}
```
---

Key: `can-if`

data:
```json
{
  // ...
  "can-if": "vlan007",
  // ...
}
```
---

<a name="ceph"></a>
## CEPH

---
Key: `num_storage_nodes`

data:
```json
{
  // ...
  "num_storage_nodes": "3",
  // ...
}
```
---

<a name="certificate-authority"></a>
### Certificate Authority

---
Key: `ca-certs`

data:
```json
{
  // ...
  "ca-certs": {"remove-defaults":false,"trusted":["-----BEGIN CERTIFICATE-----\nM,"]}
  // ...
}
```
---

<a name="rados-gateway"></a>
### RADOS Gateway

---
Key: `rgw-virtual-ip`

data:
```json
{
  // ...
  "rgw-virtual-ip": "10.252.1.3",
  // ...
}
```
---

<a name="wiping"></a>
### Wiping

---
Key: `wipe-ceph-osds`

data:
```json
{
  // ...
  "k8s_virtual_ip": "10.252.1.2",
  // ...
}
```
---

<a name="dns"></a>
## DNS

cloud-init modifications to DNS.

<a name="resolution-configuration"></a>
#### Resolution Configuration

Paves over bootstrap provisions by adjusting `/etc/sysconfig/network/config` to match the `dns-server` value.
Updates `/etc/resolv.conf` by invoking `netconfig update -f`.

> script: `/srv/cray/scripts/metal/set-dns-config.sh`

---

Key: `dns-server`

data:
```json
{
  // ...
  "dns-server": "10.92.100.225 10.252.1.4",
  // ...
}
```
---
Key: `domain`

data:
```json
{
  // ...
  "domain": "nmn hmn",
  // ...
}
```
---

<a name="static-fallback"></a>
#### Static Fallback

Safety-net script for installing static-fallback resolution when Kubernetes is offline.

> script: `/srv/cray/scripts/metal/set-host-records.sh`

Key: `host_records`

data:

```json
{
  // ...
  "host_records": [
      {
        "aliases": [
          "ncn-s003.nmn",
          "ncn-s003"
        ],
        "ip": "10.252.1.4"
      },
      {
        "aliases": [
          "ncn-s003.mtl"
        ],
        "ip": "10.1.1.2"
      },
      {
        "aliases": [
          "ncn-s003.hmn",
          // ...
  // ...
}
```
<a name="kubernetes"></a>
## Kubernetes

---
Key: `k8s_virtual_ip`

data:
```json
{
  // ...
  "k8s_virtual_ip": "10.252.1.2",
  // ...
}
```
---

---
Key: `first_master_hostname`

data:
```json
{
  // ...
  "first_master_hostname": "ncn-m002",
  // ...
}
```
---

<a name="ntp"></a>
## NTP

cloud-init modifications to NTP. 

> script: `/srv/cray/scripts/metal/set-ntp-config.sh`
---
Key: `ntp_peers`

data:
```json
{
  // ...
  "ntp_peers": "ncn-m003 ncn-w001 ncn-s001 ncn-s002 ncn-s003 ncn-m002 ncn-w003 ncn-m001 ncn-w002",
  // ...
}
```
---
Key: `ntp_local_nets`

data:
```json
{
  // ...
  "ntp_local_nets": "10.252.0.0/17 10.254.0.0/17",
  // ...
}
```
---
Key: `upstream_ntp_server`

> **`WARNING`** at this time, multiple upstream-NTP servers can not be specified.

data:
```json
{
  // ...
  "upstream_ntp_server": "time.nist.gov",
  // ...
}
```
---

<a name="node-auditing"></a>
## Node Auditing

---
Key: `ncn-mgmt-node-auditing-enabled`

data:
```json
{
  // ...
  "ncn-mgmt-node-auditing-enabled": false,
  // ...
}

---
