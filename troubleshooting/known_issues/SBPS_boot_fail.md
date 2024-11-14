# Boot content projection services can fail if an image does not have an `etag`

## Issue Description

iSCSI based boot content projection which is also known as "Scalable Boot Content Projection" (SBPS) for `rootfs` and `PE` images
is supported in CSM 1.6.0. SBPS fails if the `rootfs` image manifest to be projected doesn't have an `etag` field or the `etag` field
is present but set to NULL. Due to this problem with `etags`, the SBPS core service, the `SBPS Marshal agent`, crashes.

## Issue Identification

Issue can be identified with the symptoms below:

Compute/UAN node (iSCSI Initiator) boot fails with the following messages in the console log:

```text
2024-11-12T20:07:50.17117 [  100.620313] dracut-pre-mount[3827]: iscsiadm: No active sessions.
2024-11-12T20:13:00.44921 [  402.905538] dracut-pre-mount[5379]: ls: cannot access '/dev/mapper/594b7c79-9cb5-48f6-bceb-18f3596f0dbb_rootfs': No such file or directory
2024-11-12T20:13:00.44925 [  402.924254] dracut-pre-mount[3814]: Warning: sbps-add-content.sh failed.
2024-11-12T20:13:00.44926 [  402.952550] dracut-pre-mount[3809]: Warning: Unable to prepare squashfs file /tmp/cps/rootfs, dropping to debug.
```

SBPS Marshal agent crashes with the following messages on the worker node (iSCSI Target):

```bash
ncn-w002:~ # systemctl status sbps-marshal.service
× sbps-marshal.service - System service that manages Squashfs images projected via iSCSI for IMS, PE, and other ancillary images similar to PE.
     Loaded: loaded (/usr/lib/systemd/system/sbps-marshal.service; enabled; preset: disabled)
     Active: failed (Result: exit-code) since Tue 2024-11-12 19:20:05 UTC; 18h ago
   Duration: 2.232s
    Process: 1239406 ExecStart=/usr/lib/sbps-marshal/bin/sbps-marshal (code=exited, status=1/FAILURE)
   Main PID: 1239406 (code=exited, status=1/FAILURE)
        CPU: 1.394s

Nov 12 19:20:04 ncn-w002 sbps-marshal[1239406]:   File "/usr/lib/sbps-marshal/bin/sbps-marshal", line 8, in <module>
Nov 12 19:20:04 ncn-w002 sbps-marshal[1239406]:     sys.exit(main())
Nov 12 19:20:04 ncn-w002 sbps-marshal[1239406]:              ^^^^^^
Nov 12 19:20:04 ncn-w002 sbps-marshal[1239406]:   File "/usr/lib/sbps-marshal/lib/python3.12/site-packages/bin/agent.py", line 270, in main
Nov 12 19:20:04 ncn-w002 sbps-marshal[1239406]:     rootfs_s3_etag = artifact["link"]["etag"]
Nov 12 19:20:04 ncn-w002 sbps-marshal[1239406]:                      ~~~~~~~~~~~~~~~~^^^^^^^^
Nov 12 19:20:04 ncn-w002 sbps-marshal[1239406]: KeyError: 'etag'
Nov 12 19:20:05 ncn-w002 systemd[1]: sbps-marshal.service: Main process exited, code=exited, status=1/FAILURE
Nov 12 19:20:05 ncn-w002 systemd[1]: sbps-marshal.service: Failed with result 'exit-code'.
Nov 12 19:20:05 ncn-w002 systemd[1]: sbps-marshal.service: Consumed 1.394s CPU time.
```

The complete log for the SBPS Marshal agent `systemd` service can be obtained from `journalctl` log as below:

```bash
    # journalctl -u sbps-marshal.service
```

## Workaround Description

Step 1: Identify the manifest(s) which are missing the `etag` field

This can be fetched from worker node as `s3:/boot-images` is mounted onto the worker node. The following command will
search the mounted directory for manifests that are missing the `etag` field:

```bash
for f in /var/lib/cps-local/boot-images/*/manifest.json; do \
    echo $f etag=$(cat $f | jq '.artifacts[] | select(.type == "application/vnd.cray.image.rootfs.squashfs").link.etag' );  \
done | grep etag=null
```

