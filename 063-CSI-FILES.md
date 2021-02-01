# Cray Site Init Files

This page describes administrative knowledge around CSI's files.

> Detailed information for collecting certain files starts in  [Service Guides](./300-SERVICE-GUIDES.md)
  
* [Save-File / Avoiding Parameters](#save-file--avoiding-parameters)
* [Shasta CFG](#shasta-cfg)
    * [LDAP](#ldap)
    * [Configuring Cray Datacenter LDAP](#configuring-cray-datacenter-ldap)
  * [Storing in GIT (VCS)](#storing-in-git-vcs)
* [CSI `hmn_connections.json` Notes](#csi-`hmn_connections.json`-notes)

<a name="save-file--avoiding-parameters"></a>
## Save-File / Avoiding Parameters

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

<a name="shasta-cfg"></a>
## Shasta CFG

Shasta Configs contain environment manifests for helmcharts and other deployment items through `customizations.yaml`.

A bare-bones shasta-cfg framework lives in the CSM tarballs:

- For new systems, follow the instructions at
   ```bash
   /mnt/pitdata/${CSM_RELEASE}/shasta-cfg/docs/NEW-SYSTEM.md
   ```
- Existing systems, follow
   ```bash
   /mnt/pitdata/${CSM_RELEASE}/shasta-cfg/docs/UPDATE-SYSTEM.md
   ```

<a name="ldap"></a>
#### LDAP

When using TLS for LDAP, update the `cray-keycloak` sealed secret value by supplying a **base64 encoded** form of your CA certificate(s). You can use the `keytool` command and a PEM-encoded form of your certificate(s) to obtain this value, as follows:

  ```bash
  linux# keytool -importcert -trustcacerts -file myad-pub-cert.pem -alias myad -keystore certs.jks -storepass password -noprompt
  linux# cat certs.jks | base64
  ```

<a name="configuring-cray-datacenter-ldap"></a>
#### Configuring Cray Datacenter LDAP

This is an **`INTERNAL`** process to configure our dev systems to use LDAP for users and groups.

Add or change the `keycloak_users_localize` sealed secret in the `customizations.yaml` file for the system:

```yaml
spec:
  kubernetes:
    sealed_secrets:
      keycloak_users_localize:
        generate:
          name: keycloak-users-localize
          data:
          - type: static
            args:
              name: ldap_connection_url
              value: ldap://172.30.79.134
```

Run `utils/secrets-seed-customizations.sh customizations.yaml` to generate the encrypted value.

Configure non-secret options by adding the following fields to the `cray-keycloak-users-localize` chart customizations:

```yaml
spec:
  kubernetes:
    services:
      cray-keycloak-users-localize:
        ldapSearchBase: "dc=datacenter,dc=cray,dc=com"
        localRoleAssignments:
        - {"group": "criemp", "role": "admin", "client": "shasta"}
        - {"group": "criemp", "role": "admin", "client": "cray"}
        - {"group": "craydev", "role": "admin", "client": "shasta"}
        - {"group": "craydev", "role": "admin", "client": "cray"}
        - {"group": "shasta_admins", "role": "admin", "client": "shasta"}
        - {"group": "shasta_admins", "role": "admin", "client": "cray"}
        - {"group": "shasta_users", "role": "user", "client": "shasta"}
        - {"group": "shasta_users", "role": "user", "client": "cray"}
```

<a name="storing-in-git-vcs"></a>
#### Storing in GIT (VCS)

If one is to store their SHASTA-CFG repository in git, it is a good practice to include the CSM release version in associated commit messages, e.g:

  ```bash
  linux# git commit -m "Updated to $(/mnt/pitdata/${CSM_RELEASE}/lib/version.sh)"
  linux# git push -u origin master
  ```

<a name="csi-`hmn_connections.json`-notes"></a>
### CSI `hmn_connections.json` Notes

If you see warnings from `csi config init` that are similar to the warning messages below, it means that CSI encountered an unknown piece of hardware in the `hmn_connections.json` file. If you do not see this message you can move on to sub-step 2.

```json
{"level":"warn","ts":1610405168.8705149,"msg":"Found unknown source prefix! If this is expected to be an Application node, please update application_node_config.yaml","row":{"Source":"gateway01","SourceRack":"x3000","SourceLocation":"u33","DestinationRack":"x3002","DestinationLocation":"u48","DestinationPort":"j29"}}
```

If the piece of hardware is expected to be an application node then [follow the procedure to create the application_node_config.yaml](308-APPLICATION-NODE-CONFIG.md) file. The argument `--application-node-config-yaml ./application-node-config.yaml` can be given to `csi config init` to include the additional application node configuration. Due to systems having system specific application node source names in `hmn_connections.json` (and the SHCD) the `csi config init` command will need to be given additional configuration file to properly include these nodes in SLS Input file.

