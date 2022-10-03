# Known Issue: Velero Version Mismatch

In CSM 1.3 the Velero client and server versions differ after CSM is installed. This is not known to cause any problems with backup and restore functionality, but this page will document how to correct this situation if needed.

```text
ncn-m001:~ # velero version
Client:
        Version: v1.5.2
        Git commit: e115e5a191b1fdb5d379b62a35916115e77124a4
Server:
        Version: v1.6.3
```

## Fix

Run the following command on master and worker nodes to deploy the `v1.6.3` version of the Velero client:

   1. (`ncn-mw#`) Install the `v1.6.3` version of the Velero client:

       ```bash
       tar -xzf /srv/cray/tmp/velero-v1.6.3-linux-amd64.tar.gz -O "velero-v1.6.3-linux-amd64/velero" > /usr/bin/velero
       ```

   1. (`ncn-mw#`) Verify the versions now match:

       ```bash
       velero version
       ```

       Example output:

       ```text
       Client:
               Version: v1.6.3
               Git commit: 5fe3a50bfddc2becb4c0bd5e2d3d4053a23e95d2
       Server:
               Version: v1.6.3
       ```

Velero client and server versions should now match.
