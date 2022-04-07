# Troubleshoot forward-zone DNS issues

Troubleshoot issues when DNS is not properly configured use unbound for validating, recursive, caching DNS.

Unbound is a free, open source validating, recursive, caching DNS resolver software under the BSD license. It is a recently developed DNS System that came into the DNS space to bring a fast and lean system that incorporates modern features based on open standards. Let us look at the features that Unbound has to offer.

### Features of Unbound

* Security and privacy: Unbound supports DNS-over-TLS which allows clients to encrypt their communication. Moreover, it supports various modern standards that limit the amount of data exchanged with authoritative servers. These modern standards include Query Name Minimization, the Aggressive Use of DNSSEC-Validated Cache and support for authority zones, which can be used to load a copy of the root zone.
* Support for recursive functionality only: Unbound can only be used as a recursive name server hence cannot be implemented for scenarios where an authoritative name server is needed. This makes Unbound great for caching and resolving hosts on your own Local Area Network.


### Issue found

When DNS forwarder hangs or is offline, all dns lookups hangs since at Cray/HPE we don't do fqdn requests.

### Procedure to fix


1. Confirm that DNS is configured properly.

    Run the following command from the server presenting issues.

     ```bash
    kubectl get cm -n services cray-dns-unbound -o yaml|grep forward
    <EMPTY>
    ```

    If an IP address is returned, DNS is configured properly and the remaining steps in this procedure can be skipped. If an IP address is not returned, proceed to the next step.


2. Use the IP address to direct DNS requests directly to the `cray-dns-unbound` service.

    Replace the example IP address (172.30.84.40) with IP of service that require fqdn.
    This change must be implemented to the `cray-dns-unbound` service. 
    ```bash
    forward-zone:
        name: .
        forward-addr: 172.30.84.40
    ```

3. After this implementation FQDN will be correctly resolved and no more hangs will happen.

    Below is an example of full code of `cray-dns-unbound` service.