An example run of the command listing the problematic `manifest.json` is as follows:

```bash
# for f in /var/lib/cps-local/boot-images/*/manifest.json; do \
     echo $f etag=$(cat $f | jq '.artifacts[] | select(.type == "application/vnd.cray.image.rootfs.squashfs").link.etag' );  \
 done | grep etag=null
/var/lib/cps-local/boot-images/3f89b76d-7578-4ac3-8891-0f8b4335b06d/manifest.json etag=null
```

Looking at the `manifest.json`:

```bash
ncn-w006:~ # cat /var/lib/cps-local/boot-images/3f89b76d-7578-4ac3-8891-0f8b4335b06d/manifest.json
{
   "artifacts" : [
      {
         "link" : {
            "path" : "s3://boot-images/3f89b76d-7578-4ac3-8891-0f8b4335b06d/compute.squashfs",
            "type" : "s3"
         },
         "md5" : "fa69a6665124629bfb1d74bfa3e4b7de",
         "type" : "application/vnd.cray.image.rootfs.squashfs"
      }
   ],
   "created" : "20240815093713",
   "version" : "1.0"
}
```

The "link" section has no `etag` field.

Step 2: Update the manifest with `etag` and update the same in `s3` from master node

Example `manifest.json` update with `etag` obtained from `s3` and update the same in `s3`:

```bash
ncn-m001:~ # MANIFEST=$(cray ims images describe "3f89b76d-7578-4ac3-8891-0f8b4335b06d"  --format json | jq -r .link.path)
ncn-m001:~ # echo $MANIFEST
s3://boot-images/3f89b76d-7578-4ac3-8891-0f8b4335b06d/manifest.json

ncn-m001:~ # cray artifacts get $(echo $MANIFEST | sed -e 's;^s3://;;g' -e 's;boot-images/;boot-images ;g' ) manifest.json

ncn-m001:~ # cray artifacts describe $(cat manifest.json | jq -r '.artifacts[] | select(.type == "application/vnd.cray.image.rootfs.squashfs").link.path' | sed -e 's;^s3://;;g' -e 's;boot-images/;boot-images ;g' ) --format json
{
  "artifact": {
    "AcceptRanges": "bytes",
    "LastModified": "2024-08-15T14:45:58+00:00",
    "ContentLength": 22095331328,
    "ETag": "\"f4153fe0a18cfb2205fb002d81a23ab2-2634\"",
    "ContentType": "binary/octet-stream",
    "Metadata": {
      "md5sum": "fa69a6665124629bfb1d74bfa3e4b7de"
    }
  }
}
ncn-m001:~ # cray artifacts describe $(cat manifest.json | jq -r '.artifacts[] | select(.type == "application/vnd.cray.image.rootfs.squashfs").link.path' | sed -e 's;^s3://;;g' -e 's;boot-images/;boot-images ;g' ) --format json | jq -r '.artifact.ETag' | tr -d '"'
f4153fe0a18cfb2205fb002d81a23ab2-2634
```

Now update the `manifest.json` file to add the `etag` obtained in the "link" section.

```bash
ncn-m001:~ # cat manifest.json
{
   "artifacts" : [
      {
         "link" : {
            "path" : "s3://boot-images/3f89b76d-7578-4ac3-8891-0f8b4335b06d/compute.squashfs",
            "etag" : "f4153fe0a18cfb2205fb002d81a23ab2-2634",
            "type" : "s3"
         },
         "md5" : "fa69a6665124629bfb1d74bfa3e4b7de",
         "type" : "application/vnd.cray.image.rootfs.squashfs"
      }
   ],
   "created" : "20240815093713",
   "version" : "1.0"
}
```

Now update the `etag` in S3 as well:

```bash
ncn-m001:~ # cray artifacts create $( echo $MANIFEST | sed -e 's;^s3://;;g' -e 's;boot-images/;boot-images ;g' ) manifest.json
```

Step 3: Restart SBPS Marshal agent `systemd` service on each impacted worker node and ensure it's running successfully

```bash
# systemctl restart sbps-marshal.service
# systemctl status sbps-marshal.service
```
