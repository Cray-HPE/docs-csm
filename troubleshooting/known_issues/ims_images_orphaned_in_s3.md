# Known Issue: IMS Images Orphaned in S3

There was an issue where image files larger than 5Gb were not correctly deleted from S3 when the image
was deleted through the IMS service. These artifacts are no longer referenced by IMS but are still
left in the S3 `boot-images` bucket and need to be deleted manually.

This issue is resolved in CSM V1.6.1 and V1.7.0 and will not produce additional orphaned artifacts
after these versions, but orphaned artifacts may still exist on the system from previous versions if
they have not been cleaned up.

## Prerequisites

- The latest CSM documentation RPM must be installed on the node where the procedure is being performed.
    - See [Check for latest documentation](../../update_product_stream/README.md#check-for-latest-documentation).
- Ensure thre is an environment variable `CRAY_CREDENTIALS` pointing to an authentication token.
    - See [Authenticate an Account with the Command Line](../../operations/security_and_authentication/Authenticate_an_Account_with_the_Command_Line.md).

## Fix

These items can be deleted out of S3. There is a script defined here that will automatically look through
all of the artifacts in the `boot-images` bucket in S3 and finds the artifacts that no longer belong to
a valid IMS image. There is a `--dry-run` option which will only list the artifacts found; without that
option the script will delete the orphaned artifacts.

1. (`ncn-mw#`) Run the script in `dry run` mode

  Running the script with `--dry-run` as an argument will list the files that
  it finds that are orphaned without deleting anything. Do this first to inspect
  what is present before they are removed permanently.

  ```bash
  /usr/share/doc/csm/scripts/remove_orphaned_artifacts.py --dry-run
  ```

  Expected output will look something like:

  ```text
  Found: 01643906-7fa2-4388-9dc6-c6f2f8c5589d/rootfs, size: 14.315Gb
  Found: 01b880ec-940d-470a-9beb-dfdf5b562bec/rootfs, size: 19.675Gb
  Found: 02aa48c9-4376-4758-8f4c-09a6f4d46c13/rootfs, size: 21.770Gb
  Found: 02c4841d-3d0e-4af4-a869-1a542bf2bf39/rootfs, size: 19.955Gb
  Found: 039689b3-a1e8-432e-a058-c7973e2036d9/rootfs, size: 13.996Gb
  Found: 05b18508-387e-45c6-85c8-c2169ecac37f/rootfs, size: 19.689Gb
  Found: 06a2e527-607b-4703-bf1b-54c32aee4fb8/rootfs, size: 20.777Gb
  Found: 0773ed3f-9237-48f5-89b6-2e49855f6d76/rootfs, size: 21.643Gb
  Found: 079f6bce-d902-438a-8db7-bcb06a21d3de/rootfs, size: 13.995Gb
  Found: 09fb55d9-798e-41f7-b8d4-2f45a80c5e07/rootfs, size: 14.017Gb
  Found: 0c8a0db2-2403-41c6-85e5-5783e9c471b6/rootfs, size: 18.972Gb
  Found: 10a14e1c-4cbc-4197-9a5a-f133db5d3d25/rootfs, size: 21.643Gb
  Found: 11bde47f-8a41-469d-a6d6-dabdd8ce470f/rootfs, size: 5.957Gb
  Found: 12df4d6c-d5a1-4e4d-8973-64dedff63b98/rootfs, size: 12.100Gb
  Found: 142b8bfe-7f56-4385-ab20-1d4c176a447f/rootfs, size: 13.995Gb
  Found: 15387a19-f1b9-4e16-bd9f-17e229ef2360/rootfs, size: 14.419Gb
  Found: 160ce9fb-63a3-476b-926e-0f2a7baad65d/rootfs, size: 16.184Gb
  Found: 16a7f5cf-9c04-4396-84b7-13e0cd4674f1/rootfs, size: 20.740Gb
  Total orphaned: 303.84Gb
  ```

1. (`ncn-mw#`) Delete the orphaned artifacts

  NOTE: This step is not reversible so make sure none of the files listed in the
  previous step are incorrectly identified.

  Run the script without the `--dry-run` option to delete the artifacts:

  ```bash
  /usr/share/doc/csm/scripts/remove_orphaned_artifacts.py --dry-run
  ```

  Expected output will look something like:

  ```text
  Deleted: 01643906-7fa2-4388-9dc6-c6f2f8c5589d/rootfs, size: 14.315Gb
  Deleted: 01b880ec-940d-470a-9beb-dfdf5b562bec/rootfs, size: 19.675Gb
  Deleted: 02aa48c9-4376-4758-8f4c-09a6f4d46c13/rootfs, size: 21.770Gb
  Deleted: 02c4841d-3d0e-4af4-a869-1a542bf2bf39/rootfs, size: 19.955Gb
  Deleted: 039689b3-a1e8-432e-a058-c7973e2036d9/rootfs, size: 13.996Gb
  Deleted: 05b18508-387e-45c6-85c8-c2169ecac37f/rootfs, size: 19.689Gb
  Deleted: 06a2e527-607b-4703-bf1b-54c32aee4fb8/rootfs, size: 20.777Gb
  Deleted: 0773ed3f-9237-48f5-89b6-2e49855f6d76/rootfs, size: 21.643Gb
  Deleted: 079f6bce-d902-438a-8db7-bcb06a21d3de/rootfs, size: 13.995Gb
  Deleted: 09fb55d9-798e-41f7-b8d4-2f45a80c5e07/rootfs, size: 14.017Gb
  Deleted: 0c8a0db2-2403-41c6-85e5-5783e9c471b6/rootfs, size: 18.972Gb
  Deleted: 10a14e1c-4cbc-4197-9a5a-f133db5d3d25/rootfs, size: 21.643Gb
  Deleted: 11bde47f-8a41-469d-a6d6-dabdd8ce470f/rootfs, size: 5.957Gb
  Deleted: 12df4d6c-d5a1-4e4d-8973-64dedff63b98/rootfs, size: 12.100Gb
  Deleted: 142b8bfe-7f56-4385-ab20-1d4c176a447f/rootfs, size: 13.995Gb
  Deleted: 15387a19-f1b9-4e16-bd9f-17e229ef2360/rootfs, size: 14.419Gb
  Deleted: 160ce9fb-63a3-476b-926e-0f2a7baad65d/rootfs, size: 16.184Gb
  Deleted: 16a7f5cf-9c04-4396-84b7-13e0cd4674f1/rootfs, size: 20.740Gb
  Total orphaned: 303.84Gb
  ```