```
ncn-m001:~ # kubectl get cm -n services cray-dns-unbound -o yaml
apiVersion: v1
binaryData:
  records.json.gz: H4sIAC3HTGIC/72a647bNhSEX2Xh3xFBUve+SlEYsqxohdiyIWnXWRR999ptEqQFOUMdWsm/IPnOZc6Qlij+/ufu9TIvY3Pudr+97JrrkPS3ZO6m96Htdp9edsM1aY7HqZvnx78brepMGa1VaXZ/fXpZT9tAOhnPozpd2uYUFwfF+LeTKiqGRTH2/W0v15LSfg3aZkzm27C0r4lR9784eaOtypSFtCV06qCn5iNZPi9X1HKhAahez+PpIMdHP269+PHSfummZOr6YV6mDzivlOK8hZAgtBF/kP33IEEGjA3jr6b7unTT2JyS4zgDHxUGo8SGLvxe9nBJhrF//O++Wbpb87F2FbpiJKIdxR+JW2VlPOqa0HgBJg6NxJ3siPTl7dA9duL3wb2X2PzOujawn0BinAzDdwE8mTOe2e+ToMJHb24PPLZjctbaAKp+NpVgeY0GKBbXZAA99+cFsSliF/dQ7pgqAYfnUW9BKrm6Sq4uNS6qWKiukmpkAVU9myJuB1Uys1uAMrMbxIJxFIDD46i2IJVYXCUXl3odFSwUV0klSgFVPpsiXgdVMq9rgBKv1wgF08gBh6dRbkEqsbZKri21OipYKK4SSTTjx5Hi2RSxOqiSWL0CJHF6uREK5pgBDs+x2IJU4qko8VToGkH1CrVVUoXQQ0z+bIqsEVAlWSOIJEZH5aJhpIDDw8i3IJVYWiWWlhod1SvUVkkVQk8w2bMpYnRQJTE6ykmMniIUDMMCDg8j24JUYmmVWFpqdMQKtVUihW74+cX3FhOBscObFKDkZEwDlL3P1luxYJoGFYzHCRWWo0o+HCUfDl0usGSpwkosE3qa8R2MRGBsxYBC2VtxBVDm+hKxYCY14MhIzCaokuur5Ppy06OShQIrsUrowQasMinGPA8KZZ4vAMo8nyMWjKQCHBmJ3gRVcn2VXF/ueVSyUGAlUGk46scf9lNqAct2JGv8LJusdWxJ16b90vTdvPZ7Zywnuy9zPcxJezmf4b2dR7PW9R7yfxrK5Y3AU1sIkqxueP+oey/t+j80WU1hMSTK7aXKBVdO8NXC4ws2fpv+uBQjMvnU38g1gtQLrX/5DAMLKVj5Qbargy7xPucC54/5dOmTpu+DbgzaiBA2JMTdIs1ymSKK+BYh4OJLWBx+7cURZz69Ted2OR0DtsU8ACebIwqxj6sgeJMJCiJr43gI0bHgNJERRNhH5Q8WMSTG+h6uw7T6+uk/kGyjnm/JqWs+J+hUS7v23J9AuH1S2P9sS1Gkrg++azV2pF2LSdIvo1HDjMUdY9oCMsUk6ZjRqGPG4o4d9ONKcsjvo+tSMmf9F5qX4dyt/5gRQBUiqhJRtYhyvTOHYFaGycR3neAGYKWfAjsunTdliwi2imDrCBb5gMM2BtYxcBoB+/yx+iUmgCpElFeb9df4QjBhkZUMkwlpZZKAGuHTIpk4ZYsIFk2fwzYGjio7RmsTI7aNEcxX9cov25RJBUwuYAoBI9GgFjClgPGuhpWXyb4z6OcBj5aQqZjMxWQhJisxWYvJUkwiExDUZ4XVN1ACqFxElSKqElFeIdd/aw3AalkyK8IKPyW54hTM5hFsGcFWESyygehbfzBcxyS2EbDDHm/NkJyb9v3UjMlhGo49On/MnPz+G79/Dk9PMMOi4DNMZ4yRXx2ztQdk3+ddCcfD5W08otMea/NfxFnK8c8dkKYfOZz011Rr3erZmINm9xgIPuqVm8Fz4JwWnmMapt6KLWnVKaZh5mwjtj7olWv3B8rtlUIa1lxvglpzMKjdHKMwrdUQtsgYJUZxXgPhFPWL86Y4r4VwhvoFI0oL6MgSk8SRhIb9FhuxfBkZSMPE1SYo36BrCMO85SZoCV1lakiyAWEa/xDabdiaV11CGmc2cewffwMj69S0H0sAAA==
data:
  unbound.conf: |-
    server:
        module-config: "iterator"
        chroot: ""
        interface: 127.0.0.1
        interface: 0.0.0.0
        port: 5053
        so-reuseport: yes
        do-ip6: no
        do-daemonize: no
        use-syslog: no
        logfile: ""
        access-control: 127.0.0.1/32 allow
        num-threads: 2
        verbosity: 0
        log-queries: no
        statistics-interval: 0
        statistics-cumulative: no
        # Minimum lifetime of cache entries in seconds
        cache-min-ttl: 180
        # Maximum lifetime of cached entries
        cache-max-ttl: 3600
        prefetch: yes
        prefetch-key: yes
        # Optimisations
        msg-cache-slabs: 2
        rrset-cache-slabs: 2
        infra-cache-slabs: 2
        key-cache-slabs: 2
        # increase memory size of the cache
        rrset-cache-size: 1024m
        msg-cache-size: 512m
        infra-cache-numhosts: 1000000
        # increase buffer size so that no messages are lost in traffic spikes
        so-rcvbuf: 8m
        so-sndbuf: 8m
        # Faster UDP with multithreading (only on Linux).
        so-reuseport: yes
        # Set this to no for compatibility with PBSPro which requires deterministic ordering of rrsets.
        rrset-roundrobin: no

        local-data: "health.check.unbound A 127.0.0.1"
        local-data-ptr: "127.0.0.1 health.check.unbound"
        include: /etc/unbound/records.conf
        access-control: 10.0.0.0/8 allow
        access-control: 127.0.0.0/8 allow

        local-zone: "local" static
        local-zone: "nmn." static
        local-zone: "hmn." static

    forward-zone:
        name: .
        forward-addr: 172.30.84.40
kind: ConfigMap
metadata:
  creationTimestamp: "2022-04-05T22:48:13Z"
  labels:
    app.kubernetes.io/instance: cray-dns-unbound
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: cray-dns-unbound
    helm.sh/chart: cray-dns-unbound-0.4.12
  managedFields:
  - apiVersion: v1
    fieldsType: FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          .: {}
          f:meta.helm.sh/release-name: {}
          f:meta.helm.sh/release-namespace: {}
    manager: Go-http-client
    operation: Update
    time: "2022-03-11T23:08:39Z"
  - apiVersion: v1
    fieldsType: FieldsV1
    fieldsV1:
      f:binaryData:
        .: {}
        f:records.json.gz: {}
      f:data:
        .: {}
        f:unbound.conf: {}
      f:metadata:
        f:labels:
          .: {}
          f:app.kubernetes.io/instance: {}
          f:app.kubernetes.io/managed-by: {}
          f:app.kubernetes.io/name: {}
          f:helm.sh/chart: {}
    manager: kubectl-replace
    operation: Update
    time: "2022-03-11T23:17:27Z"
  name: cray-dns-unbound
  namespace: services
  resourceVersion: "24024797"
  selfLink: /api/v1/namespaces/services/configmaps/cray-dns-unbound
  uid: a990f5cf-bd42-46c4-b071-a8087e501941
ncn-m001:~ # 
```