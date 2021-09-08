

## Install HPC Firmware Pack (HFP)

Copyright 2021 Hewlett Packard Enterprise Development LP

### Prerequisites

1. Nexus must be installed and functioning.

2. The firmware tarball must be untarred and the ./install.sh script run to get the contents uploaded to Nexus.

**NOTE:** The ``ncn`` hostname is used as a generic placeholder for the node where these steps are run.

### Procedure

```bash
ncn# cd [path to location of tarballs]/os
ncn# ls -lh
total 58G
-rw-r--r-- 1 root root 894M Feb 6 17:25 firmware-0.0.0.tar.gz

ncn# tar -zxf firmware-0.0.0.tar.gz
ncn# cd firmware-0.0.0
ncn# ./install.sh
Install firmware-0.0.0
Load install tools
Configure Nexus
Creating file blobstore: firmware... 500 FAIL <-- expected
Updating file blobstore: firmware... 204 OK updated
Creating raw/hosted repository: firmware-0.0.0-0...201 OK created
Creating raw/group repository: firmware...201 OK created
Upload repository firmware-0.0.0-0
...
Clean up install tools
Untagged: docker.io/library/cray-nexus-setup:firmware-0.0.0-0
Deleted: 2c196c0c6364d9a1699d83dc98550880dc491cc3433a015d35f6cab1987dd6da
OK firmware-0.0.0-0
```

**NOTE:** The FAS Loader job will run automatically. It takes approximately 2-4 minutes to run. Use the FAS CLI to view what is available.
