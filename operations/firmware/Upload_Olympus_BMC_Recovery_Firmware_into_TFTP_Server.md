# Upload BMC Recovery Firmware into TFTP Server

`cray-upload-recovery-images` is a utility for uploading the BMC recovery files for `ChassisBMCs`, `NodeBMCs`, and `RouterBMCs` to be served by the `cray-tftp` service.
The tool uses the `cray` CLI (`fas`, `artifacts`) and `cray-tftp` to download the S3 recovery images (as remembered by FAS), then upload them into the PVC that is used by `cray-tftp`.
`cray-upload-recovery-images` should be run on every system.

## CSM v1.5 Issue

In CSM 1.5.0 the `cray-tftp-upload` script errors out because of a change to the `ipxe` pods and the TFTP repository.
This is expected to be fixed in CSM 1.5.1.

If you receive the following type of error please apply the workaround:

```text
Uploading file: curr.json
error: source and destination are required
Failed to upload curr.json - error code = 0
```

***Workaround:*** Edit the script `/usr/local/bin/cray-tftp-upload` Changing this line:

```bash
PVC_HOST=`kubectl get pods -n services -l app.kubernetes.io/instance=cms-ipxe -o custom-columns=NS:.metadata.name --no-headers`
```

To:

```bash
PVC_HOST=`kubectl get pods -n services -l app.kubernetes.io/instance=cms-ipxe -o custom-columns=NS:.metadata.name --no-headers | head -1`
```

## Prerequisites

* Cray System Management (CSM) software is installed.
* The Cray Command Line Interface (CLI) tool is initialized and configured on the system.
* Firmware is loaded into FAS as part of the HPC Firmware Pack (HFP) install; refer to the *HPE Cray EX System HPC Firmware Pack Install Guide* on the HPE Customer Support Center for more information.

## Procedure

1. Execute the `cray-upload-recovery-images` script.

  ```bash
  cray-upload-recovery-images
  ```

  ```text
  Attempting to retrieve ChassisBMC .itb file
  s3:/fw-update/d7bb5be9eecc11eab18c26c5771395a4/cc-1.3.10.itb
  d7bb5be9eecc11eab18c26c5771395a4/cc-1.3.10.itb

  Uploading file: /tmp/cc.itb
  Defaulting container name to cray-ipxe.
  Successfully uploaded /tmp/cc.itb!
  removed /tmp/cc.itb
  ChassisBMC recovery image upload complete
  ========================================
  Attempting to retrieve NodeBMC .itb file
  s3:/fw-update/d81157f7eecc11ea943d26c5771395a4/nc-1.3.10.itb
  d81157f7eecc11ea943d26c5771395a4/nc-1.3.10.itb

  Uploading file: /tmp/nc.itb
  Defaulting container name to cray-ipxe.
  Successfully uploaded /tmp/nc.itb!
  removed /tmp/nc.itb
  NodeBMC recovery image upload complete
  ========================================
  Attempting to retrieve RouterBMC .itb file
  s3:/fw-update/d85398f2eecc11ea94ff26c5771395a4/rec-1.3.10.itb
  d85398f2eecc11ea94ff26c5771395a4/rec-1.3.10.itb

  Uploading file: /tmp/rec.itb
  Defaulting container name to cray-ipxe.
  Successfully uploaded /tmp/rec.itb!
  removed /tmp/rec.itb
  RouterBMC recovery image upload complete
  ```
