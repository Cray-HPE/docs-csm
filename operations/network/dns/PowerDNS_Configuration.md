# PowerDNS Configuration

* [External DNS](#external-dns)
    * [Site setup](#site-setup)
* [Authoritative zone transfer](#authoritative-zone-transfer)
    * [Configuration parameters](#configuration parameters)
        * [Primary server name](#primary-server-name)
        * [Secondary servers](#secondary-servers)
        * [Notify zones](#notify-zones)
    * [Example configuration for BIND](#example-configuration-for-bind)
* [DNS Security Extensions and zone transfer](#dns-security-extensions-and-zone-transfer)
    * [Zone signing](#zone-signing)
    * [Transaction signatures](#transaction-signatures)
        * [Example BIND configuration with TSIG key](#example-bind-configuration-with-tsig-key)

## External DNS

PowerDNS replaces the CoreDNS server that earlier versions of CSM used to provide external DNS services.

The `cray-dns-powerdns-cmn-tcp` and `cray-dns-powerdns-cmn-udp` `LoadBalancer` resources are configured to service external DNS requests using the IP address specified by the CSI `--cmn-external-dns` command line argument.

The CSI `--system-name` and `--site-domain` command line arguments are combined to form the subdomain used for external DNS.

### Site setup

(`ncn-mw#`) In the following example, the IP address `10.101.8.113` is used for external DNS and the system has the subdomain `system.dev.cray.com`

```bash
kubectl -n services get service -l app.kubernetes.io/name=cray-dns-powerdns
```

Example output:

```text
NAME                        TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)        AGE
cray-dns-powerdns-api       ClusterIP      10.24.24.29     <none>         8081/TCP       21d
cray-dns-powerdns-cmn-tcp   LoadBalancer   10.27.91.157    10.101.8.113   53:30726/TCP   21d
cray-dns-powerdns-cmn-udp   LoadBalancer   10.17.232.118   10.101.8.113   53:30810/UDP   21d
cray-dns-powerdns-hmn-tcp   LoadBalancer   10.31.228.190   10.94.100.85   53:31080/TCP   21d
cray-dns-powerdns-hmn-udp   LoadBalancer   10.24.134.53    10.94.100.85   53:31338/UDP   21d
cray-dns-powerdns-nmn-tcp   LoadBalancer   10.22.159.196   10.92.100.85   53:31996/TCP   21d
cray-dns-powerdns-nmn-udp   LoadBalancer   10.17.203.241   10.92.100.85   53:31898/UDP   21d
```

A system administrator would typically setup the subdomain `system.dev.cray.com` in their site DNS and create a record which points to the IP address `10.101.8.113` (for example `ins1.system.dev.cray.com`).

The administrator would then delegate queries to `system.dev.cray.com` to `ins1.system.dev.cray.com` making it authoritative for that subdomain allowing CSM to respond to queries for services like `grafana.system.dev.cray.com`

The specifics of how to configure to configuring DNS forwarding is dependent on the DNS server in use; consult the documentation provided by the DNS server vendor for more information.

## Authoritative zone transfer

In addition to responding to external DNS queries, PowerDNS can support replication of domain information to secondary servers via AXFR (Authoritative Zone Transfer) queries.

### Configuration parameters

Zone transfer is configured via `customizations.yaml` parameters and can also be configured at install time via CSI command line arguments.

#### Primary server name

* Parameter: `spec.network.dns.primary_server_name`
* CSI command line argument: `--primary-server-name`
* Default value: `primary`

This is the name of the PowerDNS server. This is combined with the system domain information to create the NS record for zones, for example:

```text
system.dev.cray.com.   1890   IN    NS   primary.system.dev.cray.com.
```

This record will also point to the external DNS IP address

```bash
dig +short primary.system.dev.cray.com
```

Example output:

```text
10.101.8.113
```

#### Secondary servers

* Parameter: `spec.network.dns.secondary_servers`
* CSI command line argument: `--secondary-servers`
* Default value: `""`

This is a comma-separated list of DNS servers to notify, each in the format `server_name/IP_address`. For example:

```text
externaldns1.my.domain/1.1.1.1,externaldns2.my.domain/2.2.2.2
```

If the default value is used, then no servers to notify on zone update will be configured.

#### Notify zones

* Parameter: `spec.network.dns.notify_zones`
* CSI command line argument: `--notify-zones`
* Default value: `""`

This is a comma-separated list of zones to transfer. For example:

```text
system.dev.cray.com,8.101.10.in-addr.arpa
```

If the default value is used, then PowerDNS will attempt to transfer all zones.

### Example configuration for BIND

This is an example configuration demonstrating how to configure BIND as a secondary server for zone transfer.

For other DNS servers, consult the documentation provided by the DNS server vendor.

```text
// This is the primary configuration file for the BIND DNS server named.
//
// Please read /usr/share/doc/bind9/README.Debian.gz for information on the
// structure of BIND configuration files in Debian, *BEFORE* you customize
// this configuration file.
//
// If you are just adding zones, please do that in /etc/bind/named.conf.local

include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.default-zones";
include "/etc/bind/named.conf.log";

zone "system.dev.cray.com" {
  type slave;
  masters { 10.101.8.113; };
  allow-notify { 10.101.8.8; 10.101.8.9; 10.101.8.10; };
  file "/var/lib/bind/db.system.dev.cray.com";
};

zone "can.system.dev.cray.com" {
  type slave;
  masters { 10.101.8.113; };
  allow-notify { 10.101.8.8; 10.101.8.9; 10.101.8.10; };
  file "/var/lib/bind/db.can.system.dev.cray.com";
};

zone "8.101.10.in-addr.arpa" {
  type slave;
  masters { 10.101.8.113; };
  allow-notify { 10.101.8.8; 10.101.8.9; 10.101.8.10; };
  file "/var/lib/bind/db.8.101.10.in-addr.arpa";
};
```

`masters` should be set to the CMN IP address of the PowerDNS service. This is typically defined at install time by the `--cmn-external-dns` CSI option.

`allow-notify` should contain the CMN IP addresses of all Kubernetes worker nodes.

## DNS Security Extensions and zone transfer

### Zone signing

The CSM implementation of PowerDNS supports the DNS Security Extensions (DNSSEC) and the signing of zones with a user-supplied zone signing key.

If DNSSEC is to be used for zone transfer, then the `dnssec` SealedSecret in `customizations.yaml` should be updated to include a `base64` encoded
version of the private key portion of the desired zone signing key.

1. (`ncn-mw#`) Save the zone signing private key to a file.

    Here is an example of a zone signing key:

    ```bash
    cat Ksystem.dev.cray.com.+013+63812.private
    ```

    Example output:

    ```text
    Private-key-format: v1.3
    Algorithm: 13 (ECDSAP256SHA256)
    PrivateKey: +WFrfooCjTtoRU5UfhrpuTL0IEm6hYc4YJ6u8CcYquo=
    Created: 20210817081902
    Publish: 20210817081902
    Activate: 20210817081902
    ```

1. (`ncn-mw#`) Encode the key using the `base64` utility.

    ```bash
    base64 Ksystem.dev.cray.com.+013+63812.private
    ```

    Example output:

    ```text
    UHJpdmF0ZS1rZXktZm9ybWF0OiB2MS4zCkFsZ29yaXRobTogMTMgKEVDRFNBUDI1NlNIQTI1NikK
    UHJpdmF0ZUtleTogK1dGcmZvb0NqVHRvUlU1VWZocnB1VEwwSUVtNmhZYzRZSjZ1OENjWXF1bz0K
    Q3JlYXRlZDogMjAyMTA4MTcwODE5MDIKUHVibGlzaDogMjAyMTA4MTcwODE5MDIKQWN0aXZhdGU6
    IDIwMjEwODE3MDgxOTAyCg==
    ```

1. (`ncn-mw#`) Populate the `dnssec.generate` block in `customizations.yaml` with the encoded key.

    > **IMPORTANT**
    >
    > * The name of the key in SealedSecret **must** match the name of the zone being secured.
    >     * In the below example, the zone name is `system.dev.cray.com`.
    > * If multiple zones are to be secured, then each zone should have its own entry, even if the same key is used.

    ```yaml
    spec:
      kubernetes:
        sealed_secrets:
          dnssec:
            generate:
              name: dnssec-keys
              data:
                - type: static_b64
                  args:
                    name: system.dev.cray.com
                    value: |
                      UHJpdmF0ZS1rZXktZm9ybWF0OiB2MS4zCkFsZ29yaXRobTogMTMgKEVDRFNBUDI1NlNIQTI1NikK
                      UHJpdmF0ZUtleTogK1dGcmZvb0NqVHRvUlU1VWZocnB1VEwwSUVtNmhZYzRZSjZ1OENjWXF1bz0K
                      Q3JlYXRlZDogMjAyMTA4MTcwODE5MDIKUHVibGlzaDogMjAyMTA4MTcwODE5MDIKQWN0aXZhdGU6
                      IDIwMjEwODE3MDgxOTAyCg==
    ```

### Transaction signatures

Transaction signatures (TSIG) provide a secure communication channel between a primary and secondary DNS server.
To configure TSIG, add the desired key to the `dnssec.generate` block in `customizations.yaml`.
Only a single transaction signing key is supported and that key is applied to all zones.

> **IMPORTANT** The key used for TSIG **must** have `.tsig` in the name and (unlike the zone signing key) it **should not** be `base64` encoded.

```yaml
spec:
  kubernetes:
    sealed_secrets:
      dnssec:
        generate:
          name: dnssec-keys
          data:
            - type: static_b64
              args:
                name: system.dev.cray.com
                value: |
                  UHJpdmF0ZS1rZXktZm9ybWF0OiB2MS4zCkFsZ29yaXRobTogMTMgKEVDRFNBUDI1NlNIQTI1NikK
                  UHJpdmF0ZUtleTogK1dGcmZvb0NqVHRvUlU1VWZocnB1VEwwSUVtNmhZYzRZSjZ1OENjWXF1bz0K
                  Q3JlYXRlZDogMjAyMTA4MTcwODE5MDIKUHVibGlzaDogMjAyMTA4MTcwODE5MDIKQWN0aXZhdGU6
                  IDIwMjEwODE3MDgxOTAyCg==
            - type: static
              args:
                name: system-key.tsig
                value:
                  name:      system-key
                  algorithm: hmac-sha256
                  key:       dnFC5euKixIKXAr6sZhI7kVQbQCXoDG5R5eHSYZiBxY=
```

#### Example BIND configuration with TSIG key

An example configuration demonstrating how to extend the previous BIND configuration example and add the TSIG key.

```text
key "system-key" {
        algorithm hmac-sha256;
        secret "dnFC5euKixIKXAr6sZhI7kVQbQCXoDG5R5eHSYZiBxY=";
};
# Primary server IP address (i.e., PowerDNS CMN ip)
server 10.101.8.113 {
        keys {
                system-key;
        };
};
```

For other DNS servers, consult the documentation provided by the DNS server vendor.
